/// Týdenní report z místních dat: tréninky, čas, série, objem po dnech,
/// rekordy a nejsilnější cvik týdne. Čistý Dart.
library;

import '../coach/weeks.dart';
import 'history.dart';
import 'models.dart';
import 'stats.dart';

class WeekReport {
  /// Pondělí 00:00 místního času.
  final DateTime monday;
  final int workouts;
  final Duration time;
  final int sets;
  final int reps;

  /// Jen cviky s váhou (kg × opakování).
  final double volumeKg;

  /// Po–Ne: objem v kg (cviky s váhou).
  final List<double> dailyVolume;

  /// Po–Ne: počítané série (všechny cviky).
  final List<int> dailySets;

  /// Nové rekordy týdne, od nejnovějšího; z každého cviku a druhu jen
  /// nejlepší.
  final List<PersonalRecord> records;

  /// Cvik s největším objemem v týdnu (u vlastní váhy nejvíc sérií).
  final String? topExerciseId;

  const WeekReport({
    required this.monday,
    required this.workouts,
    required this.time,
    required this.sets,
    required this.reps,
    required this.volumeKg,
    required this.dailyVolume,
    required this.dailySets,
    required this.records,
    required this.topExerciseId,
  });

  bool get isEmpty => workouts == 0;

  /// Neděle 23:59:59.999 téhož týdne.
  DateTime get end =>
      nextWeek(monday).subtract(const Duration(milliseconds: 1));
}

/// Report týdne, do kterého patří [day].
WeekReport weekReport(
  Iterable<Workout> workouts,
  DateTime day,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final monday = weekStart(day);
  final next = nextWeek(monday);
  final all = workouts.toList();
  var count = 0;
  var time = Duration.zero;
  var sets = 0;
  var reps = 0;
  var kg = 0.0;
  final dailyVolume = List<double>.filled(7, 0);
  final dailySets = List<int>.filled(7, 0);
  final records = <PersonalRecord>[];
  final volumeBy = <String, double>{};
  final setsBy = <String, int>{};
  for (final w in all) {
    final at = w.date.toLocal();
    if (!w.finished || at.isBefore(monday) || !at.isBefore(next)) continue;
    count++;
    final length = w.finishedAt!.difference(w.startedAt);
    // Zapomenutý trénink nechá čas běžet; strop drží součet uvěřitelný.
    if (!length.isNegative) {
      time += length > const Duration(hours: 4)
          ? const Duration(hours: 4)
          : length;
    }
    final d = at.weekday - 1;
    for (final e in w.exercises) {
      final counted = e.countedSets;
      sets += counted.length;
      dailySets[d] += counted.length;
      setsBy[e.exerciseId] = (setsBy[e.exerciseId] ?? 0) + counted.length;
      for (final s in counted) {
        reps += s.reps;
      }
      if (typeOf(e.exerciseId) == ExerciseType.weighted) {
        final v = volume(ExerciseType.weighted, e.sets);
        kg += v;
        dailyVolume[d] += v;
        volumeBy[e.exerciseId] = (volumeBy[e.exerciseId] ?? 0) + v;
      }
    }
    records.addAll(newRecords(w, all, typeOf));
  }
  // Rekord z úterý, který v pátek padl znovu, se ukáže jen jednou.
  final best = <(String, RecordKind), PersonalRecord>{};
  for (final r in records) {
    final key = (r.exerciseId, r.kind);
    if ((best[key]?.value ?? double.negativeInfinity) < r.value) best[key] = r;
  }
  records
    ..clear()
    ..addAll(best.values)
    ..sort((a, b) => b.date.compareTo(a.date));
  String? top;
  if (volumeBy.values.any((v) => v > 0)) {
    top = volumeBy.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  } else if (setsBy.values.any((v) => v > 0)) {
    top = setsBy.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }
  return WeekReport(
    monday: monday,
    workouts: count,
    time: time,
    sets: sets,
    reps: reps,
    volumeKg: kg,
    dailyVolume: dailyVolume,
    dailySets: dailySets,
    records: records,
    topExerciseId: top,
  );
}

/// Pondělí týdne s prvním dokončeným tréninkem (`null` bez historie).
DateTime? firstTrainingWeek(Iterable<Workout> workouts) {
  DateTime? first;
  for (final w in workouts) {
    if (!w.finished) continue;
    final m = weekStart(w.date);
    if (first == null || m.isBefore(first)) first = m;
  }
  return first;
}
