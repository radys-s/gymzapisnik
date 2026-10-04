import 'models.dart';
import 'stats.dart';

/// Jedno provedení cviku v dokončeném tréninku.
class ExerciseSession {
  final Workout workout;
  final WorkoutExercise entry;
  const ExerciseSession(this.workout, this.entry);
  DateTime get date => workout.date;
}

/// Dokončené tréninky od nejnovějšího.
List<Workout> finishedNewestFirst(Iterable<Workout> workouts) =>
    workouts.where((w) => w.finished).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

/// Všechna provedení cviku se započítanou sérií, od nejstaršího.
List<ExerciseSession> exerciseHistory(
  Iterable<Workout> workouts,
  String exerciseId,
) {
  final result = <ExerciseSession>[];
  for (final w in finishedNewestFirst(workouts).reversed) {
    for (final e in w.exercises) {
      if (e.exerciseId == exerciseId && e.countedSets.isNotEmpty) {
        result.add(ExerciseSession(w, e));
      }
    }
  }
  return result;
}

/// Poslední provedení cviku před daným okamžikem (bez daného tréninku).
/// Z něj se předvyplňují hodnoty a porovnává „dnes vs minule“.
ExerciseSession? lastPerformance(
  Iterable<Workout> workouts,
  String exerciseId, {
  String? excludeWorkoutId,
  DateTime? before,
}) {
  final candidates = exerciseHistory(workouts, exerciseId).where(
    (s) =>
        s.workout.id != excludeWorkoutId &&
        (before == null || s.date.isBefore(before)),
  );
  return candidates.isEmpty ? null : candidates.last;
}

/// Nejlepší výkony cviku ze všech dokončených tréninků.
Map<RecordKind, PersonalRecord> allTimeRecords(
  Iterable<Workout> workouts,
  String exerciseId,
  ExerciseType type,
) {
  final records = <RecordKind, PersonalRecord>{};
  for (final session in exerciseHistory(workouts, exerciseId)) {
    for (final set in session.entry.countedSets) {
      for (final kind in recordKinds(type)) {
        final value = recordValue(kind, set);
        if (value <= 0) continue;
        final current = records[kind];
        if (current == null || value > current.value) {
          records[kind] = PersonalRecord(
            exerciseId: exerciseId,
            kind: kind,
            value: value,
            set: set,
            workoutId: session.workout.id,
            date: session.date,
          );
        }
      }
    }
  }
  return records;
}

/// Nové osobní rekordy, které trénink přinesl proti starší historii.
///
/// První provedení cviku rekord nevytváří (nebylo s čím srovnat).
List<PersonalRecord> newRecords(
  Workout workout,
  Iterable<Workout> workouts,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final earlier = workouts.where(
    (w) => w.finished && w.id != workout.id && w.date.isBefore(workout.date),
  );
  final result = <PersonalRecord>[];
  final seen = <String>{};
  for (final entry in workout.exercises) {
    if (!seen.add(entry.exerciseId)) continue;
    final type = typeOf(entry.exerciseId);
    final before = allTimeRecords(earlier, entry.exerciseId, type);
    if (before.isEmpty) continue;
    final sets = [
      for (final e in workout.exercises)
        if (e.exerciseId == entry.exerciseId) ...e.countedSets,
    ];
    for (final kind in recordKinds(type)) {
      PersonalRecord? best;
      for (final set in sets) {
        final value = recordValue(kind, set);
        if (value <= 0) continue;
        if (best == null || value > best.value) {
          best = PersonalRecord(
            exerciseId: entry.exerciseId,
            kind: kind,
            value: value,
            set: set,
            workoutId: workout.id,
            date: workout.date,
          );
        }
      }
      final previous = before[kind]?.value ?? 0;
      if (best != null && best.value > previous) result.add(best);
    }
  }
  return result;
}

class WeekSummary {
  final int workouts;
  final int sets;

  /// Jen cviky s váhou (kg × opakování).
  final double volumeKg;
  const WeekSummary(this.workouts, this.sets, this.volumeKg);
}

/// Souhrn od pondělí 00:00 místního času.
WeekSummary weekSummary(
  Iterable<Workout> workouts,
  DateTime now,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final local = now.toLocal();
  final monday = DateTime(
    local.year,
    local.month,
    local.day - (local.weekday - 1),
  );
  var count = 0;
  var sets = 0;
  var kg = 0.0;
  for (final w in workouts) {
    if (!w.finished || w.date.toLocal().isBefore(monday)) continue;
    count++;
    for (final e in w.exercises) {
      sets += e.countedSets.length;
      if (typeOf(e.exerciseId) == ExerciseType.weighted) {
        kg += volume(ExerciseType.weighted, e.sets);
      }
    }
  }
  return WeekSummary(count, sets, kg);
}
