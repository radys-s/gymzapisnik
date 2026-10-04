import 'package:flutter/foundation.dart';

import '../core/ids.dart';
import '../data/store.dart';
import '../domain/catalog.dart';
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

  /// Uloží rozepsaná data před aktualizací webové verze.
  Future<void> saveBeforeUpdate() async {}
}
