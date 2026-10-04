import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/domain/models.dart';

const plan = PlannedExercise('bench_press', sets: 3, repMin: 8, repMax: 12);

ExerciseSession session(int day, List<(double, int)> sets, {String? kind}) {
  final w = Workout(
    id: 'w$day',
    name: 'w',
    startedAt: DateTime(2026, 9, day),
    finishedAt: DateTime(2026, 9, day, 1),
  );
  final e = WorkoutExercise(
    id: 'e$day',
    exerciseId: 'bench_press',
    sets: [
      for (final (kg, r) in sets) SetEntry(weight: kg, reps: r, done: true),
    ],
    extra: kind == null
        ? null
        : {
            coachKey: {'kind': kind},
          },
  );
  w.exercises.add(e);
  return ExerciseSession(w, e);
}

void main() {
  test('first time asks user to pick weight', () {
    final s = suggest(plan, ExerciseType.weighted, []);
    expect(s.kind, SuggestionKind.start);
    expect((s.weight, s.reps, s.sets), (0.0, 8, 3));
  });

  test('all sets at top of range adds weight', () {
    final s = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 12), (60, 12), (60, 12)]),
    ]);
    expect(s.kind, SuggestionKind.increase);
    expect((s.weight, s.reps), (62.5, 8));
    expect(s.reason, contains('přidej 2,5 kg'));
  });

  test('missing reps holds weight and adds one rep', () {
    final s = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 12), (60, 10), (60, 9)]),
    ]);
    expect(s.kind, SuggestionKind.hold);
    expect((s.weight, s.reps), (60.0, 10));
  });

  test('fewer sets than planned is not an increase', () {
    final s = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 12), (60, 12)]),
    ]);
    expect(s.kind, SuggestionKind.hold);
    expect(s.reps, 12);
  });

  test('two sessions without progress trigger deload, but not twice', () {
    final stall = [
      session(1, [(80, 8), (80, 8), (80, 7)]),
      session(3, [(80, 8), (80, 7), (80, 7)]),
      session(5, [(80, 7), (80, 7), (80, 6)]),
    ];
    final s = suggest(plan, ExerciseType.weighted, stall);
    expect(s.kind, SuggestionKind.deload);
    expect(s.weight, 72.5);

    final afterDeload = [
      ...stall.sublist(1),
      session(7, [(72.5, 12), (72.5, 11), (72.5, 10)], kind: 'deload'),
    ];
    expect(
      suggest(plan, ExerciseType.weighted, afterDeload).kind,
      isNot(SuggestionKind.deload),
    );
  });

  test('progress in between prevents deload', () {
    final s = suggest(plan, ExerciseType.weighted, [
      session(1, [(80, 8)]),
      session(3, [(82.5, 8)]),
      session(5, [(82.5, 7)]),
    ]);
    expect(s.kind, isNot(SuggestionKind.deload));
  });

  test('bodyweight adds reps', () {
    const pull = PlannedExercise('pull_up', sets: 3, repMin: 6, repMax: 10);
    final s = suggest(pull, ExerciseType.bodyweight, [
      session(1, [(0, 8), (0, 7), (0, 6)]),
    ]);
    expect((s.weight, s.reps), (0.0, 7));
  });

  test('rounding to plate step', () {
    expect(roundTo(81.3, 2.5), 82.5);
    expect(roundTo(72, 2.5), 72.5);
  });

  test('templates reference only catalog exercises', () {
    final ids = {for (final e in builtInExercises) e.id};
    for (final t in splitTemplates) {
      expect(t.days, isNotEmpty);
      for (final d in t.days) {
        for (final e in d.exercises) {
          expect(ids, contains(e.exerciseId), reason: '${t.id}/${d.name}');
          expect(e.repMin <= e.repMax, isTrue);
        }
      }
    }
  });

  test('next day rotates after the last trained day of the split', () {
    final ppl = findSplit('ppl')!;
    Workout w(int day, String split, int index) => Workout(
      id: 'x$day',
      name: 'x',
      startedAt: DateTime(2026, 9, day),
      finishedAt: DateTime(2026, 9, day, 1),
      extra: {'split': split, 'splitDay': index},
    );
    expect(nextDayIndex(ppl, []), 0);
    expect(nextDayIndex(ppl, [w(1, 'ppl', 0), w(3, 'ppl', 1)]), 2);
    expect(nextDayIndex(ppl, [w(1, 'ppl', 2)]), 0);
    expect(nextDayIndex(ppl, [w(1, 'ppl', 0), w(3, 'upper_lower', 1)]), 1);
  });
}
