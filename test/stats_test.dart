import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';

SetEntry s(double w, int r, {bool warmup = false, bool done = true}) =>
    SetEntry(weight: w, reps: r, warmup: warmup, done: done);

WorkoutExercise ex(List<SetEntry> sets) =>
    WorkoutExercise(id: 'x', exerciseId: 'bench_press', sets: sets);

void main() {
  const w = ExerciseType.weighted;
  const bw = ExerciseType.bodyweight;

  test('e1rm uses Epley and handles edge cases', () {
    expect(e1rm(100, 1), 100);
    expect(e1rm(80, 8), closeTo(101.33, 0.01));
    expect(e1rm(80, 0), 0);
    expect(e1rm(0, 10), 0);
  });

  test('weightForReps inverts Epley and rounds down to a loadable plate', () {
    expect(weightForReps(100, 1), 100);
    // 100 / (1 + 10/30) = 75 → přesně, nesmí spadnout na 72,5.
    expect(weightForReps(100, 10), 75);
    // 100 / 1,2 = 83,33 → 82,5.
    expect(weightForReps(100, 6), 82.5);
    // Odhad z 80 × 8 vrátí na 8 opakování zase 80.
    expect(weightForReps(e1rm(80, 8), 8), 80);
    expect(weightForReps(0, 5), 0);
    expect(weightForReps(100, 0), 0);
  });

  test('warm-up and unfinished sets do not count', () {
    final sets = [s(40, 10, warmup: true), s(80, 8), s(85, 6, done: false)];
    expect(volume(w, sets), 640);
    expect(bestSet(w, sets)!.weight, 80);
  });

  test('bodyweight volume counts reps and best set prefers reps', () {
    final sets = [s(0, 12), s(10, 8), s(0, 10)];
    expect(volume(bw, sets), 30);
    expect(bestSet(bw, sets)!.reps, 12);
  });

  test('85x6 beats 80x8 by estimated 1RM', () {
    expect(compareSets(w, s(85, 6), s(80, 8)), greaterThan(0));
  });

  test('comparison pairs sets and decides overall trend', () {
    final today = ex([s(80, 8), s(85, 6), s(85, 5)]);
    final last = ex([s(77.5, 8), s(82.5, 6), s(82.5, 5), s(80, 5)]);
    final c = compareExercise(w, today, last);
    expect(c.sets.map((p) => p.trend), [
      Trend.better,
      Trend.better,
      Trend.better,
      Trend.missing,
    ]);
    expect(c.overall, Trend.better);
    expect(c.volumeToday, 80 * 8 + 85 * 6 + 85 * 5);
  });

  test('equal best set falls back to volume', () {
    final c = compareExercise(
      w,
      ex([s(80, 8), s(80, 8)]),
      ex([s(80, 8), s(80, 7)]),
    );
    expect(c.overall, Trend.better);
  });

  test('pairExercises matches by exercise and keeps leftovers', () {
    WorkoutExercise e(String id, {bool done = true}) => WorkoutExercise(
      id: id,
      exerciseId: id.split('#').first,
      sets: [s(60, 8, done: done)],
    );
    Workout w(List<WorkoutExercise> list) => Workout(
      id: 'w',
      name: 'x',
      startedAt: DateTime(2026, 10, 1),
      exercises: list,
    );
    final a = w([e('bench'), e('squat'), e('bench#2'), e('row', done: false)]);
    final b = w([e('squat'), e('bench'), e('curl')]);
    final pairs = pairExercises(a, b);
    String id(WorkoutExercise? x) => x?.id ?? '-';
    expect(
      [for (final (x, y) in pairs) '${id(x)}/${id(y)}'],
      ['bench/bench', 'squat/squat', 'bench#2/-', '-/curl'],
    );
  });

  test('first performance is marked as added', () {
    final c = compareExercise(w, ex([s(80, 8)]), null);
    expect(c.overall, Trend.added);
    expect(c.sets.single.trend, Trend.added);
  });

  test('nothing done today is missing', () {
    final c = compareExercise(w, ex([s(80, 8, done: false)]), ex([s(80, 8)]));
    expect(c.overall, Trend.missing);
  });
}
