import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/hevy_import.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

const _header =
    'title,start_time,end_time,description,exercise_title,superset_id,'
    'exercise_notes,set_index,set_type,weight_kg,reps,distance_km,'
    'duration_seconds,rpe';

String _row(String exercise, String kg, String reps) =>
    'A,"15 Jul 2026, 09:00","15 Jul 2026, 10:00",,$exercise,,,0,normal,'
    '$kg,$reps,,,';

ExerciseSession _session(int day, double kg, {String? kind}) {
  final w = Workout(
    id: 'w$day',
    name: 'w',
    startedAt: DateTime(2026, 9, day),
    finishedAt: DateTime(2026, 9, day, 1),
  );
  final e = WorkoutExercise(
    id: 'e$day',
    exerciseId: 'squat',
    sets: [
      for (var i = 0; i < 3; i++) SetEntry(weight: kg, reps: 6, done: true),
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

Future<AppState> _state() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  return state;
}

void main() {
  test('after a deload the coach returns to the old weight', () {
    const plan = PlannedExercise('squat', sets: 3, repMin: 5, repMax: 8);
    final s = suggest(plan, ExerciseType.weighted, [
      _session(1, 100),
      _session(3, 90, kind: SuggestionKind.deload.name),
    ]);
    expect(s.weight, 100);
    expect(s.reps, 5);
  });

  test(
    'Hevy assisted weight is not added load, dumbbell variant stays apart',
    () {
      final r = parseHevyCsv(
        '$_header\n'
        '${_row('Pull Up (Assisted)', '30', '8')}\n'
        '${_row('Romanian Deadlift (Dumbbell)', '22', '10')}\n'
        '${_row('Romanian Deadlift (Barbell)', '80', '8')}\n',
      );
      final sets = {
        for (final e in r.workouts.single.exercises)
          e.exerciseId: e.sets.single,
      };
      final pull = sets['pull_up']!;
      expect(pull.weight, 0);
      expect(pull.extra['assistKg'], 30);
      expect(sets.containsKey('romanian_deadlift'), isTrue);
      expect(sets['romanian_deadlift']!.weight, 80);
      expect(
        r.newExercises.map((e) => e.name),
        contains('Romanian Deadlift (Dumbbell)'),
      );
    },
  );

  test('weighted set needs a weight before it can be confirmed', () async {
    final state = await _state();
    await state.startWorkout();
    final bench = await state.addExercise('bench_press');
    bench.sets = [SetEntry(reps: 8)];
    expect(await state.toggleDone(bench.sets.first), 'Zadej váhu v kg.');
    final dips = await state.addExercise('dips');
    dips.sets = [SetEntry(reps: 8)];
    expect(await state.toggleDone(dips.sets.first), isNull);
  });

  test('one broken row does not block start', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = LocalStore(db);
    await store.open();
    await store.put(Kinds.workout, {
      'id': 'bad',
      'exercises': [null],
    });
    final state = AppState(store);
    await state.load();
    expect(state.workouts, isEmpty);
    expect(await store.raw('bad'), isNotNull);
  });

  test(
    'restore keeps local programs and settings, adds missing ones',
    () async {
      final state = await _state();
      final mine = await state.saveProgram(
        const SplitTemplate(
          id: '',
          name: 'Můj',
        description: '',
          perWeek: 1,
          days: [
            SplitDay('Den', [PlannedExercise('squat')]),
          ],
        ),
      );
      await state.setPreferences(restSeconds: 90);
      final source = encodeBackup(
        Backup(
          exportedAt: DateTime(2026),
          workouts: const [],
          exercises: const [],
          settings: {
            'restSeconds': 180,
            'proteinTarget': 120,
            'programs': [
              {...mine.toJson(), 'name': 'Starý název'},
              {
                ...mine.toJson(),
                'id': '${customProgramPrefix}old',
                'name': 'Jiný',
              },
            ],
          },
        ),
      );
      await state.restoreBackup(source);
      expect(state.profile.restSeconds, 90);
      expect(state.profile.extra['proteinTarget'], 120);
      expect(state.customPrograms.map((p) => p.name), ['Můj', 'Jiný']);
    },
  );

  test('re-importing Hevy does not bring back a deleted workout', () async {
    final state = await _state();
    final csv = '$_header\n${_row('Squat (Barbell)', '100', '5')}\n';
    expect(await state.importHevy(csv), 1);
    await state.deleteWorkout(state.workouts.single);
    expect(await state.importHevy(csv), 0);
    expect(state.workouts, isEmpty);
  });
}
