import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../data/store.dart';
import '../domain/catalog.dart';
import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/profile.dart';

/// Druhy dokumentů v úložišti.
abstract final class Kinds {
  static const profile = 'profile';
  static const workout = 'workout';
  static const exercise = 'exercise';
}

/// Stav aplikace sdílený obrazovkami. UI nesahá přímo na úložiště.
class AppState extends ChangeNotifier {
  final LocalStore store;
  AppState(this.store);

  Profile profile = const Profile();

  /// Dokončené tréninky od nejnovějšího.
  List<Workout> workouts = [];

  /// Rozepsaný trénink (nejvýš jeden).
  Workout? active;

  List<Exercise> customExercises = [];

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
    notifyListeners();
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
      ..sets = fresh.sets;
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
  /// když se série nedá potvrdit.
  Future<String?> toggleDone(SetEntry set) async {
    if (!set.done) {
      if (set.reps <= 0) return 'Zadej počet opakování.';
      if (set.weight < 0 || !set.weight.isFinite) return 'Neplatná váha.';
    }
    set.done = !set.done;
    await saveActive();
    return null;
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
    final done = workout.copy();
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

  /// Uloží rozepsaná data před aktualizací webové verze.
  Future<void> saveBeforeUpdate() => saveActive();
}
