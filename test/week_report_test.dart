import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';
import 'package:gymzapisnik/domain/week_report.dart';

Workout workout(
  String id,
  DateTime end,
  Map<String, List<(double, int)>> exercises, {
  Duration length = const Duration(hours: 1),
  bool finished = true,
}) => Workout(
  id: id,
  name: id,
  startedAt: end.subtract(length),
  finishedAt: finished ? end : null,
  exercises: [
    for (final e in exercises.entries)
      WorkoutExercise(
        id: '$id-${e.key}',
        exerciseId: e.key,
        sets: [
          for (final (w, r) in e.value)
            SetEntry(weight: w, reps: r, done: true),
        ],
      ),
  ],
);

ExerciseType typeOf(String id) =>
    id == 'pull_up' ? ExerciseType.bodyweight : ExerciseType.weighted;

void main() {
  // Po 7. 9. 2026 je pondělí.
  final lastWeek = DateTime(2026, 9, 2, 18);
  final mon = DateTime(2026, 9, 7, 18);
  final wed = DateTime(2026, 9, 9, 18);
  final nextMon = DateTime(2026, 9, 14, 8);
  final all = [
    workout('old', lastWeek, {
      'bench_press': [(80, 5)],
    }),
    workout('a', mon, {
      'bench_press': [(80, 5), (80, 5)],
      'pull_up': [(0, 10)],
    }, length: const Duration(minutes: 50)),
    workout('b', wed, {
      'bench_press': [(85, 5)],
      'squat': [(100, 5), (100, 5), (100, 5)],
    }, length: const Duration(hours: 9)),
    workout('open', wed, {
      'squat': [(200, 5)],
    }, finished: false),
    workout('next', nextMon, {
      'squat': [(120, 5)],
    }),
  ];

  test('sums only finished workouts of the week', () {
    final r = weekReport(all, DateTime(2026, 9, 10), typeOf);
    expect(r.monday, DateTime(2026, 9, 7));
    expect(r.workouts, 2);
    expect(r.sets, 7);
    expect(r.reps, 5 + 5 + 10 + 5 + 15);
    expect(r.volumeKg, 800 + 425 + 1500);
  });

  test('caps a forgotten workout at four hours', () {
    final r = weekReport(all, mon, typeOf);
    expect(r.time, const Duration(minutes: 50) + const Duration(hours: 4));
  });

  test('splits volume and sets by weekday', () {
    final r = weekReport(all, mon, typeOf);
    expect(r.dailyVolume[0], 800);
    expect(r.dailyVolume[2], 1925);
    expect(r.dailySets[0], 3);
    expect(r.dailySets[2], 4);
    expect(r.dailySets.skip(3).every((n) => n == 0), isTrue);
  });

  test('lists records against all earlier history, newest first', () {
    final r = weekReport(all, mon, typeOf);
    expect(r.records.map((x) => x.workoutId).toSet(), {'b'});
    expect(r.records.map((x) => x.exerciseId).toSet(), {'bench_press'});
    expect(r.records.map((x) => x.kind), contains(RecordKind.maxWeight));
  });

  test('a record broken twice in a week shows once, with the best value', () {
    final r = weekReport(
      [
        workout('base', lastWeek, {
          'bench_press': [(80, 5)],
        }),
        workout('tue', DateTime(2026, 9, 8, 18), {
          'bench_press': [(82.5, 5)],
        }),
        workout('fri', DateTime(2026, 9, 11, 18), {
          'bench_press': [(85, 5)],
        }),
      ],
      mon,
      typeOf,
    );
    final weight = r.records.where((x) => x.kind == RecordKind.maxWeight);
    expect(weight.length, 1);
    expect(weight.single.value, 85);
    expect(weight.single.workoutId, 'fri');
  });

  test('top exercise is the biggest volume', () {
    expect(weekReport(all, mon, typeOf).topExerciseId, 'squat');
  });

  test('bodyweight-only week picks the exercise with most sets', () {
    final r = weekReport(
      [
        workout('p', mon, {
          'pull_up': [(0, 8), (0, 8)],
        }),
      ],
      mon,
      typeOf,
    );
    expect(r.topExerciseId, 'pull_up');
    expect(r.volumeKg, 0);
  });

  test('empty week', () {
    final r = weekReport(all, DateTime(2026, 8, 20), typeOf);
    expect(r.isEmpty, isTrue);
    expect(r.topExerciseId, isNull);
    expect(r.records, isEmpty);
  });

  test('first training week is the monday of the oldest finished workout', () {
    expect(firstTrainingWeek(all), DateTime(2026, 8, 31));
    expect(firstTrainingWeek(const []), isNull);
  });
}
