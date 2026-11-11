import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';

Future<AppState> _state() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  return state;
}

void main() {
  test('logging a set fires only the active slice', () async {
    final state = await _state();
    final fired = <String, int>{};
    void count(String name, StateSlice s) =>
        s.addListener(() => fired[name] = (fired[name] ?? 0) + 1);
    count('active', state.on.active);
    count('history', state.on.history);
    count('food', state.on.food);
    count('consent', state.on.consent);

    final entry = await state.addExercise('bench_press');
    final set = entry.sets.first
      ..weight = 60
      ..reps = 8;
    await state.saveActive();
    await state.toggleDone(set);

    expect(fired['active'], greaterThanOrEqualTo(3));
    expect(fired['history'], isNull);
    expect(fired['food'], isNull);
    expect(fired['consent'], isNull);

    final done = await state.finishActive();
    expect(done.error, isNull);
    expect(fired['history'], 1);
    expect(fired['food'], isNull);
  });

  test(
    'a slice detaches from the state when its last listener leaves',
    () async {
      final state = await _state();
      var calls = 0;
      void listener() => calls++;
      state.on.food.addListener(listener);
      state.on.food.removeListener(listener);
      await state.addExercise('bench_press');
      expect(calls, 0);
    },
  );

  test('history summaries are cached until workouts change', () async {
    final state = await _state();
    final now = DateTime(2026, 11, 11, 18);
    final first = state.recentRecordList();
    expect(identical(first, state.recentRecordList()), isTrue);
    final week = state.weekSummaryAt(now);
    expect(identical(week, state.weekSummaryAt(now)), isTrue);

    final entry = await state.addExercise('bench_press');
    entry.sets.first
      ..weight = 60
      ..reps = 8
      ..done = true;
    await state.finishActive(now: now);

    expect(identical(first, state.recentRecordList()), isFalse);
    expect(identical(week, state.weekSummaryAt(now)), isFalse);
    expect(state.weekSummaryAt(now), isNot(same(week)));
  });
}
