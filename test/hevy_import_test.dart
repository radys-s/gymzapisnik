import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/hevy_import.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

const header =
    'title,start_time,end_time,description,exercise_title,superset_id,'
    'exercise_notes,set_index,set_type,weight_kg,reps,distance_km,'
    'duration_seconds,rpe';

const sample =
    '$header\r\n'
    'Push A,"15 Jul 2026, 09:00","15 Jul 2026, 10:05","Dobrý, těžký",'
    'Bench Press (Barbell),,Pauza dole,0,warmup,40,10,,,\r\n'
    'Push A,"15 Jul 2026, 09:00","15 Jul 2026, 10:05","Dobrý, těžký",'
    'Bench Press (Barbell),,Pauza dole,1,normal,80,8,,,8\r\n'
    'Push A,"15 Jul 2026, 09:00","15 Jul 2026, 10:05","Dobrý, těžký",'
    'Bench Press (Dumbbell),,,0,normal,30,10,,,\r\n'
    'Push A,"15 Jul 2026, 09:00","15 Jul 2026, 10:05","Dobrý, těžký",'
    '"Zvláštní cvik ""X""",,,0,normal,12.5,12,,,\r\n'
    'Push A,"15 Jul 2026, 09:00","15 Jul 2026, 10:05","Dobrý, těžký",'
    'Plank,,,0,normal,0,0,,60,\r\n'
    'Legs,"17 Jul 2026, 18:30","17 Jul 2026, 19:20",,'
    'Squat (Barbell),,,0,normal,100,5,,,\r\n';

void main() {
  test('parses sets, warm-ups, names and times', () {
    final r = parseHevyCsv(sample);
    expect(r.workouts, hasLength(2));
    expect(r.skippedRows, 1); // plank bez opakování

    final push = r.workouts.firstWhere((w) => w.name == 'Push A');
    expect(push.startedAt, DateTime(2026, 7, 15, 9, 0));
    expect(push.finishedAt, DateTime(2026, 7, 15, 10, 5));
    expect(push.note, 'Dobrý, těžký');
    expect(push.exercises.map((e) => e.exerciseId), [
      'bench_press',
      'dumbbell_bench_press',
      isNot(anyOf('bench_press', 'dumbbell_bench_press')),
    ]);
    final bench = push.exercises.first;
    expect(bench.note, 'Pauza dole');
    expect(bench.sets.map((s) => (s.weight, s.reps, s.warmup)), [
      (40.0, 10, true),
      (80.0, 8, false),
    ]);
    expect(bench.sets.every((s) => s.done), isTrue);

    expect(r.newExercises, hasLength(1));
    expect(r.newExercises.single.name, 'Zvláštní cvik "X"');
    expect(r.newExercises.single.custom, isTrue);
    expect(push.exercises.last.exerciseId, r.newExercises.single.id);

    final legs = r.workouts.firstWhere((w) => w.name == 'Legs');
    expect(legs.exercises.single.exerciseId, 'squat');
  });

  test('converts pounds and rejects foreign files', () {
    final lbs = parseHevyCsv(
      'title,start_time,end_time,exercise_title,set_type,weight_lbs,reps\n'
      'A,"1 Jan 2026, 10:00","1 Jan 2026, 11:00",Deadlift (Barbell),normal,225,3\n',
    );
    expect(lbs.workouts.single.exercises.single.sets.single.weight, 102.1);

    expect(() => parseHevyCsv(''), throwsFormatException);
    expect(() => parseHevyCsv('a,b\n1,2\n'), throwsFormatException);
    expect(() => parseHevyCsv('$header\r\n'), throwsFormatException);
  });

  test('ids are stable so a second import adds nothing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();

    expect(await state.importHevy(sample), 2);
    expect(state.workouts, hasLength(2));
    expect(state.customExercises, hasLength(1));
    expect(await state.importHevy(sample), 0);
    expect(state.workouts, hasLength(2));
    expect(state.customExercises, hasLength(1));

    // přežije restart
    final again = AppState(LocalStore(db));
    await again.load();
    expect(again.workouts, hasLength(2));
    expect(again.workouts.every((Workout w) => w.finished), isTrue);
  });
}
