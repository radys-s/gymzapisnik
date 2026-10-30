import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/ai_config.dart';
import '../ai/fridge_coach.dart';
import '../ai/trainer.dart';
import '../coach/missions.dart';
import '../coach/plan_quiz.dart';
import '../coach/plates.dart';
import '../coach/progression.dart';
import '../coach/splits.dart';
import '../coach/achievements.dart';
import '../coach/coach_context.dart';
import '../coach/local_coach.dart';
import '../coach/recovery.dart';
import '../coach/streak.dart';
import '../coach/tips.dart';
import '../core/ids.dart';
import '../data/backup.dart';
import '../domain/bodyweight.dart';
import '../data/hevy_import.dart';
import '../data/off_client.dart';
import '../data/csv.dart';
import '../data/store.dart';
import '../domain/catalog.dart';
import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/nutrition.dart';
import '../domain/profile.dart';
import '../domain/set_match.dart';
import '../domain/stats.dart';
import '../coach/reminders.dart';
import '../notify/notifier.dart';
import '../premium/entitlements.dart';

/// Druhy dokumentů v úložišti.
abstract final class Kinds {
  static const profile = 'profile';
  static const workout = 'workout';
  static const exercise = 'exercise';
  static const bodyweight = 'bodyweight';
  static const food = 'food';
}

/// Stav aplikace sdílený obrazovkami. UI nesahá přímo na úložiště.
class AppState extends ChangeNotifier {
  final LocalStore store;
  AppState(
    this.store, {
    this.paywall = paywallEnabled,
    this.notifier = const NoopNotifier(),
    ProductLookup? lookup,
    FridgeCoach? coach,
    TrainerAi? trainer,
  }) : lookup = lookup ?? OffClient() {
    // Dva klienti: zrušení u trenéra nesmí přerušit fotku ledničky.
    this.coach =
        coach ?? HttpFridgeCoach(baseUrl: aiBaseUrl, installId: installId);
    this.trainer =
        trainer ?? HttpFridgeCoach(baseUrl: aiBaseUrl, installId: installId);
  }

  /// AI kouč pro ledničku a návrhy jídel (v testech jde přepsat).
  late final FridgeCoach coach;

  /// AI trenér: fotka stroje a chat (v testech jde přepsat).
  late final TrainerAi trainer;

  /// Hledání produktů podle čárového kódu (v testech jde přepsat).
  final ProductLookup lookup;

  /// Místní oznámení; ve webové verzi prázdná implementace.
  final Notifier notifier;

  /// Je zapnutý paywall (v testech jde přepsat).
  final bool paywall;

  /// Je funkce Pro dostupná?
  bool has(ProFeature feature) =>
      Entitlements.has(profile, feature, paywall: paywall);

  Profile profile = const Profile();

  /// Dokončené tréninky od nejnovějšího.
  List<Workout> workouts = [];

  /// Rozepsaný trénink (nejvýš jeden).
  Workout? active;

  List<Exercise> customExercises = [];

  /// Tělesná váha, nejnovější první.
  List<BodyWeight> bodyweights = [];

  /// Výživový deník, nejnovější záznam první.
  List<FoodEntry> foods = [];

  Future<void> load() async {
    await store.open();
    final json = await store.get(Profile.id);
    profile = json == null ? const Profile() : Profile.fromJson(json);
    final all = _parsed(await store.all(Kinds.workout), Workout.fromJson);
    workouts = all.where((w) => w.finished).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final unfinished = all.where((w) => !w.finished).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    active = unfinished.firstOrNull;
    customExercises = _parsed(
      await store.all(Kinds.exercise),
      Exercise.fromJson,
    )..sort((a, b) => a.name.compareTo(b.name));
    bodyweights = _parsed(
      await store.all(Kinds.bodyweight),
      BodyWeight.fromJson,
    )..sort((a, b) => b.date.compareTo(a.date));
    foods = _parsed(await store.all(Kinds.food), FoodEntry.fromJson)
      ..sort(_newestFood);
    notifyListeners();
    unawaited(syncReminders());
    unawaited(syncRest());
  }

  /// Načte dokumenty; poškozený řádek přeskočí (zůstane v databázi beze
  /// změny), aby jeden vadný záznam nezablokoval spuštění aplikace.
  static List<T> _parsed<T>(
    Iterable<Map<String, dynamic>> rows,
    T Function(Map<String, dynamic>) parse,
  ) {
    final result = <T>[];
    for (final row in rows) {
      try {
        result.add(parse(row));
      } catch (e) {
        debugPrint('Přeskočen poškozený záznam ${row['id']}: $e');
      }
    }
    return result;
  }

  /// Souhlas; s [welcomeVersion] zároveň uzavře uvítání jedním zápisem,
  /// aby po pádu nezůstalo „uvítání hotové, souhlas chybí".
  Future<void> acceptConsent({
    required bool adult,
    required bool guardianConsent,
    String? welcomeVersion,
    bool aiNotice = false,
  }) => _updateProfile((current) {
    final next = current.acceptConsent(
      adult: adult,
      guardianConsent: guardianConsent,
      now: DateTime.now(),
    );
    return next.withExtra({
      if (welcomeVersion != null) ...{
        'welcomeSeen': true,
        'seenVersion': welcomeVersion,
      },
      // Upozornění na AI bylo součástí souhlasu: trenér se už neptá znovu.
      if (aiNotice) 'aiNotice': true,
    });
  });

  /// Všechny cviky: vlastní + katalog.
  List<Exercise> get allExercises => [...customExercises, ...builtInExercises];

  /// Cvik podle ID; neznámé ID (např. smazaný vlastní cvik) dostane
  /// náhradní záznam, aby historie dál fungovala.
  Exercise exercise(String id) =>
      findExercise(id, customExercises) ??
      Exercise(id: id, name: 'Neznámý cvik', muscle: 'Ostatní');

  ExerciseType typeOf(String id) => exercise(id).type;

  Future<Exercise> addCustomExercise({
    required String name,
    required String muscle,
    required ExerciseType type,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Zadej název cviku.');
    final exercise = Exercise(
      id: 'custom_${newId()}',
      name: trimmed,
      muscle: muscle,
      type: type,
      custom: true,
    );
    await _enqueue(() => store.put(Kinds.exercise, exercise.toJson()));
    customExercises = [...customExercises, exercise]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return exercise;
  }

  // ---------------------------------------------------------------------
  // Aktivní trénink
  // ---------------------------------------------------------------------

  /// Zápisy se řadí za sebe, aby rychlé klikání nepřepsalo novější stav
  /// starším a dokončení počkalo na rozepsané uložení.
  /// Výchozí `null` místo `Future.value()`: hotová future si pamatuje zónu,
  /// ve které vznikla, a v testech s falešným časem by fronta nikdy nedoběhla.
  Future<void>? _writes;
  Future<({Workout? workout, String? error})>? _finishing;

  Future<T> _enqueue<T>(Future<T> Function() write) {
    final previous = _writes;
    final next = previous == null
        ? Future<T>.sync(write)
        : previous.then((_) => write());
    final chain = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _writes = chain;
    // Doběhlá fronta se zahodí: další zápis pak nezávisí na zóně staré future.
    chain.whenComplete(() {
      if (identical(_writes, chain)) _writes = null;
    });
    return next;
  }

  /// Uloží aktuální stav rozepsaného tréninku.
  Future<void> saveActive() {
    final workout = active;
    if (workout == null) return _writes ?? Future.value();
    final json = workout.toJson();
    notifyListeners();
    return _enqueue(() => store.put(Kinds.workout, json));
  }

  static const _weekdays = [
    'pondělí',
    'úterý',
    'středa',
    'čtvrtek',
    'pátek',
    'sobota',
    'neděle',
  ];

  /// Začne nový trénink, nebo vrátí rozepsaný.
  Future<Workout> startWorkout({String? name, DateTime? now}) async {
    if (_finishing != null) throw StateError('Počkej na uložení tréninku.');
    final existing = active;
    if (existing != null) return existing;
    final start = now ?? DateTime.now();
    _dayPick = null;
    active = Workout(
      id: newId(),
      name: name ?? 'Trénink – ${_weekdays[start.weekday - 1]}',
      startedAt: start,
    );
    await saveActive();
    return active!;
  }

  /// Zopakuje minulý trénink: stejné cviky, hodnoty z posledního provedení.
  Future<Workout> repeatWorkout(Workout past) async {
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    final workout = await startWorkout(name: past.name);
    final ids = <String>[];
    for (final e in past.exercises) {
      if (!ids.contains(e.exerciseId)) ids.add(e.exerciseId);
    }
    for (final id in ids) {
      workout.exercises.add(_prefilled(id));
    }
    await saveActive();
    return workout;
  }

  /// Série předvyplněné z posledního provedení cviku (nedokončené).
  WorkoutExercise _prefilled(String exerciseId) {
    final last = lastSetsOf(exerciseId);
    return WorkoutExercise(
      id: newId(),
      exerciseId: exerciseId,
      sets: last.isEmpty
          ? [SetEntry()]
          : [for (final s in last) s.copy(done: false)],
    );
  }

  List<Workout>? _badgesOf;
  List<Exercise>? _badgesExercises;
  List<BadgeState> _badges = const [];

  /// Stav odznaků (v mezipaměti, dokud se nezmění tréninky nebo cviky).
  /// Platí jen proto, že `workouts` i `customExercises` se při každé změně
  /// nahrazují novým seznamem; úprava na místě by mezipaměť nezneplatnila.
  List<BadgeState> get badgeStates {
    if (!identical(_badgesOf, workouts) ||
        !identical(_badgesExercises, customExercises)) {
      _badges = computeBadges(workouts, typeOf);
      _badgesOf = workouts;
      _badgesExercises = customExercises;
    }
    return _badges;
  }

  /// Odznaky odemčené daným tréninkem.
  List<BadgeState> badgesFrom(String workoutId) => [
    for (final b in badgeStates)
      if (b.workoutId == workoutId) b,
  ];

  List<Workout>? _recordsOf;
  final _records = <String, Map<RecordKind, PersonalRecord>>{};

  /// Nejlepší výkony cviku z dokončených tréninků (v mezipaměti, dokud se
  /// seznam tréninků nezmění; ten se při každé změně vytváří nový).
  Map<RecordKind, PersonalRecord> recordsOf(String exerciseId) {
    if (!identical(_recordsOf, workouts)) {
      _records.clear();
      _recordsOf = workouts;
    }
    return _records.putIfAbsent(
      exerciseId,
      () => allTimeRecords(workouts, exerciseId, typeOf(exerciseId)),
    );
  }

  bool _isWeighted(SetEntry set) {
    for (final e in active?.exercises ?? const <WorkoutExercise>[]) {
      if (e.sets.any((s) => identical(s, set))) {
        return typeOf(e.exerciseId) == ExerciseType.weighted;
      }
    }
    return false;
  }

  /// Rekordy, které potvrzená série v aktivním tréninku právě drží.
  List<RecordKind> liveRecords(SetEntry set) {
    final workout = active;
    if (workout == null || !set.counts) return const [];
    String? exerciseId;
    for (final e in workout.exercises) {
      if (e.sets.any((s) => identical(s, set))) exerciseId = e.exerciseId;
    }
    if (exerciseId == null) return const [];
    return liveRecordKinds(
      set: set,
      sessionSets: [
        for (final e in workout.exercises)
          if (e.exerciseId == exerciseId) ...e.sets,
      ],
      before: recordsOf(exerciseId),
      type: typeOf(exerciseId),
    );
  }

  /// Série z posledního dokončeného provedení cviku (pro „minule“).
  List<SetEntry> lastSetsOf(String exerciseId) {
    final session = lastPerformance(workouts, exerciseId);
    if (session == null) return const [];
    return [
      for (final e in session.workout.exercises)
        if (e.exerciseId == exerciseId) ...e.sets.where((s) => s.done),
    ];
  }

  Future<WorkoutExercise> addExercise(String exerciseId) async {
    final workout = active ?? await startWorkout();
    final entry = _prefilled(exerciseId);
    workout.exercises.add(entry);
    await saveActive();
    return entry;
  }

  Future<void> replaceExercise(WorkoutExercise entry, String exerciseId) {
    final fresh = _prefilled(exerciseId);
    entry
      ..exerciseId = exerciseId
      ..sets = fresh.sets
      // Návrh kouče patřil původnímu cviku.
      ..extra.remove(coachKey);
    return saveActive();
  }

  /// Přidá rozcvičovací série podle první pracovní váhy cviku. Dřívější
  /// nepotvrzené rozcvičky nahradí. Vrací počet přidaných sérií; `null`,
  /// když už je nějaká rozcvička potvrzená nebo chybí pracovní váha.
  Future<int?> addWarmups(WorkoutExercise entry) async {
    if (entry.sets.any((s) => s.warmup && s.done)) return null;
    final working = entry.sets.where((s) => !s.warmup && s.weight > 0);
    if (working.isEmpty) return null;
    final plan = warmupPlan(working.first.weight);
    if (plan.isEmpty) return 0;
    entry.sets = [
      for (final w in plan)
        SetEntry(weight: w.weight, reps: w.reps, warmup: true),
      ...entry.sets.where((s) => !s.warmup),
    ];
    await saveActive();
    return plan.length;
  }

  Future<void> removeExercise(WorkoutExercise entry) {
    active?.exercises.remove(entry);
    return saveActive();
  }

  /// Posune cvik v tréninku o [delta] míst (záporně = nahoru).
  Future<void> moveExercise(WorkoutExercise entry, int delta) {
    final list = active?.exercises;
    if (list == null) return Future.value();
    final from = list.indexOf(entry);
    final to = from + delta;
    if (from < 0 || to < 0 || to >= list.length) return Future.value();
    list
      ..removeAt(from)
      ..insert(to, entry);
    return saveActive();
  }

  /// Přesune cvik tažením z indexu [from] na výsledný index [to].
  Future<void> reorderExercise(int from, int to) {
    final list = active?.exercises;
    if (list == null || from < 0 || from >= list.length) {
      return Future.value();
    }
    final target = to.clamp(0, list.length - 1);
    if (target == from) return Future.value();
    list.insert(target, list.removeAt(from));
    return saveActive();
  }

  /// Hodnoty „minule" pro série cviku (stejný druh a pořadí v něm).
  List<SetEntry?> previousFor(WorkoutExercise entry) =>
      previousSets(entry.sets, lastSetsOf(entry.exerciseId));

  /// Další pracovní série: hodnoty z minula na stejné pozici, jinak kopie
  /// poslední pracovní série.
  Future<SetEntry> addSet(WorkoutExercise entry) async {
    final set = nextWorkingSet(entry.sets, lastSetsOf(entry.exerciseId));
    entry.sets.add(set);
    await saveActive();
    return set;
  }

  /// Smaže sérii a vrátí její pozici (pro „Vrátit"), -1 když tam nebyla.
  Future<int> removeSet(WorkoutExercise entry, SetEntry set) async {
    final index = entry.sets.indexOf(set);
    if (index < 0) return index;
    entry.sets.removeAt(index);
    await saveActive();
    return index;
  }

  /// Vrátí smazanou sérii na původní místo. [sets] je seznam, ze kterého
  /// se mazalo: po nahrazení cviku, jeho odebrání nebo dokončení tréninku
  /// se nic nevrací (vrací `false`).
  Future<bool> restoreSet(
    WorkoutExercise entry,
    SetEntry set,
    int index, {
    required List<SetEntry> sets,
  }) async {
    if (!(active?.exercises.contains(entry) ?? false) ||
        !identical(entry.sets, sets) ||
        sets.contains(set)) {
      return false;
    }
    sets.insert(index.clamp(0, sets.length), set);
    await saveActive();
    return true;
  }

  /// Označí sérii jako hotovou (nebo zpět). Vrací chybovou hlášku,
  /// když se série nedá potvrdit. Potvrzení spustí pauzu.
  Future<String?> toggleDone(SetEntry set, {DateTime? now}) async {
    if (!set.done) {
      if (set.reps <= 0) return 'Zadej počet opakování.';
      if (set.weight < 0 || !set.weight.isFinite) return 'Neplatná váha.';
      if (!set.warmup && set.weight == 0 && _isWeighted(set)) {
        return 'Zadej váhu v kg.';
      }
    }
    set.done = !set.done;
    if (set.done) {
      _setRestEnd(
        (now ?? DateTime.now()).add(Duration(seconds: profile.restSeconds)),
      );
    }
    await saveActive();
    await syncRest();
    return null;
  }

  // ---------------------------------------------------------------------
  // Pauza mezi sériemi
  // ---------------------------------------------------------------------

  static const _restKey = 'restEndsAt';

  /// Konec pauzy jako časové razítko: odpočet sedí i po uspání nebo
  /// zavření aplikace. `null` = žádná pauza.
  DateTime? get restEndsAt {
    final v = active?.extra[_restKey];
    return v is String ? DateTime.tryParse(v)?.toLocal() : null;
  }

  void _setRestEnd(DateTime? end) {
    final workout = active;
    if (workout == null) return;
    if (end == null) {
      workout.extra.remove(_restKey);
    } else {
      workout.extra[_restKey] = end.toUtc().toIso8601String();
    }
  }

  /// Prodlouží nebo zkrátí běžící pauzu; pod nulou ji ukončí.
  Future<void> adjustRest(Duration delta, {DateTime? now}) async {
    final end = restEndsAt;
    if (end == null) return;
    final next = end.add(delta);
    _setRestEnd(next.isAfter(now ?? DateTime.now()) ? next : null);
    await saveActive();
    await syncRest();
  }

  Future<void> skipRest() async {
    if (restEndsAt == null) return;
    _setRestEnd(null);
    await saveActive();
    await syncRest();
  }

  bool get restAlerts => profile.extra['restAlerts'] == true;

  Future<bool> setRestAlerts(bool enabled) async {
    if (notifier is! RestNotifier) return false;
    if (enabled && !await notifier.requestPermission()) return false;
    await _updateProfile(
      (p) => p.withExtra({'restAlerts': enabled ? true : null}),
    );
    await syncRest();
    return true;
  }

  Future<void>? _restUpdates;

  /// Vyhodnotit poslední stav až ve frontě, aby stará pauza nepřepsala
  /// zrušení při dokončení tréninku. Chyba oznámení neblokuje zápis série.
  Future<void> syncRest() {
    final rest = notifier;
    if (rest is! RestNotifier) return Future.value();
    Future<void> update() async {
      try {
        final end = restEndsAt;
        if (restAlerts && end != null && end.isAfter(DateTime.now())) {
          await (rest as RestNotifier).scheduleRest(end);
        } else {
          await (rest as RestNotifier).cancelRest();
        }
      } catch (e) {
        debugPrint('Upozornění na pauzu se nepodařilo naplánovat: $e');
      }
    }

    final next = _restUpdates == null
        ? update()
        : _restUpdates!.then((_) => update());
    _restUpdates = next;
    next.whenComplete(() {
      if (identical(_restUpdates, next)) _restUpdates = null;
    });
    return next;
  }

  Future<void> toggleWarmup(SetEntry set) {
    set.warmup = !set.warmup;
    return saveActive();
  }

  /// Nastaví druh série (rozcvička / pracovní).
  Future<void> setWarmup(SetEntry set, bool warmup) {
    if (set.warmup == warmup) return Future.value();
    set.warmup = warmup;
    return saveActive();
  }

  /// Dokončí trénink: uloží jen potvrzené série a cviky, které nějakou mají.
  /// Vrací dokončený trénink, nebo chybovou hlášku.
  Future<({Workout? workout, String? error})> finishActive({DateTime? now}) {
    final pending = _finishing;
    if (pending != null) return pending;
    final finishing = _finishActive(now: now);
    _finishing = finishing;
    return finishing.whenComplete(() => _finishing = null);
  }

  Future<({Workout? workout, String? error})> _finishActive({
    DateTime? now,
  }) async {
    final workout = active;
    if (workout == null) return (workout: null, error: 'Žádný trénink.');
    final done = workout.copy()..extra.remove(_restKey);
    done.exercises = [
      for (final e in done.exercises)
        if (e.sets.any((s) => s.done && s.reps > 0))
          e..sets = e.sets.where((s) => s.done && s.reps > 0).toList(),
    ];
    if (!done.exercises.any((e) => e.countedSets.isNotEmpty)) {
      return (workout: null, error: 'Potvrď aspoň jednu pracovní sérii.');
    }
    final finished = Workout.fromJson({
      ...done.toJson(),
      'id': completedWorkoutId(workout.id),
      'finishedAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
    });
    // Aktivní trénink se odpojí hned, aby opožděné uložení z UI
    // (např. psaní do pole těsně před dokončením) ho nevrátilo zpět.
    active = null;
    try {
      await _enqueue(
        () => store.replace(
          removeId: workout.id,
          kind: Kinds.workout,
          data: finished.toJson(),
        ),
      );
    } catch (_) {
      active = workout;
      notifyListeners();
      return (
        workout: null,
        error: 'Trénink se nepodařilo uložit. Zkus dokončení znovu. Pokud chyba trvá, aplikaci nezavírej.',
      );
    }
    workouts = [finished, ...workouts.where((w) => w.id != finished.id)]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(syncReminders());
    unawaited(syncRest());
    return (workout: finished, error: null);
  }

  Future<void> discardActive() async {
    final workout = active;
    if (workout == null) return;
    active = null;
    try {
      await _enqueue(() => store.remove(workout.id));
    } catch (_) {
      active = workout;
      rethrow;
    }
    notifyListeners();
    await syncRest();
  }

  // ---------------------------------------------------------------------
  // Split a progrese
  // ---------------------------------------------------------------------

  /// Zvolený program. Hotová šablona se přizpůsobí doporučenému počtu
  /// cviků z dotazníku „Tvůj plán“; vlastní program zůstává, jak je.
  SplitTemplate? get split {
    if (!identical(_splitOf, profile)) {
      final base = findSplit(profile.splitId, customPrograms);
      _split = base == null ? null : fitted(base);
      _splitOf = profile;
    }
    return _split;
  }

  /// Hotový program s dny upravenými na doporučený počet cviků
  /// z dotazníku. Vlastní programy zůstávají, jak si je uživatel složil.
  SplitTemplate fitted(SplitTemplate base) {
    final answers = planAnswers;
    if (base.custom || answers == null) return base;
    final count = recommendPlan(answers).exercises;
    return base.copyWith(days: [for (final d in base.days) fitDay(d, count)]);
  }

  Profile? _splitOf;
  SplitTemplate? _split;

  /// Odpovědi z dotazníku „Tvůj plán“; `null` = ještě nevyplněný.
  PlanAnswers? get planAnswers => PlanAnswers.tryParse(profile.extra['plan']);

  /// Uloží odpovědi a zapne doporučený program, počet tréninků týdně
  /// a pauzu podle cíle. Bez [answers] (doporučení bez dotazníku) zapne
  /// jen výchozí doporučený program a odpovědi neuloží.
  Future<PlanRecommendation> applyPlan(PlanAnswers? answers) async {
    final r = recommendPlan(answers ?? const PlanAnswers());
    await _updateProfile((p) {
      // Vybrané dny zůstanou, když jich je tolik, kolik plán chce.
      final days = p.trainingDays;
      return p.withExtra({
        'plan': ?answers?.toJson(),
        'split': r.splitId,
        'weekGoal': r.perWeek,
        if (days != null && days.length != r.perWeek) 'trainingDays': null,
        'restSeconds': r.restSeconds,
      });
    });
    unawaited(syncReminders());
    return r;
  }

  Profile? _programsOf;
  List<SplitTemplate> _programs = const [];

  /// Vlastní programy (uložené v profilu, jdou i do zálohy).
  List<SplitTemplate> get customPrograms {
    if (!identical(_programsOf, profile)) {
      _programsOf = profile;
      final raw = profile.extra['programs'];
      _programs = [
        if (raw is List)
          for (final json in raw) ?SplitTemplate.tryCustom(json),
      ];
    }
    return _programs;
  }

  Future<void> setSplit(String? id) async {
    await _updateProfile((p) => p.withExtra({'split': id}));
    unawaited(syncReminders());
  }

  /// Uloží vlastní program (nový dostane ID). Vrací uložený program,
  /// nebo hodí [ArgumentError] s českou zprávou.
  Future<SplitTemplate> saveProgram(
    SplitTemplate program, {
    bool activate = false,
  }) async {
    final cleaned = program.copyWith(
      id: program.id.startsWith(customProgramPrefix)
          ? program.id
          : '$customProgramPrefix${newId()}',
      name: program.name.trim(),
      custom: true,
      // Vlastní program se cvičí dokola: doporučení = počet dnů.
      perWeek: program.days.length.clamp(1, 7),
      days: [for (final d in program.days) d.copyWith(name: d.name.trim())],
    );
    final error = programError(cleaned);
    if (error != null) throw ArgumentError(error);
    await _updateProfile((p) {
      // Ostatní programy zůstanou tak, jak jsou uložené (i ty, které
      // novější verze neumí přečíst), aby se uložením jednoho neztratily.
      final list = [...p.extra['programs'] as List? ?? const []];
      final at = list.indexWhere((e) => e is Map && e['id'] == cleaned.id);
      if (at >= 0) {
        list[at] = cleaned.toJson();
      } else {
        if (list.length >= maxCustomPrograms) {
          throw ArgumentError(
            'Vlastních programů může být nejvýš $maxCustomPrograms.',
          );
        }
        list.add(cleaned.toJson());
      }
      return p.withExtra({'programs': list, if (activate) 'split': cleaned.id});
    });
    unawaited(syncReminders());
    return cleaned;
  }

  /// Smaže vlastní program; byl-li zvolený, přejde na volné tréninky.
  Future<void> deleteProgram(String id) async {
    await _updateProfile((p) {
      final list = [
        for (final json in p.extra['programs'] as List? ?? const [])
          if (json is Map && json['id'] != id) json,
      ];
      return p.withExtra({
        'programs': list.isEmpty ? null : list,
        if (p.splitId == id) 'split': null,
      });
    });
    unawaited(syncReminders());
  }

  /// Frekvence: kolikrát týdně a volitelně ve které dny. Se zvolenými dny
  /// je cíl jejich počet; `null` cíl = podle programu.
  Future<void> setFrequency({int? perWeek, List<int>? days}) async {
    final picked = days == null || days.isEmpty
        ? null
        : ({for (final d in days) d.clamp(1, 7)}.toList()..sort());
    await _updateProfile(
      (p) => p.withExtra({
        'weekGoal': picked?.length ?? perWeek?.clamp(1, 7),
        'trainingDays': picked,
      }),
    );
    unawaited(syncReminders());
  }

  /// Přidá nebo odebere den tréninku (1 = pondělí). Čte aktuální profil
  /// až ve frontě zápisů, takže rychlá klepnutí se nepřepíšou. Bez dnů
  /// se cíl vrátí na počet podle programu.
  Future<void> toggleTrainingDay(int day) async {
    await _updateProfile((p) {
      final days = [...?p.trainingDays];
      if (!days.remove(day)) days.add(day.clamp(1, 7));
      days.sort();
      return p.withExtra({
        'weekGoal': days.isEmpty ? null : days.length,
        'trainingDays': days.isEmpty ? null : days,
      });
    });
    unawaited(syncReminders());
  }

  /// Označí profil jako Pro (až bude hotová platba, volá se po nákupu).
  Future<void> setPro(bool value) async {
    await _updateProfile((p) => p.withExtra({'pro': value ? true : null}));
  }

  /// Týdenní cíl tréninků: vlastní, jinak podle splitu, jinak 3.
  int get weekGoal => profile.weekGoal ?? split?.perWeek ?? 3;

  /// Čas připomínky (minuty od půlnoci) nebo `null` = vypnout. Při zapnutí
  /// se zeptá na povolení; vrací `false`, když ho uživatel odmítl.
  Future<bool> setReminder(int? minutes) async {
    if (minutes != null && !await notifier.requestPermission()) {
      return false;
    }
    await _updateProfile(
      (p) => p.withExtra({'reminder': minutes?.clamp(0, 1439)}),
    );
    await syncReminders();
    return true;
  }

  /// Přepočítá naplánovaná oznámení podle tréninků a týdenního cíle.
  /// Chyba plánování nikdy nesmí shodit zápis tréninku.
  Future<void> syncReminders({DateTime? now}) async {
    if (!notifier.supported) return;
    try {
      final minutes = profile.reminderMinutes;
      if (minutes == null) {
        await notifier.cancelAll();
        return;
      }
      await notifier.schedule(
        planReminders(
          now: now ?? DateTime.now(),
          hour: minutes ~/ 60,
          minute: minutes % 60,
          goal: weekGoal,
          finished: workouts,
          trainingDays: profile.trainingDays,
        ),
      );
    } catch (e) {
      debugPrint('Připomínky se nepodařilo naplánovat: $e');
    }
  }

  /// Po každých tolika nových trénincích od poslední zálohy aplikace
  /// připomene zálohu (data jsou jen v zařízení).
  static const backupEvery = 10;

  bool get backupDue {
    final saved = profile.extra['backupCount'];
    final at = saved is num ? saved.toInt() : 0;
    return workouts.length - at >= backupEvery;
  }

  /// Zapamatuje, že záloha právě vznikla.
  Future<void> markBackedUp() async {
    await _updateProfile((p) => p.withExtra({'backupCount': workouts.length}));
  }

  /// Týdenní cíl bez pevných dnů (`null` = podle programu).
  Future<void> setWeekGoal(int? goal) => setFrequency(perWeek: goal);

  /// Dnešní mise podle týdenního cíle a odcvičených tréninků.
  Mission mission([DateTime? now]) => todayMission(
    goal: weekGoal,
    finished: [for (final w in workouts) w.date],
    now: now ?? DateTime.now(),
    startedAt: profile.consentAt?.toLocal(),
    trainingDays: profile.trainingDays,
  );

  /// Týdny v řadě se splněným cílem.
  Streak streak([DateTime? now]) => computeStreak(
    goal: weekGoal,
    finished: [for (final w in workouts) w.date],
    now: now ?? DateTime.now(),
  );

  /// Den splitu na řadě (po posledním odcvičeném dni).
  int get nextSplitDay {
    final s = split;
    return s == null ? 0 : nextDayIndex(s, workouts);
  }

  /// Ručně zvolený jiný den a program, ke kterému patří.
  (String, int)? _dayPick;

  /// Den, který je dnes na řadě: ručně zvolený na hlavní kartě, jinak
  /// další v pořadí. Stejný den ukazuje hlavní karta i trenér.
  int get todaySplitDay {
    final s = split;
    if (s == null || s.days.isEmpty) return 0;
    if (_dayPick case (final id, final day) when id == s.id) {
      return day % s.days.length;
    }
    return nextSplitDay;
  }

  SplitDay? get todayDay {
    final s = split;
    return s == null || s.days.isEmpty ? null : s.days[todaySplitDay];
  }

  /// Zvolí jiný den programu na dnešek (`null` = zpět na den na řadě).
  void pickSplitDay(int? day) {
    final s = split;
    _dayPick = s == null || day == null ? null : (s.id, day);
    notifyListeners();
  }

  /// Návrh váhy a opakování pro každý cvik dne.
  ///
  /// Bez Pro dostane každý cvik jen rozsah z plánu, bez návrhu váhy.
  List<(PlannedExercise, Suggestion)> plan(SplitDay day) => [
    for (final p in day.exercises)
      (
        p,
        has(ProFeature.coach)
            ? suggest(
                p,
                typeOf(p.exerciseId),
                exerciseHistory(workouts, p.exerciseId),
              )
            : Suggestion(
                kind: SuggestionKind.start,
                weight: 0,
                reps: p.repMin,
                sets: p.sets,
                reason: 'Návrh váhy od kouče je součástí Pro.',
              ),
      ),
  ];

  /// Začne trénink podle dne splitu s předvyplněnými návrhy.
  Future<Workout> startSplitDay(int dayIndex, {DateTime? now}) async {
    final s = split;
    if (s == null) throw StateError('Není zvolený split.');
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    final index = dayIndex % s.days.length;
    final day = s.days[index];
    final workout = await startWorkout(name: day.name, now: now);
    workout.extra
      ..['split'] = s.id
      ..['splitDay'] = index;
    await _fillPlanned(workout, day);
    return workout;
  }

  /// Začne trénink sestavený mimo program (výběr partií a počtu cviků).
  Future<Workout> startPlanned(SplitDay day, {DateTime? now}) async {
    if (active != null) throw StateError('Nejdřív dokonči rozepsaný trénink.');
    if (day.exercises.isEmpty) throw StateError('Trénink nemá žádný cvik.');
    final workout = await startWorkout(name: day.name, now: now);
    await _fillPlanned(workout, day);
    return workout;
  }

  Future<void> _fillPlanned(Workout workout, SplitDay day) async {
    for (final (p, suggestion) in plan(day)) {
      workout.exercises.add(
        WorkoutExercise(
          id: newId(),
          exerciseId: p.exerciseId,
          sets: suggestion.toSets(),
          extra: {coachKey: suggestion.toJson()},
        ),
      );
    }
    await saveActive();
  }

  // ---------------------------------------------------------------------
  // Historie
  // ---------------------------------------------------------------------

  /// Uloží upravený dokončený trénink. Ponechá jen vyplněné série a cviky,
  /// které nějakou mají; bez pracovní série úpravu odmítne.
  Future<String?> updateWorkout(Workout edited) async {
    if (!edited.finished) return 'Trénink není dokončený.';
    final cleaned = edited.copy()
      ..name = edited.name.trim().isEmpty ? 'Trénink' : edited.name.trim()
      ..note = edited.note.trim();
    cleaned.exercises = [
      for (final e in cleaned.exercises)
        if (e.sets.any((s) => s.reps > 0))
          e
            ..sets = [
              for (final s in e.sets)
                if (s.reps > 0) s..done = true,
            ],
    ];
    if (!cleaned.exercises.any((e) => e.countedSets.isNotEmpty)) {
      return 'Trénink musí mít aspoň jednu pracovní sérii.';
    }
    await _enqueue(() => store.put(Kinds.workout, cleaned.toJson()));
    workouts = [for (final w in workouts) w.id == cleaned.id ? cleaned : w]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(syncReminders());
    return null;
  }

  Future<void> deleteWorkout(Workout workout) async {
    await _enqueue(() => store.remove(workout.id));
    workouts = workouts.where((w) => w.id != workout.id).toList();
    notifyListeners();
    unawaited(syncReminders());
  }

  /// Uloží rozepsaná data před aktualizací webové verze.
  Future<void> saveBeforeUpdate() async {
    final finishing = _finishing;
    if (finishing != null) {
      final result = await finishing;
      if (result.error != null) throw StateError(result.error!);
    }
    await saveActive();
  }

  // ---------------------------------------------------------------------
  // Nastavení, záloha, export
  // ---------------------------------------------------------------------

  /// Změní nastavení v profilu (`null` = beze změny).
  Future<void> setPreferences({
    int? restSeconds,
    String? theme,
    String? accent,
    String? look,
    double? weightStep,
  }) => _updateProfile(
    (p) => p.withExtra({
      'restSeconds': ?restSeconds?.clamp(15, 600),
      if (weightStep != null && weightSteps.contains(weightStep))
        'weightStep': weightStep,
      'theme': ?theme,
      'accent': ?accent,
      'look': ?look,
    }),
  );

  /// Zapíše váhu; `false` = nesmyslná hodnota.
  Future<bool> addBodyweight(double kg, {DateTime? now}) async {
    if (!validBodyWeight(kg)) return false;
    final entry = BodyWeight(
      id: newId(),
      date: now ?? DateTime.now(),
      kg: double.parse(kg.toStringAsFixed(1)),
    );
    await _enqueue(() => store.put(Kinds.bodyweight, entry.toJson()));
    bodyweights = [entry, ...bodyweights]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    return true;
  }

  Future<void> removeBodyweight(String id) async {
    await _enqueue(() => store.remove(id));
    bodyweights = bodyweights.where((b) => b.id != id).toList();
    notifyListeners();
  }

  static int _newestFood(FoodEntry a, FoodEntry b) {
    final byDay = b.day.compareTo(a.day);
    return byDay != 0 ? byDay : b.loggedAt.compareTo(a.loggedAt);
  }

  /// Záznamy deníku z jednoho dne, nejnovější první.
  List<FoodEntry> foodsOn(String day) => [
    for (final f in foods)
      if (f.day == day) f,
  ];

  /// Naposledy zapsaná jídla (bez duplicit podle názvu), k rychlému opakování.
  List<FoodEntry> get recentFoods {
    final seen = <String>{};
    return [
      for (final f in foods)
        if (seen.add(foodKey(f))) f,
    ].take(8).toList();
  }

  /// Klíč jídla pro nedávná a oblíbená: název bez velikosti písmen + kód.
  static String foodKey(FoodEntry f) =>
      '${f.name.trim().toLowerCase()}|${f.barcode ?? ''}';

  /// Připnutá jídla (šablony se stejným množstvím), nejnověji připnuté první.
  List<FoodEntry> get favoriteFoods => [
    if (profile.extra['favoriteFoods'] case final List list)
      for (final f in list)
        if (f is Map<String, dynamic>) ?_tryFood(f),
  ];

  static FoodEntry? _tryFood(Map<String, dynamic> json) {
    try {
      final f = FoodEntry.fromJson(json);
      return f.name.trim().isEmpty ? null : f;
    } catch (_) {
      return null;
    }
  }

  bool isFavoriteFood(FoodEntry f) =>
      favoriteFoods.any((x) => foodKey(x) == foodKey(f));

  /// Připne nebo odepne jídlo; vrací `true`, když je teď oblíbené.
  /// Nejvýš [maxFavoriteFoods], nejstarší připnuté vypadne.
  Future<bool> toggleFavoriteFood(FoodEntry f) async {
    late bool pinned;
    await _updateProfile((p) {
      final raw = p.extra['favoriteFoods'];
      final current = [
        if (raw is List)
          for (final x in raw)
            if (x is Map<String, dynamic>) ?_tryFood(x),
      ];
      final key = foodKey(f);
      final rest = [
        for (final x in current)
          if (foodKey(x) != key) x,
      ];
      pinned = rest.length == current.length;
      final next = pinned ? [f, ...rest].take(maxFavoriteFoods) : rest;
      return p.withExtra({
        'favoriteFoods': next.isEmpty
            ? null
            : [for (final x in next) x.toJson()],
      });
    });
    return pinned;
  }

  /// Rychlé přidání: oblíbená první, pak nedávná bez opakování.
  List<FoodEntry> get quickFoods {
    final favorites = favoriteFoods;
    final keys = {for (final f in favorites) foodKey(f)};
    return [
      ...favorites,
      for (final f in recentFoods)
        if (!keys.contains(foodKey(f))) f,
    ];
  }

  /// Uloží nový záznam, nebo přepíše existující (stejné `id`).
  /// Vrací chybovou zprávu, nebo `null` po uložení.
  Future<String?> saveFood(FoodEntry entry) async {
    final error = validateFood(
      name: entry.name,
      amount: entry.amount,
      basis: entry.basis,
      values: entry.values,
    );
    if (error != null) return error;
    if (parseDayKey(entry.day) == null) return 'Neplatný den.';
    await _enqueue(() => store.put(Kinds.food, entry.toJson()));
    foods = [
      entry,
      for (final f in foods)
        if (f.id != entry.id) f,
    ]..sort(_newestFood);
    notifyListeners();
    return null;
  }

  Future<void> removeFood(String id) async {
    await _enqueue(() => store.remove(id));
    foods = foods.where((f) => f.id != id).toList();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // AI kouč: spíž, cíle, kontext pro návrhy
  // ---------------------------------------------------------------------

  /// Změna profilu počítaná až ve frontě z posledního uloženého stavu:
  /// dvě rychlé změny (barva, souhlas) se navzájem nepřepíšou.
  Future<void> _updateProfile(Profile Function(Profile current) change) =>
      _enqueue(() async {
        final next = change(profile);
        await store.put(Kinds.profile, next.toJson());
        profile = next;
        notifyListeners();
      });

  /// Náhodné ID instalace pro denní limit AI; vznikne při prvním použití.
  /// Nepatří do zálohy (jiné zařízení = jiná instalace).
  Future<String> installId() async {
    late String id;
    await _updateProfile((p) {
      final saved = p.extra['installId'];
      id = saved is String && saved.length == 36 ? saved : newId();
      return p.withExtra({'installId': id});
    });
    return id;
  }

  /// Poslední potvrzený seznam potravin doma.
  List<PantryItem> get pantry {
    final raw = profile.extra['pantry'];
    if (raw is! List) return const [];
    return [for (final i in raw) ?PantryItem.tryParse(i)];
  }

  Future<void> savePantry(List<PantryItem> items) => _updateProfile(
    (p) => p.withExtra({
      'pantry': items.isEmpty
          ? null
          : [for (final i in mergePantry([], items)) i.toJson()],
    }),
  );

  Set<String> get pantryExcluded => {
    for (final name in (profile.extra['pantryExcluded'] as List? ?? const []))
      if (name is String) pantryKey(name),
  };
  int get pantryMinutes => [10, 20, 40].contains(profile.extra['pantryMinutes'])
      ? profile.extra['pantryMinutes'] as int
      : 20;

  Future<void> savePantrySelection(Set<String> excluded, int minutes) =>
      _updateProfile(
        (p) => p.withExtra({
          'pantryExcluded': excluded.toList()..sort(),
          'pantryMinutes': [10, 20, 40].contains(minutes) ? minutes : 20,
        }),
      );

  List<MealIdea> get savedMealIdeas =>
      parseMeals({'meals': profile.extra['mealIdeas']});
  Future<void> saveMealIdeas(List<MealIdea> meals) => _updateProfile(
    (p) => p.withExtra({
      'mealIdeas': [for (final meal in meals.take(6)) meal.toJson()],
    }),
  );

  /// Úvod je za uživatelem; zároveň zná novinky této verze.
  Future<void> finishWelcome(String version) => _updateProfile(
    (p) => p.withExtra({'welcomeSeen': true, 'seenVersion': version}),
  );

  Future<void> markVersionSeen(String version) =>
      _updateProfile((p) => p.withExtra({'seenVersion': version}));

  /// Zapamatuje si záložku; chyba uložení nesmí rozbít přepnutí.
  Future<void> setLastTab(int tab) async {
    try {
      await _updateProfile(
        (p) => p.withExtra({'lastTab': tab == 1 ? 1 : null}),
      );
    } catch (e) {
      debugPrint('Záložku se nepodařilo uložit: $e');
    }
  }

  /// Chat s AI trenérem: posledních [maxCoachChat] zpráv v zařízení.
  List<ChatMessage> get coachChat => [
    if (profile.extra['coachChat'] case final List list)
      for (final m in list) ?ChatMessage.tryParse(m),
  ];

  Future<void> saveCoachChat(List<ChatMessage> messages) => _updateProfile(
    (p) => p.withExtra({
      'coachChat': messages.isEmpty
          ? null
          : [
              for (final m in messages.skip(
                messages.length > maxCoachChat
                    ? messages.length - maxCoachChat
                    : 0,
              ))
                m.toJson(),
            ],
    }),
  );

  /// Souhrn tréninků pro trenéra (bez jména a poznámek).
  Map<String, dynamic> trainerContext([DateTime? now]) {
    final at = now ?? DateTime.now();
    return coachContext(
      now: at,
      workouts: workouts,
      exercise: exercise,
      adult: profile.adult,
      weekGoal: weekGoal,
      split: split,
      todayDay: todaySplitDay,
      todaySuggestions: [
        if (todayDay case final day?)
          for (final (_, s) in plan(day)) s,
      ],
      mission: mission(at),
      trainingDays: profile.trainingDays,
      plan: planAnswers,
      bodyweightKg: bodyweights.firstOrNull?.kg,
      recovery: recoveryByFocus(
        workouts,
        at,
        muscleOf: (id) => exercise(id).muscle,
      ),
      focusNames: {for (final f in dayFocuses) f.id: f.name},
    );
  }

  /// Fakta pro místního trenéra: stejná čísla jako hlavní karta.
  CoachFacts coachFacts([DateTime? now]) {
    final at = now ?? DateTime.now();
    final s = split;
    final day = todayDay;
    final names = {for (final f in dayFocuses) f.id: f.name};
    final recovery = recoveryByFocus(
      workouts,
      at,
      muscleOf: (id) => exercise(id).muscle,
    );
    String label(String id) => exercise(id).name;

    final last = finishedNewestFirst(workouts).firstOrNull;
    final days = profile.trainingDays;
    const short = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];
    return CoachFacts(
      mission: mission(at),
      program: s?.name,
      day: day?.name,
      dayNumber: todaySplitDay + 1,
      dayCount: s?.days.length ?? 1,
      plan: [
        if (day != null)
          for (final (pl, sug) in plan(day))
            PlanLine(
              name: label(pl.exerciseId),
              sets: pl.sets,
              repMin: pl.repMin,
              repMax: pl.repMax,
              suggestion: sug,
              weighted: typeOf(pl.exerciseId) == ExerciseType.weighted,
            ),
      ],
      hardSets: {
        for (final e in weeklyHardSets(
          workouts,
          at,
          (id) => exercise(id).muscle,
        ).entries)
          names[e.key] ?? e.key: e.value,
      },
      ready: [
        for (final r in recovery.values)
          if (r.isReady && r.focusId != 'core') names[r.focusId] ?? r.focusId,
      ],
      tired: [
        for (final r in recovery.values)
          if (!r.isReady) names[r.focusId] ?? r.focusId,
      ],
      stalls: findStalls(workouts, at, typeOf, label),
      trainingDaysLeft: [
        if (days != null)
          for (final d in days)
            if (d >= at.weekday) short[d - 1],
      ],
      daysSinceLast: last == null ? null : at.difference(last.date).inDays,
      activeWorkout: active != null,
    );
  }

  Future<void> acceptAiNotice() =>
      _updateProfile((p) => p.withExtra({'aiNotice': true}));

  /// Nastaví cíle (`null` = bez cíle). Kalorický cíl jen pro dospělé.
  Future<void> setNutritionTargets({double? protein, double? kcal}) =>
      _updateProfile(
        (p) => p.withExtra({
          'proteinTarget': protein?.clamp(20, 400).roundToDouble(),
          'kcalTarget': p.restrictWeightLoss
              ? null
              : kcal?.clamp(1000, 6000).roundToDouble(),
        }),
      );

  /// Kolik bílkovin dnes zbývá do cíle; `null` bez cíle.
  double? proteinLeft([DateTime? now]) {
    final target = profile.proteinTarget;
    if (target == null) return null;
    final eaten = totalsOf(foodsOn(dayKey(now ?? DateTime.now()))).protein;
    return (target - eaten).clamp(0, target).toDouble();
  }

  /// Kontext pro návrh jídel: dnešní trénink, snědeno, zbývající bílkoviny.
  MealContext mealContext({required int maxMinutes, DateTime? now}) {
    final at = now ?? DateTime.now();
    final today = dayKey(at);
    final totals = totalsOf(foodsOn(today));
    final trainedToday = workouts.any((w) => dayKey(w.date.toLocal()) == today);
    return MealContext(
      trainingToday: trainedToday || mission(at).shouldTrain,
      eatenKcal: totals.kcal,
      eatenProtein: totals.protein,
      proteinLeft: proteinLeft(at),
      maxMinutes: maxMinutes,
      adult: profile.adult,
    );
  }

  String exportBackup({DateTime? now}) => encodeBackup(
    Backup(
      exportedAt: now ?? DateTime.now(),
      workouts: workouts,
      exercises: customExercises,
      bodyweights: bodyweights,
      foods: foods,
      settings: {
        for (final e in profile.extra.entries)
          if (backupSettingsKeys.contains(e.key)) e.key: e.value,
      },
    ),
  );

  String exportCsv() => workoutsToCsv(workouts, exercise);

  /// Doplní ze zálohy tréninky a vlastní cviky, které v zařízení chybí.
  /// Co už v zařízení je (i upravené po záloze), zůstane beze změny;
  /// nic se nemaže. Vrací počet doplněných tréninků.
  /// Neplatný soubor hodí [FormatException] s českou zprávou.
  Future<int> restoreBackup(String source) async {
    final backup = decodeBackup(source);
    final count = await _enqueue(() async {
      final haveWorkouts = {for (final w in workouts) w.id};
      final haveExercises = {for (final e in customExercises) e.id};
      final newWorkouts = [
        for (final w in backup.workouts)
          if (!haveWorkouts.contains(w.id)) w,
      ];
      final newExercises = [
        for (final e in backup.exercises)
          if (!haveExercises.contains(e.id)) e,
      ];
      // Nic místního se nepřepíše: ze zálohy se doplní jen chybějící
      // nastavení a programy, které tu ještě nejsou.
      final localPrograms = [...profile.extra['programs'] as List? ?? const []];
      final localIds = {
        for (final e in localPrograms)
          if (e is Map) e['id'],
      };
      final backupPrograms = backup.settings['programs'];
      final nextProfile = profile.withExtra({
        for (final e in backup.settings.entries)
          if (e.key != 'programs' && !profile.extra.containsKey(e.key))
            e.key: e.value,
        if (backupPrograms is List)
          'programs': [
            ...localPrograms,
            for (final e in backupPrograms)
              if (e is Map && !localIds.contains(e['id'])) e,
          ],
      });
      final haveWeights = {for (final b in bodyweights) b.id};
      final newWeights = [
        for (final b in backup.bodyweights)
          if (!haveWeights.contains(b.id)) b,
      ];
      final haveFoods = {for (final f in foods) f.id};
      final newFoods = [
        for (final f in backup.foods)
          if (!haveFoods.contains(f.id)) f,
      ];
      final docs = <(String, Map<String, dynamic>)>[
        for (final f in newFoods) (Kinds.food, f.toJson()),
        for (final b in newWeights) (Kinds.bodyweight, b.toJson()),
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
        (Kinds.profile, nextProfile.toJson()),
      ];
      for (final (kind, data) in docs) {
        if (kind == Kinds.profile) continue;
        final existing = await store.raw(data['id'] as String);
        if ((existing != null && existing['kind'] != kind) ||
            data['id'] == active?.id) {
          throw const FormatException(
            'Záloha obsahuje kolidující ID. Nic nebylo obnoveno.',
          );
        }
      }
      await store.putAll(docs);
      workouts = [...newWorkouts, ...workouts]
        ..sort((a, b) => b.date.compareTo(a.date));
      customExercises = [...newExercises, ...customExercises]
        ..sort((a, b) => a.name.compareTo(b.name));
      profile = nextProfile;
      bodyweights = [...newWeights, ...bodyweights]
        ..sort((a, b) => b.date.compareTo(a.date));
      foods = [...newFoods, ...foods]..sort(_newestFood);
      return newWorkouts.length;
    });
    notifyListeners();
    unawaited(syncReminders());
    return count;
  }

  /// Doplní tréninky z exportu Hevy. Už existující (stejný začátek a název)
  /// přeskočí, takže opakovaný import nic nezdvojí. Vrací počet přidaných.
  Future<int> importHevy(String source) async {
    final count = await _enqueue(() async {
      final parsed = parseHevyCsv(source, custom: customExercises);
      // Smazaný trénink se opakovaným importem nevrací.
      final deleted = <String>{
        for (final w in parsed.workouts)
          if ((await store.raw(w.id))?['deleted'] == 1) w.id,
      };
      final haveWorkouts = {for (final w in workouts) w.id, ...deleted};
      final haveExercises = {for (final e in customExercises) e.id};
      final newWorkouts = [
        for (final w in parsed.workouts)
          if (!haveWorkouts.contains(w.id)) w,
      ];
      final newExercises = [
        for (final e in parsed.newExercises)
          if (!haveExercises.contains(e.id)) e,
      ];
      await store.putAll([
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
      ]);
      workouts = [...newWorkouts, ...workouts]
        ..sort((a, b) => b.date.compareTo(a.date));
      customExercises = [...newExercises, ...customExercises]
        ..sort((a, b) => a.name.compareTo(b.name));
      return newWorkouts.length;
    });
    notifyListeners();
    unawaited(syncReminders());
    return count;
  }

  /// Smaže všechna data v zařízení včetně souhlasu (aplikace začne znovu).
  Future<void> wipeAll() async {
    await _enqueue(store.wipeLocal);
    profile = const Profile();
    workouts = [];
    active = null;
    customExercises = [];
    bodyweights = [];
    foods = [];
    notifyListeners();
    if (notifier.supported) unawaited(notifier.cancelAll());
    // Budík pauzy má vlastní id, cancelAll ho nezruší.
    unawaited(syncRest());
  }
}
