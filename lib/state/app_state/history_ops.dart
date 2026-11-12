part of '../app_state.dart';

/// Historie.
extension HistoryOps on AppState {
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
    _changed();
    unawaited(syncReminders());
    return null;
  }

  Future<void> deleteWorkout(Workout workout) async {
    await _enqueue(() => store.remove(workout.id));
    workouts = workouts.where((w) => w.id != workout.id).toList();
    _changed();
    unawaited(syncReminders());
  }

  /// Vrátí smazaný dokončený trénink („Vrátit“ po smazání).
  Future<void> restoreWorkout(Workout workout) async {
    if (workouts.any((w) => w.id == workout.id)) return;
    await _enqueue(() => store.put(Kinds.workout, workout.toJson()));
    workouts = [workout, ...workouts]..sort((a, b) => b.date.compareTo(a.date));
    _changed();
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
}
