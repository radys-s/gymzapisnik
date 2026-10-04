import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

void main() {
  late AppDatabase db;
  late AppState state;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    state = AppState(LocalStore(db));
    await state.load();
  });

  tearDown(() => db.close());

  Future<AppState> reload() async {
    final again = AppState(LocalStore(db));
    await again.load();
    return again;
  }

  Future<Workout> logBench(List<(double, int)> sets, DateTime at) async {
    await state.startWorkout(now: at);
    final entry = await state.addExercise('bench_press');
    entry.sets = [
      for (final (w, r) in sets) SetEntry(weight: w, reps: r, done: true),
    ];
    final result = await state.finishActive(
      now: at.add(const Duration(hours: 1)),
    );
    return result.workout!;
  }

  test('start returns the running workout instead of a second one', () async {
    final a = await state.startWorkout(now: DateTime(2026, 10, 5, 18));
    final b = await state.startWorkout();
    expect(identical(a, b), isTrue);
    expect(a.name, 'Trénink – pondělí');
    expect((await reload()).active?.id, a.id);
  });

  test('new exercise is prefilled from last performance, not done', () async {
    await logBench([(80, 8), (80, 7)], DateTime(2026, 10, 1));
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    expect(
      [for (final s in entry.sets) (s.weight, s.reps, s.done)],
      [(80.0, 8, false), (80.0, 7, false)],
    );
    final third = await state.addSet(entry);
    expect((third.weight, third.reps, third.done), (80.0, 7, false));
  });

  test('first time exercise gets one empty set', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    expect(entry.sets.single.reps, 0);
  });

  test('done needs reps', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    expect(await state.toggleDone(entry.sets.single), isNotNull);
    entry.sets.single.reps = 5;
    expect(await state.toggleDone(entry.sets.single), isNull);
    expect(entry.sets.single.done, isTrue);
  });

  test('finish keeps only confirmed sets and survives reload', () async {
    final start = DateTime(2026, 10, 2, 17);
    await state.startWorkout(now: start);
    final bench = await state.addExercise('bench_press');
    bench.sets = [
      SetEntry(weight: 60, reps: 10, done: true, warmup: true),
      SetEntry(weight: 80, reps: 8, done: true),
      SetEntry(weight: 80, reps: 8),
    ];
    final empty = await state.addExercise('incline_press');
    expect(empty.sets.single.done, isFalse);
    final result = await state.finishActive(
      now: start.add(const Duration(hours: 1)),
    );
    expect(result.error, isNull);
    final saved = result.workout!;
    expect(saved.exercises.single.sets.length, 2);
    expect(state.active, isNull);

    final again = await reload();
    expect(again.active, isNull);
    expect(again.workouts.single.id, saved.id);
    expect(again.workouts.single.exercises.single.sets.length, 2);
  });

  test('finish without a working set is refused and keeps workout', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    entry.sets = [SetEntry(weight: 40, reps: 10, done: true, warmup: true)];
    final result = await state.finishActive();
    expect(result.error, isNotNull);
    expect(state.active, isNotNull);
  });

  test('late save after finish does not resurrect the workout', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    entry.sets = [SetEntry(weight: 80, reps: 5, done: true)];
    final finishing = state.finishActive();
    final late = state.saveActive();
    await Future.wait([finishing, late]);
    final again = await reload();
    expect(again.active, isNull);
    expect(again.workouts, hasLength(1));
  });

  test('discard removes the active workout', () async {
    await state.startWorkout();
    await state.addExercise('bench_press');
    await state.discardActive();
    expect(state.active, isNull);
    expect((await reload()).active, isNull);
  });

  test('repeat copies exercises with last values', () async {
    final past = await logBench([(85, 5)], DateTime(2026, 10, 1));
    final w = await state.repeatWorkout(past);
    expect(w.name, past.name);
    expect(w.exercises.single.sets.single.weight, 85);
    expect(w.exercises.single.sets.single.done, isFalse);
  });

  test('warm-up toggles and replace swaps sets', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    await state.toggleWarmup(entry.sets.single);
    expect(entry.sets.single.warmup, isTrue);
    await state.replaceExercise(entry, 'incline_press');
    expect(entry.exerciseId, 'incline_press');
    expect(entry.sets.single.warmup, isFalse);
    await state.removeExercise(entry);
    expect((await reload()).active!.exercises, isEmpty);
  });

  test('confirming a set starts rest that survives reload', () async {
    final now = DateTime(2026, 10, 5, 18);
    await state.startWorkout(now: now);
    final entry = await state.addExercise('bench_press');
    entry.sets.single.reps = 5;
    await state.toggleDone(entry.sets.single, now: now);
    expect(state.restEndsAt, now.add(const Duration(seconds: 120)));
    expect((await reload()).restEndsAt, state.restEndsAt);

    await state.adjustRest(const Duration(seconds: 15), now: now);
    expect(state.restEndsAt, now.add(const Duration(seconds: 135)));
    await state.adjustRest(const Duration(seconds: -200), now: now);
    expect(state.restEndsAt, isNull);
  });

  test('unconfirming does not start rest; skip clears it', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    final set = entry.sets.single..reps = 5;
    await state.toggleDone(set);
    await state.skipRest();
    expect(state.restEndsAt, isNull);
    await state.toggleDone(set);
    expect(set.done, isFalse);
    expect(state.restEndsAt, isNull);
  });

  test('finished workout does not keep rest timestamp', () async {
    await state.startWorkout();
    final entry = await state.addExercise('bench_press');
    entry.sets.single.reps = 5;
    await state.toggleDone(entry.sets.single);
    final saved = (await state.finishActive()).workout!;
    expect(saved.toJson().containsKey('restEndsAt'), isFalse);
  });

  test('edit finished workout keeps filled sets and survives reload', () async {
    final w = await logBench([(80, 8), (80, 6)], DateTime(2026, 10, 1));
    final draft = w.copy()..name = '  Push  ';
    draft.exercises.single.sets
      ..[1].reps = 0
      ..add(SetEntry(weight: 70, reps: 10));
    expect(await state.updateWorkout(draft), isNull);
    final again = await reload();
    final saved = again.workouts.single;
    expect(saved.name, 'Push');
    expect(
      [for (final s in saved.exercises.single.sets) (s.weight, s.reps, s.done)],
      [(80.0, 8, true), (70.0, 10, true)],
    );
  });

  test('edit without working set is refused', () async {
    final w = await logBench([(80, 8)], DateTime(2026, 10, 1));
    final draft = w.copy();
    draft.exercises.single.sets.single.warmup = true;
    expect(await state.updateWorkout(draft), isNotNull);
    expect(state.workouts.single.exercises.single.sets.single.warmup, isFalse);
  });

  test('delete removes workout from history', () async {
    final w = await logBench([(80, 8)], DateTime(2026, 10, 1));
    await state.deleteWorkout(w);
    expect(state.workouts, isEmpty);
    expect((await reload()).workouts, isEmpty);
  });
}
