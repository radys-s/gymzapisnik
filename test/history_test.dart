import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';

Workout workout(
  String id,
  DateTime date,
  Map<String, List<(double, int)>> exercises, {
  bool finished = true,
}) => Workout(
  id: id,
  name: id,
  startedAt: date.subtract(const Duration(hours: 1)),
  finishedAt: finished ? date : null,
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
  final d1 = DateTime.utc(2026, 9, 1, 18);
  final d2 = DateTime.utc(2026, 9, 4, 18);
  final d3 = DateTime.utc(2026, 9, 8, 18);
  final all = [
    workout('a', d1, {
      'bench_press': [(77.5, 8), (82.5, 6)],
    }),
    workout('b', d2, {
      'bench_press': [(80, 8), (85, 6)],
      'pull_up': [(0, 8)],
    }),
    workout('c', d3, {
      'bench_press': [(85, 6)],
    }, finished: false),
  ];

  test('history is oldest first and ignores unfinished workouts', () {
    final h = exerciseHistory(all, 'bench_press');
    expect(h.map((s) => s.workout.id), ['a', 'b']);
  });

  test('last performance skips the current workout and later ones', () {
    expect(lastPerformance(all, 'bench_press')!.workout.id, 'b');
    expect(
      lastPerformance(all, 'bench_press', excludeWorkoutId: 'b')!.workout.id,
      'a',
    );
    expect(lastPerformance(all, 'bench_press', before: d2)!.workout.id, 'a');
    expect(lastPerformance(all, 'squat'), isNull);
  });

  test('all-time records per kind', () {
    final r = allTimeRecords(all, 'bench_press', ExerciseType.weighted);
    expect(r[RecordKind.maxWeight]!.value, 85);
    expect(r[RecordKind.bestE1rm]!.workoutId, 'b');
  });

  test('new records compare only against earlier workouts', () {
    final records = newRecords(all[1], all, typeOf);
    expect(records.map((r) => r.kind).toSet(), {
      RecordKind.maxWeight,
      RecordKind.bestE1rm,
    });
    // pull_up was done for the first time: no record yet.
    expect(records.any((r) => r.exerciseId == 'pull_up'), isFalse);
    expect(newRecords(all[0], all, typeOf), isEmpty);
  });

  test('bodyweight record on more reps', () {
    final later = workout('d', DateTime.utc(2026, 9, 10), {
      'pull_up': [(0, 10)],
    });
    final records = newRecords(later, [...all, later], typeOf);
    expect(records.single.kind, RecordKind.maxReps);
    expect(records.single.value, 10);
  });

  test('week summary starts on Monday', () {
    // 2026-09-08 is a Tuesday; week starts 2026-09-07.
    final week = weekSummary(
      [
        ...all,
        workout('e', DateTime(2026, 9, 7, 10), {
          'bench_press': [(100, 5)],
        }),
        workout('f', DateTime(2026, 9, 6, 10), {
          'bench_press': [(100, 5)],
        }),
      ],
      DateTime(2026, 9, 8, 12),
      typeOf,
    );
    expect(week.workouts, 1);
    expect(week.sets, 1);
    expect(week.volumeKg, 500);
  });

  test('json round trip keeps unknown keys', () {
    final w = all[1];
    final json = w.toJson()
      ..['future'] = 1
      ..['exercises'][0]['sets'][0]['rpe'] = 8;
    final back = Workout.fromJson(json);
    expect(back.toJson()['future'], 1);
    expect(back.exercises[0].sets[0].extra['rpe'], 8);
    expect(back.finishedAt, w.finishedAt);
  });

  test('progress series: best value per workout, oldest first', () {
    final ws = [
      workout('b', DateTime(2026, 10, 3), {
        'bench': [(80, 8), (85, 5)],
        'pull_up': [(0, 10)],
      }),
      workout('a', DateTime(2026, 10, 1), {
        'bench': [(80, 6)],
      }),
      workout('x', DateTime(2026, 10, 4), {
        'bench': [(100, 1)],
      }, finished: false),
    ];
    final bench = progressSeries(ws, 'bench', ExerciseType.weighted);
    expect([for (final p in bench) p.date.day], [1, 3]);
    expect(bench.last.value, closeTo(e1rm(80, 8), 1e-9));
    final pull = progressSeries(ws, 'pull_up', ExerciseType.bodyweight);
    expect(pull.single.value, 10);
  });

  test('recent records: newest first, one per exercise, limited', () {
    final ws = [
      workout('a', DateTime(2026, 9, 1), {
        'bench': [(80, 8)],
        'squat': [(100, 5)],
      }),
      workout('b', DateTime(2026, 9, 3), {
        'bench': [(85, 8)],
        'squat': [(105, 5)],
      }),
      workout('c', DateTime(2026, 9, 5), {
        'bench': [(90, 8)],
      }),
    ];
    final r = recentRecords(ws, typeOf);
    expect([for (final p in r) '${p.workoutId}/${p.exerciseId}'], [
      'c/bench',
      'b/squat',
    ]);
    expect(recentRecords(ws, typeOf, limit: 1), hasLength(1));
    expect(recentRecords([ws.first], typeOf), isEmpty);
  });

  test('most trained exercise counts workouts, not sets', () {
    final ws = [
      workout('a', DateTime(2026, 9, 1), {
        'squat': [(100, 5), (100, 5), (100, 5), (100, 5)],
        'bench': [(80, 8)],
      }),
      workout('b', DateTime(2026, 9, 3), {
        'bench': [(80, 8)],
      }),
      workout('c', DateTime(2026, 9, 5), {
        'squat': [(100, 5)],
        'bench': [(80, 8)],
      }, finished: false),
    ];
    expect(mostTrainedExercise(ws), 'bench');
    expect(mostTrainedExercise(const []), isNull);
  });
}
