import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';

void main() {
  group('recommendPlan', () {
    String id(int days, [PlanLevel l = PlanLevel.beginner, PlanGoal? g]) =>
        recommendPlan(
          PlanAnswers(days: days, level: l, goal: g ?? PlanGoal.muscle),
        ).splitId;

    test('program follows days, level and goal', () {
      expect(id(2), 'full_body_3');
      expect(id(3), 'full_body_3');
      expect(id(3, PlanLevel.advanced), 'ppl');
      expect(id(3, PlanLevel.advanced, PlanGoal.strength), 'full_body_3');
      expect(id(4), 'upper_lower');
      expect(id(5), 'upper_lower');
      expect(id(5, PlanLevel.advanced), 'ppl');
      expect(id(6), 'ppl');
      expect(id(6, PlanLevel.advanced), 'arnold');
      for (var d = 2; d <= 6; d++) {
        expect(findSplit(id(d)), isNotNull);
      }
    });

    test('rest and week goal follow the answers', () {
      final r = recommendPlan(
        const PlanAnswers(days: 4, goal: PlanGoal.strength),
      );
      expect(r.perWeek, 4);
      expect(r.restSeconds, 180);
      expect(r.why, isNotEmpty);
    });
  });

  test('recommended count by time, beginners one less', () {
    expect(recommendedCount(30, PlanLevel.advanced), 4);
    expect(recommendedCount(45, PlanLevel.advanced), 5);
    expect(recommendedCount(60, PlanLevel.advanced), 6);
    expect(recommendedCount(90, PlanLevel.advanced), 8);
    expect(recommendedCount(30, PlanLevel.beginner), 3);
    expect(recommendedCount(90, PlanLevel.beginner), 7);
  });

  test('answers parse safely', () {
    const a = PlanAnswers(
      goal: PlanGoal.fitness,
      days: 5,
      level: PlanLevel.advanced,
      minutes: 45,
    );
    final back = PlanAnswers.tryParse(a.toJson())!;
    expect(back.goal, PlanGoal.fitness);
    expect(back.days, 5);
    expect(back.level, PlanLevel.advanced);
    expect(back.minutes, 45);
    expect(PlanAnswers.tryParse('x'), isNull);
    expect(PlanAnswers.tryParse({'days': 'tři', 'minutes': 60}), isNull);
    final odd = PlanAnswers.tryParse({'days': 9, 'minutes': 50})!;
    expect(odd.days, 6);
    expect(odd.minutes, 60);
  });

  test('fitDay trims and extends without duplicates', () {
    final day = findSplit('upper_lower')!.days.first;
    final short = fitDay(day, 3);
    expect(short.exercises, hasLength(3));
    expect(short.exercises.first.exerciseId, day.exercises.first.exerciseId);

    final long = fitDay(day, day.exercises.length + 2);
    final ids = long.exercises.map((e) => e.exerciseId).toList();
    expect(ids, hasLength(day.exercises.length + 2));
    expect(ids.toSet(), hasLength(ids.length));
    expect(
      ids.take(day.exercises.length),
      day.exercises.map((e) => e.exerciseId),
    );
  });

  test('applyPlan sets program, goal, rest and fitted days', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    expect(state.planAnswers, isNull);

    final r = await state.applyPlan(
      const PlanAnswers(days: 4, minutes: 30, goal: PlanGoal.strength),
    );
    expect(r.splitId, 'upper_lower');
    expect(state.split?.id, 'upper_lower');
    expect(state.weekGoal, 4);
    expect(state.profile.restSeconds, 180);
    expect(state.planAnswers?.minutes, 30);
    for (final d in state.split!.days) {
      expect(d.exercises, hasLength(r.exercises));
    }
    // Detail programu ukazuje stejné dny jako trénink.
    expect(
      state.fitted(findSplit('upper_lower')!).days.first.exercises,
      hasLength(r.exercises),
    );
  });

  test(
    'plan keeps matching weekdays, recommendation alone saves no answers',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final state = AppState(LocalStore(db));
      await state.load();
      await state.setFrequency(days: [1, 3, 5]);
      await state.applyPlan(null);
      expect(state.planAnswers, isNull);
      expect(state.split?.id, 'full_body_3');
      expect(state.profile.trainingDays, [1, 3, 5]);
      await state.applyPlan(const PlanAnswers(days: 4));
      expect(state.profile.trainingDays, isNull);
      expect(state.weekGoal, 4);
    },
  );

  test('backup keeps the plan and rejects a broken one', () {
    String backup(String plan) =>
        '{"format":"$backupFormat","version":1,'
        '"settings":{"plan":$plan},"workouts":[]}';
    final b = decodeBackup(backup('{"days":4,"minutes":45,"goal":"fitness"}'));
    expect(PlanAnswers.tryParse(b.settings['plan'])?.days, 4);
    expect(() => decodeBackup(backup('"x"')), throwsFormatException);
  });
}
