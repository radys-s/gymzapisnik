import 'models.dart';

/// Odhad maxima na jedno opakování (Epley). Slouží k porovnání sérií
/// s různým počtem opakování (80 × 8 vs 85 × 6).
double e1rm(double weight, int reps) {
  if (reps <= 0 || weight <= 0) return 0;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}

/// Porovná dvě série: kladné číslo = `a` je lepší.
///
/// S váhou rozhoduje odhad 1RM, při shodě vyšší váha.
/// S vlastní váhou rozhoduje počet opakování, při shodě přidaná zátěž.
int compareSets(ExerciseType type, SetEntry a, SetEntry b) {
  int cmp(num x, num y) => x.compareTo(y);
  if (type == ExerciseType.weighted) {
    final byE1rm = cmp(e1rm(a.weight, a.reps), e1rm(b.weight, b.reps));
    return byE1rm != 0 ? byE1rm : cmp(a.weight, b.weight);
  }
  final byReps = cmp(a.reps, b.reps);
  return byReps != 0 ? byReps : cmp(a.weight, b.weight);
}

/// Nejlepší započítaná série, nebo `null`.
SetEntry? bestSet(ExerciseType type, Iterable<SetEntry> sets) {
  SetEntry? best;
  for (final s in sets.where((s) => s.counts)) {
    if (best == null || compareSets(type, s, best) > 0) best = s;
  }
  return best;
}

/// Objem: s váhou kg × opakování, s vlastní váhou počet opakování.
double volume(ExerciseType type, Iterable<SetEntry> sets) {
  var total = 0.0;
  for (final s in sets.where((s) => s.counts)) {
    total += type == ExerciseType.weighted ? s.weight * s.reps : s.reps;
  }
  return total;
}

enum Trend { better, same, worse, added, missing }

Trend _trend(int cmp) => cmp > 0
    ? Trend.better
    : cmp < 0
    ? Trend.worse
    : Trend.same;

class SetComparison {
  final SetEntry? today;
  final SetEntry? last;
  final Trend trend;
  const SetComparison(this.today, this.last, this.trend);
}

/// Dnešní cvik proti minulému provedení.
class ExerciseComparison {
  final List<SetComparison> sets;
  final SetEntry? bestToday;
  final SetEntry? bestLast;
  final double volumeToday;
  final double volumeLast;

  /// Celkový verdikt: podle nejlepší série, při shodě podle objemu.
  final Trend overall;

  const ExerciseComparison({
    required this.sets,
    required this.bestToday,
    required this.bestLast,
    required this.volumeToday,
    required this.volumeLast,
    required this.overall,
  });

  double get volumeDelta => volumeToday - volumeLast;
}

/// Série se párují podle pořadí započítaných sérií.
ExerciseComparison compareExercise(
  ExerciseType type,
  WorkoutExercise today,
  WorkoutExercise? last,
) {
  final now = today.countedSets;
  final before = last?.countedSets ?? const <SetEntry>[];
  final pairs = <SetComparison>[];
  final length = now.length > before.length ? now.length : before.length;
  for (var i = 0; i < length; i++) {
    final a = i < now.length ? now[i] : null;
    final b = i < before.length ? before[i] : null;
    pairs.add(
      SetComparison(
        a,
        b,
        a == null
            ? Trend.missing
            : b == null
            ? Trend.added
            : _trend(compareSets(type, a, b)),
      ),
    );
  }
  final bestToday = bestSet(type, now);
  final bestLast = bestSet(type, before);
  final volumeToday = volume(type, now);
  final volumeLast = volume(type, before);
  final Trend overall;
  if (bestToday == null) {
    overall = Trend.missing;
  } else if (bestLast == null) {
    overall = Trend.added;
  } else {
    final byBest = compareSets(type, bestToday, bestLast);
    overall = _trend(byBest != 0 ? byBest : volumeToday.compareTo(volumeLast));
  }
  return ExerciseComparison(
    sets: pairs,
    bestToday: bestToday,
    bestLast: bestLast,
    volumeToday: volumeToday,
    volumeLast: volumeLast,
    overall: overall,
  );
}

enum RecordKind {
  /// Nejvyšší váha (u vlastní váhy nejvyšší přidaná zátěž).
  maxWeight,

  /// Nejlepší odhad 1RM (jen cviky s váhou).
  bestE1rm,

  /// Nejvíc opakování v sérii (jen vlastní váha).
  maxReps;

  String get label => switch (this) {
    maxWeight => 'Max váha',
    bestE1rm => 'Odhad 1RM',
    maxReps => 'Max opakování',
  };
}

class PersonalRecord {
  final String exerciseId;
  final RecordKind kind;
  final double value;
  final SetEntry set;
  final String workoutId;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseId,
    required this.kind,
    required this.value,
    required this.set,
    required this.workoutId,
    required this.date,
  });
}

List<RecordKind> recordKinds(ExerciseType type) => type == ExerciseType.weighted
    ? const [RecordKind.maxWeight, RecordKind.bestE1rm]
    : const [RecordKind.maxReps, RecordKind.maxWeight];

double recordValue(RecordKind kind, SetEntry set) => switch (kind) {
  RecordKind.maxWeight => set.weight,
  RecordKind.bestE1rm => e1rm(set.weight, set.reps),
  RecordKind.maxReps => set.reps.toDouble(),
};
