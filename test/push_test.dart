import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/push.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/domain/models.dart';

const plan = PlannedExercise('bench_press', sets: 3, repMin: 8, repMax: 12);

ExerciseSession session(
  int day,
  List<(double, int)> sets, {
  WorkoutRating? rating,
}) {
  final w = Workout(
    id: 'w$day',
    name: 'w',
    startedAt: DateTime(2026, 9, day),
    finishedAt: DateTime(2026, 9, day, 1),
  );
  if (rating != null) w.extra[ratingKey] = rating.name;
  final e = WorkoutExercise(
    id: 'e$day',
    exerciseId: 'bench_press',
    sets: [
      for (final (kg, r) in sets) SetEntry(weight: kg, reps: r, done: true),
    ],
  );
  w.exercises.add(e);
  return ExerciseSession(w, e);
}

void main() {
  test('rating changes how fast the weight goes up', () {
    final top = [(60.0, 12), (60.0, 12), (60.0, 12)];
    final limit = suggest(plan, ExerciseType.weighted, [
      session(1, top, rating: WorkoutRating.limit),
    ]);
    expect(limit.kind, SuggestionKind.hold);
    expect(limit.weight, 60);
    expect(limit.reason, contains('na hraně'));

    final easy = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 11), (60, 11), (60, 12)], rating: WorkoutRating.easy),
    ]);
    expect(easy.kind, SuggestionKind.increase);
    expect(easy.weight, 62.5);

    // Bez hodnocení o opakování méně = držet.
    final plain = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 11), (60, 11), (60, 12)]),
    ]);
    expect(plain.kind, SuggestionKind.hold);
  });

  test('low protein halves the weight step', () {
    final s = suggest(plan, ExerciseType.weighted, [
      session(1, [(60, 12), (60, 12), (60, 12)]),
    ], proteinLow: true);
    expect(s.weight, 61.25);
    expect(s.reason, contains('bílkovin'));
    expect(proteinLow((average: 100, target: 160, days: 5)), isTrue);
    expect(proteinLow((average: 140, target: 160, days: 5)), isFalse);
    expect(proteinLow(null), isFalse);
  });

  test('plateau after three sessions without a new max', () {
    final rising = [
      for (var i = 1; i <= 5; i++) session(i, [(60.0 + i * 2.5, 8)]),
    ];
    expect(plateauOf('bench_press', ExerciseType.weighted, rising), isNull);

    final stuck = [
      session(1, [(60, 8)]),
      session(3, [(70, 8)]),
      session(5, [(70, 7)]),
      session(8, [(70, 8)]),
      session(10, [(70, 6)]),
    ];
    final p = plateauOf('bench_press', ExerciseType.weighted, stuck)!;
    expect(p.sessions, 3);
    expect(p.topWeight, 70);
    final tips = plateauTips(
      p,
      protein: (average: 90, target: 160, days: 6),
      lastRating: WorkoutRating.limit,
    );
    // Málo bílkovin je první rada, lehčí týden se počítá z poslední váhy.
    expect(tips.first, contains('90 g'));
    expect(tips[1], contains('62,5 kg'));
    expect(plateauOf('bench_press', ExerciseType.bodyweight, stuck), isNull);

    // Dvojitá progrese: po přidání váhy klesne odhad 1RM, ale opakování
    // rostou. To je posun, ne zaseknutí.
    final climbing = [
      session(1, [(60, 12)]),
      session(3, [(62.5, 8)]),
      session(5, [(62.5, 9)]),
      session(8, [(62.5, 10)]),
    ];
    expect(plateauOf('bench_press', ExerciseType.weighted, climbing), isNull);

    // Odlehčený trénink se nepočítá a hned po něm se nic nehlásí.
    final deload = [
      ...stuck,
      session(12, [(62.5, 8)]),
    ];
    expect(plateauOf('bench_press', ExerciseType.weighted, deload), isNull);
  });

  test('week focus is valid only in its week and survives JSON', () {
    final monday = DateTime(2026, 11, 2);
    final f = WeekFocus(
      FocusKind.strength,
      week: monday,
      exerciseId: 'bench_press',
    );
    final back = WeekFocus.tryParse(f.toJson())!;
    expect(back.kind, FocusKind.strength);
    expect(back.exerciseId, 'bench_press');
    expect(back.activeAt(DateTime(2026, 11, 8, 23)), isTrue);
    expect(back.activeAt(DateTime(2026, 11, 9)), isFalse);
    expect(
      WeekFocus.tryParse({'kind': 'strength', 'week': '2026-11-2'}),
      isNull,
    );
    expect(WeekFocus.tryParse('x'), isNull);
  });

  test('focus progress for strength and consistency', () {
    final monday = DateTime(2026, 9, 7);
    final history = [
      session(1, [(80, 8)]),
      session(8, [(82.5, 8)]),
    ].map((s) => s.workout).toList();
    final strength = focusProgress(
      WeekFocus(FocusKind.strength, week: monday, exerciseId: 'bench_press'),
      workouts: history,
      now: DateTime(2026, 9, 9),
      typeOf: (_) => ExerciseType.weighted,
      nameOf: (_) => 'Bench',
      weekGoal: 3,
    );
    // Základ 80 × 8 ≈ 101,3 kg 1RM, cíl +2,5 % → 104 kg; teď 104,5.
    expect(strength.target, 104);
    expect(strength.done, isTrue);

    final consistency = focusProgress(
      WeekFocus(FocusKind.consistency, week: monday),
      workouts: history,
      now: DateTime(2026, 9, 12),
      typeOf: (_) => ExerciseType.weighted,
      nameOf: (_) => 'Bench',
      weekGoal: 4,
    );
    expect((consistency.value, consistency.target), (1.0, 4.0));
    expect(consistency.push, contains('3 tréninky'));
    expect(consistency.push, contains('2 dny'));
  });
}
