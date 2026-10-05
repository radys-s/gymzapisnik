import 'dart:async';

import 'package:flutter/foundation.dart';

import '../coach/missions.dart';
import '../coach/progression.dart';
import '../coach/splits.dart';
import '../coach/streak.dart';
import '../core/ids.dart';
import '../data/backup.dart';
import '../domain/bodyweight.dart';
import '../data/hevy_import.dart';
import '../data/csv.dart';
import '../data/store.dart';
import '../domain/catalog.dart';
import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/profile.dart';
import '../coach/reminders.dart';
import '../notify/notifier.dart';
import '../premium/entitlements.dart';

/// Druhy dokumentů v úložišti.
abstract final class Kinds {
  static const profile = 'profile';
  static const workout = 'workout';
  static const exercise = 'exercise';
  static const bodyweight = 'bodyweight';
}

/// Stav aplikace sdílený obrazovkami. UI nesahá přímo na úložiště.
class AppState extends ChangeNotifier {
  final LocalStore store;
  AppState(
    this.store, {
    this.paywall = paywallEnabled,
    this.notifier = const NoopNotifier(),
  });

  /// Místní oznámení (na webu a iPhonu prázdná implementace).
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

  Future<void> load() async {
    await store.open();
    final json = await store.get(Profile.id);
    profile = json == null ? const Profile() : Profile.fromJson(json);
    final all = [
      for (final w in await store.all(Kinds.workout)) Workout.fromJson(w),
    ];
    workouts = all.where((w) => w.finished).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final unfinished = all.where((w) => !w.finished).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    active = unfinished.firstOrNull;
    customExercises = [
      for (final e in await store.all(Kinds.exercise)) Exercise.fromJson(e),
    ]..sort((a, b) => a.name.compareTo(b.name));
    bodyweights = [
      for (final b in await store.all(Kinds.bodyweight)) BodyWeight.fromJson(b),
    ]..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(syncReminders());
  }

  Future<void> acceptConsent({
    required bool adult,
    required bool guardianConsent,
  }) async {
    final next = profile.acceptConsent(
      adult: adult,
      guardianConsent: guardianConsent,
      now: DateTime.now(),
    );
    await store.put(Kinds.profile, next.toJson());
    profile = next;
    notifyListeners();
  }

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
    await store.put(Kinds.exercise, exercise.toJson());
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

  Future<void> _enqueue(Future<void> Function() write) {
    final previous = _writes;
    final next = previous == null ? write() : previous.then((_) => write());
    _writes = next.catchError((_) {});
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
    final existing = active;
    if (existing != null) return existing;
    final start = now ?? DateTime.now();
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

  Future<void> removeExercise(WorkoutExercise entry) {
    active?.exercises.remove(entry);
    return saveActive();
  }

  /// Další série: hodnoty z minula na stejné pozici, jinak kopie poslední.
  Future<SetEntry> addSet(WorkoutExercise entry) async {
    final last = lastSetsOf(entry.exerciseId);
    final index = entry.sets.length;
    final source = index < last.length
        ? last[index]
        : entry.sets.lastOrNull ?? SetEntry();
    final set = source.copy(done: false)..warmup = false;
    entry.sets.add(set);
    await saveActive();
    return set;
  }

  Future<void> removeSet(WorkoutExercise entry, SetEntry set) {
    entry.sets.remove(set);
    return saveActive();
  }

  /// Označí sérii jako hotovou (nebo zpět). Vrací chybovou hlášku,
  /// když se série nedá potvrdit. Potvrzení spustí pauzu.
  Future<String?> toggleDone(SetEntry set, {DateTime? now}) async {
    if (!set.done) {
      if (set.reps <= 0) return 'Zadej počet opakování.';
      if (set.weight < 0 || !set.weight.isFinite) return 'Neplatná váha.';
    }
    set.done = !set.done;
    if (set.done) {
      _setRestEnd(
        (now ?? DateTime.now()).add(Duration(seconds: profile.restSeconds)),
      );
    }
    await saveActive();
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
  Future<void> adjustRest(Duration delta, {DateTime? now}) {
    final end = restEndsAt;
    if (end == null) return Future.value();
    final next = end.add(delta);
    _setRestEnd(next.isAfter(now ?? DateTime.now()) ? next : null);
    return saveActive();
  }

  Future<void> skipRest() {
    if (restEndsAt == null) return Future.value();
    _setRestEnd(null);
    return saveActive();
  }

  Future<void> toggleWarmup(SetEntry set) {
    set.warmup = !set.warmup;
    return saveActive();
  }

  /// Dokončí trénink: uloží jen potvrzené série a cviky, které nějakou mají.
  /// Vrací dokončený trénink, nebo chybovou hlášku.
  Future<({Workout? workout, String? error})> finishActive({
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
      rethrow;
    }
    workouts = [finished, ...workouts.where((w) => w.id != finished.id)]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(syncReminders());
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
  }

  // ---------------------------------------------------------------------
  // Split a progrese
  // ---------------------------------------------------------------------

  SplitTemplate? get split => findSplit(profile.splitId);

  Future<void> setSplit(String? id) async {
    final next = profile.withExtra({'split': id});
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
    unawaited(syncReminders());
  }

  /// Označí profil jako Pro (až bude hotová platba, volá se po nákupu).
  Future<void> setPro(bool value) async {
    final next = profile.withExtra({'pro': value ? true : null});
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
  }

  /// Týdenní cíl tréninků: vlastní, jinak podle splitu, jinak 3.
  int get weekGoal => profile.weekGoal ?? split?.perWeek ?? 3;

  /// Čas připomínky (minuty od půlnoci) nebo `null` = vypnout. Při zapnutí
  /// se zeptá na povolení; vrací `false`, když ho uživatel odmítl.
  Future<bool> setReminder(int? minutes) async {
    if (minutes != null && !await notifier.requestPermission()) {
      return false;
    }
    final next = profile.withExtra({'reminder': minutes?.clamp(0, 1439)});
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
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
    final next = profile.withExtra({'backupCount': workouts.length});
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
  }

  Future<void> setWeekGoal(int? goal) async {
    final next = profile.withExtra({'weekGoal': goal?.clamp(1, 7)});
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
    unawaited(syncReminders());
  }

  /// Dnešní mise podle týdenního cíle a odcvičených tréninků.
  Mission mission([DateTime? now]) => todayMission(
    goal: weekGoal,
    finished: [for (final w in workouts) w.date],
    now: now ?? DateTime.now(),
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
    return workout;
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
  Future<void> saveBeforeUpdate() => saveActive();

  // ---------------------------------------------------------------------
  // Nastavení, záloha, export
  // ---------------------------------------------------------------------

  /// Změní nastavení v profilu (`null` = beze změny).
  Future<void> setPreferences({int? restSeconds, String? theme}) async {
    final next = profile.withExtra({
      'restSeconds': ?restSeconds?.clamp(15, 600),
      'theme': ?theme,
    });
    await _enqueue(() => store.put(Kinds.profile, next.toJson()));
    profile = next;
    notifyListeners();
  }

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

  String exportBackup({DateTime? now}) => encodeBackup(
    Backup(
      exportedAt: now ?? DateTime.now(),
      workouts: workouts,
      exercises: customExercises,
      bodyweights: bodyweights,
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
    final nextProfile = profile.withExtra(backup.settings);
    final haveWeights = {for (final b in bodyweights) b.id};
    final newWeights = [
      for (final b in backup.bodyweights)
        if (!haveWeights.contains(b.id)) b,
    ];
    await _enqueue(
      () => store.putAll([
        for (final b in newWeights) (Kinds.bodyweight, b.toJson()),
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
        (Kinds.profile, nextProfile.toJson()),
      ]),
    );
    workouts = [...newWorkouts, ...workouts]
      ..sort((a, b) => b.date.compareTo(a.date));
    customExercises = [...newExercises, ...customExercises]
      ..sort((a, b) => a.name.compareTo(b.name));
    profile = nextProfile;
    bodyweights = [...newWeights, ...bodyweights]
      ..sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    unawaited(syncReminders());
    return newWorkouts.length;
  }

  /// Doplní tréninky z exportu Hevy. Už existující (stejný začátek a název)
  /// přeskočí, takže opakovaný import nic nezdvojí. Vrací počet přidaných.
  Future<int> importHevy(String source) async {
    final parsed = parseHevyCsv(source, custom: customExercises);
    final haveWorkouts = {for (final w in workouts) w.id};
    final haveExercises = {for (final e in customExercises) e.id};
    final newWorkouts = [
      for (final w in parsed.workouts)
        if (!haveWorkouts.contains(w.id)) w,
    ];
    final newExercises = [
      for (final e in parsed.newExercises)
        if (!haveExercises.contains(e.id)) e,
    ];
    await _enqueue(
      () => store.putAll([
        for (final e in newExercises) (Kinds.exercise, e.toJson()),
        for (final w in newWorkouts) (Kinds.workout, w.toJson()),
      ]),
    );
    workouts = [...newWorkouts, ...workouts]
      ..sort((a, b) => b.date.compareTo(a.date));
    customExercises = [...newExercises, ...customExercises]
      ..sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    unawaited(syncReminders());
    return newWorkouts.length;
  }

  /// Smaže všechna data v zařízení včetně souhlasu (aplikace začne znovu).
  Future<void> wipeAll() async {
    await _enqueue(store.wipeLocal);
    profile = const Profile();
    workouts = [];
    active = null;
    customExercises = [];
    bodyweights = [];
    notifyListeners();
    if (notifier.supported) unawaited(notifier.cancelAll());
  }
}
