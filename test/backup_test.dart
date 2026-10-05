import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/core/version.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/csv.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';

Future<AppState> newState() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  await state.acceptConsent(adult: true, guardianConsent: false);
  return state;
}

Future<void> logWorkout(
  AppState state,
  DateTime at,
  String exerciseId,
  List<SetEntry> sets,
) async {
  await state.startWorkout(now: at);
  final e = await state.addExercise(exerciseId);
  e.sets = sets;
  await state.finishActive(now: at.add(const Duration(hours: 1)));
}

void main() {
  // Dvě nezávislá zařízení = dvě databáze v paměti.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('backup round trip into a fresh device', () async {
    final source = await newState();
    await source.setPreferences(restSeconds: 90, theme: 'light');
    await source.setSplit('ppl');
    await logWorkout(source, DateTime(2026, 9, 1, 17), 'bench_press', [
      SetEntry(weight: 80, reps: 8, done: true),
    ]);
    final json = source.exportBackup();

    final target = await newState();
    expect(await target.restoreBackup(json), 1);
    expect(target.workouts.single.exercises.single.sets.single.weight, 80);
    expect(target.profile.restSeconds, 90);
    expect(target.profile.theme, 'light');
    expect(target.profile.splitId, 'ppl');
    expect(target.profile.hasValidConsent, isTrue);

    // Po restartu aplikace jsou data stále v úložišti.
    final reloaded = AppState(target.store);
    await reloaded.load();
    expect(reloaded.workouts, hasLength(1));
    expect(reloaded.profile.restSeconds, 90);
  });

  test('restore adds missing workouts and keeps local edits', () async {
    final state = await newState();
    await logWorkout(state, DateTime(2026, 9, 1, 17), 'squat', [
      SetEntry(weight: 100, reps: 5, done: true),
    ]);
    final backup = state.exportBackup();
    await logWorkout(state, DateTime(2026, 9, 3, 17), 'bench_press', [
      SetEntry(weight: 80, reps: 8, done: true),
    ]);
    // Úprava po záloze: obnova ji nesmí přepsat starší verzí.
    final edited = state.workouts.last.copy()..name = 'Upraveno';
    expect(await state.updateWorkout(edited), isNull);
    expect(await state.restoreBackup(backup), 0);
    expect(state.workouts, hasLength(2));
    expect(state.workouts.first.exercises.single.exerciseId, 'bench_press');
    expect(state.workouts.last.name, 'Upraveno');

    // Smazaný trénink obnova vrátí.
    await state.deleteWorkout(state.workouts.last);
    expect(await state.restoreBackup(backup), 1);
    expect(state.workouts, hasLength(2));
    expect(state.workouts.last.name, isNot('Upraveno')); // verze ze zálohy
  });

  test('invalid backups are rejected with a Czech message', () async {
    final state = await newState();
    for (final bad in [
      'nonsense',
      '{"format":"other"}',
      '{"format":"$backupFormat","version":99}',
      '{"format":"$backupFormat","version":1,"workouts":[1]}',
    ]) {
      await expectLater(
        state.restoreBackup(bad),
        throwsA(isA<FormatException>()),
      );
    }
    expect(state.workouts, isEmpty);
  });

  test('backup leaves out consent and unknown profile keys', () {
    final b = decodeBackup(
      '{"format":"$backupFormat","version":1,'
      '"settings":{"restSeconds":60,"adult":true,"consentAt":"x"},'
      '"workouts":[{"id":"w","startedAt":"2026-09-01T10:00:00Z"}]}',
    );
    expect(b.settings, {'restSeconds': 60});
    expect(b.workouts, isEmpty); // rozepsaný trénink se neobnovuje
  });

  test('csv for Czech Excel', () {
    final w = Workout(
      id: 'w',
      name: 'Push; těžký',
      startedAt: DateTime(2026, 9, 1, 17),
      finishedAt: DateTime(2026, 9, 1, 18, 5),
      note: '=SUM(A1)',
      exercises: [
        WorkoutExercise(
          id: 'e',
          exerciseId: 'bench_press',
          sets: [
            SetEntry(weight: 40, reps: 10, warmup: true, done: true),
            SetEntry(weight: 77.5, reps: 8, done: true),
            SetEntry(weight: 80, reps: 0),
          ],
        ),
      ],
    );
    final csv = workoutsToCsv([
      w,
    ], (id) => Exercise(id: id, name: 'Bench press', muscle: 'Hrudník'));
    expect(csv.startsWith('﻿Datum;Trénink;Cvik'), isTrue);
    final lines = csv.trim().split('\r\n');
    expect(lines, hasLength(3));
    expect(
      lines[2],
      '2026-09-01 18:05;"Push; těžký";Bench press;Hrudník;2;;77,5;8;98,2;'
      "'=SUM(A1)",
    );
    expect(lines[1], contains(';ano;40;10;;'));
  });

  test('app version matches pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('\nversion: $appVersion\n'));
  });
}
