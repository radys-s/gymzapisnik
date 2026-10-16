/// Přehledy pro stránku Statistiky. Čistý Dart.
library;

import '../domain/models.dart';
import '../domain/stats.dart';
import 'weeks.dart';

/// Součty za období.
class Totals {
  final int workouts;
  final int sets;
  final double volumeKg;
  final Duration time;
  const Totals(this.workouts, this.sets, this.volumeKg, this.time);
}

/// Delší „trénink“ se do času nepočítá (zapomenuté dokončení).
const _maxCounted = Duration(hours: 5);

/// Součty dokončených tréninků v [from, to) (bez mezí = vše).
Totals totalsOf(
  Iterable<Workout> workouts,
  ExerciseType Function(String exerciseId) typeOf, {
  DateTime? from,
  DateTime? to,
}) {
  var count = 0;
  var sets = 0;
  var kg = 0.0;
  var time = Duration.zero;
  for (final w in workouts) {
    final end = w.finishedAt;
    if (end == null) continue;
    if (from != null && w.date.isBefore(from)) continue;
    if (to != null && !w.date.isBefore(to)) continue;
    count++;
    final length = end.difference(w.startedAt);
    if (!length.isNegative && length <= _maxCounted) time += length;
    for (final e in w.exercises) {
      sets += e.countedSets.length;
      if (typeOf(e.exerciseId) == ExerciseType.weighted) {
        kg += volume(ExerciseType.weighted, e.sets);
      }
    }
  }
  return Totals(count, sets, kg, time);
}

/// Jeden týden grafu.
class WeekBucket {
  final DateTime monday;
  final Totals totals;
  const WeekBucket(this.monday, this.totals);
}

/// Posledních [weeks] týdnů od nejstaršího; poslední je rozběhnutý týden.
List<WeekBucket> weeklyBuckets(
  Iterable<Workout> workouts,
  DateTime now,
  ExerciseType Function(String exerciseId) typeOf, {
  int weeks = 12,
}) {
  final current = weekStart(now);
  final first = DateTime(
    current.year,
    current.month,
    current.day - 7 * (weeks - 1),
  );
  // Jeden průchod: tréninky podle pondělí jejich týdne.
  final byWeek = <DateTime, List<Workout>>{};
  for (final w in workouts) {
    if (!w.finished) continue;
    final m = weekStart(w.date);
    if (m.isBefore(first) || m.isAfter(current)) continue;
    byWeek.putIfAbsent(m, () => []).add(w);
  }
  return [
    for (var m = first; !m.isAfter(current); m = nextWeek(m))
      WeekBucket(m, totalsOf(byWeek[m] ?? const [], typeOf)),
  ];
}

/// Počet dokončených tréninků podle dne (půlnoc místního času).
Map<DateTime, int> dailyCounts(Iterable<Workout> workouts) {
  final result = <DateTime, int>{};
  for (final w in workouts) {
    if (!w.finished) continue;
    result.update(dayStart(w.date), (n) => n + 1, ifAbsent: () => 1);
  }
  return result;
}

/// Stejný okamžik o měsíc dřív (31. 3. → 28./29. 2.), pro srovnání
/// rozběhnutého měsíce se stejně dlouhým úsekem minulého.
DateTime sameTimeLastMonth(DateTime d) {
  final l = d.toLocal();
  final lastDay = DateTime(l.year, l.month, 0).day;
  return DateTime(
    l.year,
    l.month - 1,
    l.day > lastDay ? lastDay : l.day,
    l.hour,
    l.minute,
  );
}

/// Začátek měsíce posunutý o [delta] měsíců.
DateTime monthStart(DateTime d, [int delta = 0]) {
  final l = d.toLocal();
  return DateTime(l.year, l.month + delta);
}
