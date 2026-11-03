/// Rutina z odcvičeného tréninku: stejné cviky, počet sérií a rozsah
/// opakování. Čistý Dart bez Flutteru.
library;

import '../domain/models.dart';
import 'splits.dart';

/// Program o jednom dni podle tréninku. `null`, když trénink nemá
/// žádnou pracovní sérii.
SplitTemplate? routineFromWorkout(Workout workout) {
  final exercises = <PlannedExercise>[];
  for (final e in workout.exercises) {
    // Drop a do selhání nejsou předpis: rozsah i počet z běžných sérií.
    final normal = [
      for (final s in e.countedSets)
        if (s.kind == SetKind.normal) s,
    ];
    final sets = normal.isEmpty ? e.countedSets : normal;
    if (sets.isEmpty) continue;
    if (exercises.any((p) => p.exerciseId == e.exerciseId)) continue;
    final reps = [for (final s in sets) s.reps.clamp(1, 50)]..sort();
    // Stejná opakování ve všech sériích: rozsah +2, ať je kam růst.
    final high = reps.last > reps.first ? reps.last : reps.first + 2;
    final low = high > 50 ? 48 : reps.first;
    exercises.add(
      PlannedExercise(
        e.exerciseId,
        sets: sets.length.clamp(1, 10),
        repMin: low,
        repMax: high.clamp(1, 50),
      ),
    );
    if (exercises.length >= maxDayExercises) break;
  }
  if (exercises.isEmpty) return null;
  var name = workout.name.trim().isEmpty ? 'Trénink' : workout.name.trim();
  if (name.length > maxNameLength) name = name.substring(0, maxNameLength);
  return SplitTemplate(
    id: '',
    name: name,
    description: 'Uloženo z tréninku',
    perWeek: 1,
    days: [SplitDay(name, exercises)],
    custom: true,
  );
}
