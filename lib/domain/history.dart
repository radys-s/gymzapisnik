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

/// Rekordy, které série v rozběhnutém tréninku právě drží proti historii
/// [before]. Při shodě v tréninku patří rekord první takové sérii; když
/// ji později překoná jiná série, rekord se přesune na ni.
///
/// Bez historie cviku rekord nevzniká (stejně jako u [newRecords]).
List<RecordKind> liveRecordKinds({
  required SetEntry set,
  required List<SetEntry> sessionSets,
  required Map<RecordKind, PersonalRecord> before,
  required ExerciseType type,
}) {
  if (!set.counts || before.isEmpty) return const [];
  final result = <RecordKind>[];
  for (final kind in recordKinds(type)) {
    final value = recordValue(kind, set);
    if (value <= 0 || value <= (before[kind]?.value ?? 0)) continue;
    SetEntry? leader;
    var best = 0.0;
    for (final s in sessionSets.where((s) => s.counts)) {
      final v = recordValue(kind, s);
      if (leader == null || v > best) {
        leader = s;
        best = v;
      }
    }
    if (identical(leader, set)) result.add(kind);
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

/// Souhrn od pondělí 00:00 místního času do konce týdne.
WeekSummary weekSummary(
  Iterable<Workout> workouts,
  DateTime now,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final local = now.toLocal();
  return _summaryOfWeek(
    workouts,
    DateTime(local.year, local.month, local.day - (local.weekday - 1)),
    typeOf,
  );
}

/// Souhrn předchozího týdne (pondělí až neděle).
WeekSummary previousWeekSummary(
  Iterable<Workout> workouts,
  DateTime now,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final local = now.toLocal();
  return _summaryOfWeek(
    workouts,
    DateTime(local.year, local.month, local.day - (local.weekday - 1) - 7),
    typeOf,
  );
}

WeekSummary _summaryOfWeek(
  Iterable<Workout> workouts,
  DateTime monday,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final end = DateTime(monday.year, monday.month, monday.day + 7);
  var count = 0;
  var sets = 0;
  var kg = 0.0;
  for (final w in workouts) {
    final at = w.date.toLocal();
    if (!w.finished || at.isBefore(monday) || !at.isBefore(end)) continue;
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

/// Počet cviků s novým rekordem v tomto týdnu (každý cvik nejvýš jednou).
int weekRecordCount(
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
  final end = DateTime(monday.year, monday.month, monday.day + 7);
  final exercises = <String>{};
  for (final w in workouts) {
    final at = w.date.toLocal();
    if (!w.finished || at.isBefore(monday) || !at.isBefore(end)) continue;
    for (final r in newRecords(w, workouts, typeOf)) {
      exercises.add(r.exerciseId);
    }
  }
  return exercises.length;
}

/// Bod grafu progresu: jeden trénink.
class ProgressPoint {
  final DateTime date;
  final double value;
  const ProgressPoint(this.date, this.value);
}

/// Progres cviku po trénincích, od nejstaršího: s váhou nejlepší odhad 1RM,
/// s vlastní váhou nejvíc opakování v sérii.
List<ProgressPoint> progressSeries(
  Iterable<Workout> workouts,
  String exerciseId,
  ExerciseType type,
) {
  final byWorkout = <String, ProgressPoint>{};
  for (final session in exerciseHistory(workouts, exerciseId)) {
    for (final set in session.entry.countedSets) {
      final value = type == ExerciseType.weighted
          ? e1rm(set.weight, set.reps)
          : set.reps.toDouble();
      final current = byWorkout[session.workout.id];
      if (current == null || value > current.value) {
        byWorkout[session.workout.id] = ProgressPoint(session.date, value);
      }
    }
  }
  return byWorkout.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

/// Nedávné osobní rekordy, od nejnovějšího. Z každého cviku jen jeden
/// (nejnovější). Prohledává jen posledních [scan] tréninků.
List<PersonalRecord> recentRecords(
  Iterable<Workout> workouts,
  ExerciseType Function(String exerciseId) typeOf, {
  int limit = 3,
  int scan = 20,
}) {
  final result = <PersonalRecord>[];
  final seen = <String>{};
  for (final w in finishedNewestFirst(workouts).take(scan)) {
    for (final r in newRecords(w, workouts, typeOf)) {
      if (seen.add(r.exerciseId)) result.add(r);
      if (result.length >= limit) return result;
    }
  }
  return result;
}

/// Nejčastěji cvičený cvik (podle počtu tréninků), nebo `null`.
/// Při shodě vyhrává cvik z novějšího tréninku (seznam je od nejnovějšího).
String? mostTrainedExercise(Iterable<Workout> workouts) {
  final counts = <String, int>{};
  for (final w in finishedNewestFirst(workouts)) {
    for (final id in {
      for (final e in w.exercises)
        if (e.countedSets.isNotEmpty) e.exerciseId,
    }) {
      counts.update(id, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}
