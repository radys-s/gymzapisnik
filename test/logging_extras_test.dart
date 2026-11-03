import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/routine.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/widgets/labels.dart';
import 'package:gymzapisnik/ui/widgets/set_kind.dart';

void main() {
  test('set kinds keep warm-up separate and survive JSON', () {
    final s = SetEntry(weight: 60, reps: 10, done: true)..kind = SetKind.drop;
    final back = SetEntry.fromJson(s.toJson());
    expect(back.kind, SetKind.drop);
    expect(back.counts, isTrue);
    expect(setBadge(back, 3), 'D');
    expect(setName(back, 'D'), 'Drop série');
    back.kind = SetKind.normal;
    expect(back.toJson().containsKey('kind'), isFalse);
    expect(setBadge(back, 3), '3');
    // Rozcvička nemá druh, i kdyby ho JSON nesl.
    final warm = SetEntry.fromJson({'reps': 5, 'warmup': true, 'kind': 'drop'});
    expect(warm.kind, SetKind.normal);
    expect(setBadge(warm, 1), 'R');
    expect(restLabel(90), '1 min 30 s');
    expect(restLabel(45), '45 s');
    expect(restLabel(180), '3 min');
  });

  test('routine from a workout keeps exercises, sets and rep range', () {
    final w = Workout(
      id: 'w',
      name: 'Push A',
      startedAt: DateTime(2026, 10, 1),
      finishedAt: DateTime(2026, 10, 1, 1),
    );
    w.exercises.addAll([
      WorkoutExercise(
        id: 'a',
        exerciseId: 'bench_press',
        sets: [
          SetEntry(weight: 40, reps: 10, warmup: true, done: true),
          SetEntry(weight: 80, reps: 8, done: true),
          SetEntry(weight: 80, reps: 6, done: true),
        ],
      ),
      WorkoutExercise(
        id: 'b',
        exerciseId: 'lateral_raise',
        sets: [
          for (var i = 0; i < 3; i++) SetEntry(weight: 8, reps: 12, done: true),
          // Drop série nemění předpis.
          SetEntry(weight: 4, reps: 20, done: true)..kind = SetKind.drop,
        ],
      ),
      WorkoutExercise(id: 'c', exerciseId: 'squat'),
    ]);
    final r = routineFromWorkout(w)!;
    expect(r.name, 'Push A');
    final day = r.days.single.exercises;
    expect(day.map((e) => e.exerciseId), ['bench_press', 'lateral_raise']);
    expect((day[0].sets, day[0].repMin, day[0].repMax), (2, 6, 8));
    expect((day[1].sets, day[1].repMin, day[1].repMax), (3, 12, 14));
    expect(
      routineFromWorkout(Workout(id: 'x', name: '', startedAt: DateTime(2026))),
      isNull,
    );
  });

  test('rest is per exercise and saved routine lands in programs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    expect(state.restFor('squat'), state.profile.restSeconds);
    await state.setExerciseRest('squat', 240);
    expect(state.restFor('squat'), 240);
    expect(state.restFor('bench_press'), state.profile.restSeconds);

    final now = DateTime(2026, 10, 1, 17);
    await state.startWorkout(now: now);
    final e = await state.addExercise('squat');
    e.sets = [SetEntry(weight: 100, reps: 5)];
    await state.toggleDone(e.sets.first, now: now);
    expect(state.restEndsAt, now.add(const Duration(seconds: 240)));

    await state.setExerciseRest('squat', null);
    expect(state.restFor('squat'), state.profile.restSeconds);

    final done = (await state.finishActive(
      now: now.add(const Duration(hours: 1)),
    )).workout!;
    final saved = await state.saveProgram(routineFromWorkout(done)!);
    expect(state.customPrograms.map((p) => p.id), contains(saved.id));
  });
}
