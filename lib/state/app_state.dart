import 'dart:async';

import 'package:flutter/foundation.dart';

import '../ai/ai_config.dart';
import '../ai/fridge_coach.dart';
import '../ai/trainer.dart';
import '../coach/missions.dart';
import '../coach/plan_quiz.dart';
import '../coach/plates.dart';
import '../coach/progression.dart';
import '../coach/push.dart';
import '../coach/weeks.dart';
import '../coach/splits.dart';
import '../coach/start_weight.dart';
import '../coach/achievements.dart';
import '../coach/coach_context.dart';
import '../coach/local_coach.dart';
import '../coach/recovery.dart';
import '../coach/streak.dart';
import '../coach/tips.dart';
import '../core/diagnostics.dart';
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
import '../domain/profile_keys.dart';
import '../domain/set_match.dart';
import '../domain/stats.dart';
import '../coach/nutrition_target.dart';
import '../coach/reminders.dart';
import '../notify/notifier.dart';
import '../premium/entitlements.dart';

part 'app_state/active_workout.dart';
part 'app_state/rest_timer.dart';
part 'app_state/program_ops.dart';
part 'app_state/history_ops.dart';
part 'app_state/settings_ops.dart';
part 'app_state/coach_ops.dart';

/// Druhy dokumentů v úložišti.
abstract final class Kinds {
  static const profile = 'profile';
  static const workout = 'workout';
  static const exercise = 'exercise';
  static const bodyweight = 'bodyweight';
  static const food = 'food';
}

/// Stav aplikace sdílený obrazovkami. UI nesahá přímo na úložiště.
///
/// Tento soubor drží data a mezipaměti. Operace jsou rozdělené podle
/// oblasti do rozšíření v `app_state/` (aktivní trénink, pauza, program,
/// historie, nastavení a záloha, AI kouč); rozšíření nemůže mít vlastní
/// pole, proto jejich stav zůstává tady.
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

  /// Zvyšuje se při každé změně rozepsaného tréninku na místě (série,
  /// pauza), protože objekt [active] zůstává stejný.
  int _activeRev = 0;

  /// Úzké odběry změn: obrazovka se překreslí, jen když se změní data,
  /// která opravdu ukazuje. Ťuknutí na sérii tak nepřekreslí Stravu
  /// ani Pokrok.
  late final StateSlices on = StateSlices._(this);

  /// Mezipaměť odvozených hodnot; platí, dokud se nezmění [deps].
  /// Seznamy se při změně vždy nahrazují novými, takže stačí identita.
  final Map<String, (Object?, Object?)> _memo = {};

  /// Spočítá [compute] jen jednou pro stejné [deps] (porovnání `==`,
  /// u seznamů tedy identita).
  T memo<T>(String key, Object? deps, T Function() compute) {
    final hit = _memo[key];
    if (hit != null && hit.$1 == deps) return hit.$2 as T;
    final value = compute();
    _memo[key] = (deps, value);
    return value;
  }

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
        Diagnostics.record(
          'Přeskočen poškozený záznam ${row['id']}: $e',
          where: 'načtení',
        );
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
        ProfileKey.welcomeSeen: true,
        ProfileKey.seenVersion: welcomeVersion,
        ProfileKey.onboardingStep: null,
      },
      // Upozornění na AI bylo součástí souhlasu: trenér se už neptá znovu.
      if (aiNotice) ProfileKey.aiNotice: true,
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

  /// Pro rozšíření v částech knihovny (`notifyListeners` je chráněné).
  void _changed() => notifyListeners();

  // Aktivní trénink: stav pro app_state/active_workout.dart
  /// Zápisy se řadí za sebe, aby rychlé klikání nepřepsalo novější stav
  /// starším a dokončení počkalo na rozepsané uložení.
  /// Výchozí `null` místo `Future.value()`: hotová future si pamatuje zónu,
  /// ve které vznikla, a v testech s falešným časem by fronta nikdy nedoběhla.
  Future<void>? _writes;
  Future<({Workout? workout, String? error})>? _finishing;
  static const _weekdays = [
    'pondělí',
    'úterý',
    'středa',
    'čtvrtek',
    'pátek',
    'sobota',
    'neděle',
  ];
  List<Workout>? _badgesOf;
  List<Exercise>? _badgesExercises;
  List<BadgeState> _badges = const [];
  static (int, int, int) _day(DateTime t) {
    final l = t.toLocal();
    return (l.year, l.month, l.day);
  }

  // Pauza mezi sériemi: stav pro app_state/rest_timer.dart
  static const _restKey = 'restEndsAt';
  Future<void>? _restUpdates;

  // Split a progrese: stav pro app_state/program_ops.dart
  Profile? _splitOf;
  SplitTemplate? _split;
  Profile? _programsOf;
  List<SplitTemplate> _programs = const [];

  /// Po každých tolika nových trénincích od poslední zálohy aplikace
  /// připomene zálohu (data jsou jen v zařízení).
  static const backupEvery = 10;

  /// Ručně zvolený jiný den a program, ke kterému patří.
  (String, int)? _dayPick;

  // Nastavení, záloha, export: stav pro app_state/settings_ops.dart
  static int _newestFood(FoodEntry a, FoodEntry b) {
    final byDay = b.day.compareTo(a.day);
    return byDay != 0 ? byDay : b.loggedAt.compareTo(a.loggedAt);
  }

  /// Klíč jídla pro nedávná a oblíbená: název bez velikosti písmen + kód.
  static String foodKey(FoodEntry f) =>
      '${f.name.trim().toLowerCase()}|${f.barcode ?? ''}';
  static FoodEntry? _tryFood(Map<String, dynamic> json) {
    try {
      final f = FoodEntry.fromJson(json);
      return f.name.trim().isEmpty ? null : f;
    } catch (_) {
      return null;
    }
  }

  // AI kouč: spíž, cíle, kontext pro návrhy: stav pro app_state/coach_ops.dart
  static const _proteinMinKcal = 800.0;
  ({(List<FoodEntry>, String, double) key, ProteinWeek? value})? _proteinCache;
}

/// Odběr jen části stavu: ozve se, když se změní klíč z [_key].
class StateSlice extends ChangeNotifier {
  final AppState _state;
  final Object? Function(AppState s) _key;
  Object? _last;
  bool _attached = false;

  StateSlice._(this._state, this._key);

  void _check() {
    final next = _key(_state);
    if (next == _last) return;
    _last = next;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_attached) {
      _attached = true;
      _last = _key(_state);
      _state.addListener(_check);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    // Podle skutečných posluchačů, ne počítadla: odebrání neznámého
    // posluchače tak nikdy neodpojí ostatní.
    if (_attached && !hasListeners) {
      _attached = false;
      _state.removeListener(_check);
    }
  }
}

/// Části stavu, na které obrazovky reagují.
class StateSlices {
  /// Rozepsaný trénink: série, pauza, začátek a konec.
  final StateSlice active;

  /// Dokončené tréninky, vlastní cviky a tělesná váha.
  final StateSlice history;

  /// Výživový deník.
  final StateSlice food;

  /// Profil: nastavení, plán, cíle.
  final StateSlice profile;

  /// Jen platnost souhlasu (rozhoduje mezi úvodem a aplikací).
  final StateSlice consent;

  StateSlices._(AppState s)
    : active = StateSlice._(s, (s) => (s.active, s._activeRev)),
      history = StateSlice._(
        s,
        (s) => (s.workouts, s.customExercises, s.bodyweights),
      ),
      food = StateSlice._(s, (s) => s.foods),
      profile = StateSlice._(s, (s) => (s.profile, s._dayPick)),
      consent = StateSlice._(s, (s) => s.profile.hasValidConsent);

  /// Všechno kromě rozepsaného tréninku (obrazovky mimo trénink).
  late final Listenable resting = Listenable.merge([history, food, profile]);

  /// Všechno.
  late final Listenable any = Listenable.merge([
    active,
    history,
    food,
    profile,
  ]);
}
