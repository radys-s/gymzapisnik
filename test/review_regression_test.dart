import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/finders.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';
import 'package:gymzapisnik/ui/workout/set_sheet.dart';

import 'hevy_import_test.dart' show sample;

class ControlledStore extends LocalStore {
  ControlledStore(super.db);
  Completer<void>? gate;
  bool failFinish = false;
  bool failWrite = false;

  @override
  Future<void> put(String kind, Map<String, dynamic> data) async {
    await gate?.future;
    if (failWrite) throw StateError('write failed');
    await super.put(kind, data);
  }

  @override
  Future<void> replace({
    required String removeId,
    required String kind,
    required Map<String, dynamic> data,
  }) async {
    if (failFinish) throw StateError('disk full');
    await super.replace(removeId: removeId, kind: kind, data: data);
  }
}

void main() {
  late ControlledStore store;
  late AppState state;
  late SetEntry set;

  setUp(() async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    store = ControlledStore(db);
    state = AppState(store);
    await state.load();
    await state.startWorkout();
    set = (await state.addExercise('bench_press')).sets.single
      ..weight = 80
      ..reps = 8;
  });

  test(
    'rapid edits then finish preserve the latest saved data after restart',
    () async {
      store.gate = Completer<void>();
      final writes = <Future<void>>[];
      for (var r = 5; r <= 8; r++) {
        set.reps = r;
        writes.add(state.saveActive());
      }
      final confirm = state.toggleDone(set);
      final finish = state.finishActive();
      final lateSave = state.saveActive();
      store.gate!.complete();
      await Future.wait([...writes, confirm, lateSave]);
      final result = await finish;
      final again = AppState(store);
      await again.load();
      expect(again.active, isNull);
      expect(again.workouts.single.toJson(), result.workout!.toJson());
      expect(again.workouts.single.exercises.single.sets.single.reps, 8);
    },
  );

  test('failed finish returns a visible error and can be retried', () async {
    await state.toggleDone(set);
    store.failFinish = true;
    final result = await state.finishActive();
    expect(result.error, isNotNull);
    expect(state.active, isNotNull);
    expect(state.workouts, isEmpty);
    final again = AppState(store);
    await again.load();
    expect(again.active!.exercises.single.sets.single.done, isTrue);
    store.failFinish = false;
    expect((await state.finishActive()).workout, isNotNull);
  });

  test(
    'a failed queued write does not poison later writes or finishing',
    () async {
      store.failWrite = true;
      await expectLater(state.saveActive(), throwsStateError);
      store.failWrite = false;
      set.reps = 9;
      await state.toggleDone(set);
      final result = await state.finishActive();
      final again = AppState(store);
      await again.load();
      expect(again.workouts.single.toJson(), result.workout!.toJson());
      expect(again.workouts.single.exercises.single.sets.single.reps, 9);
    },
  );

  test(
    'double finish waits for one transaction and blocks a new workout',
    () async {
      store.gate = Completer<void>();
      final confirm = state.toggleDone(set);
      final first = state.finishActive();
      final second = state.finishActive();
      await expectLater(state.startWorkout(), throwsStateError);
      store.gate!.complete();
      await confirm;
      expect((await first).workout!.id, (await second).workout!.id);
      expect(state.workouts, hasLength(1));
    },
  );

  test(
    'update waits for finish and refuses reload after a failed finish',
    () async {
      store.gate = Completer<void>();
      final confirm = state.toggleDone(set);
      store.failFinish = true;
      final finish = state.finishActive();
      final update = expectLater(state.saveBeforeUpdate(), throwsStateError);
      store.gate!.complete();
      await confirm;
      expect((await finish).error, isNotNull);
      await update;
      expect(state.active, isNotNull);
    },
  );

  test(
    'concurrent Hevy import has the same history before and after restart',
    () async {
      final counts = await Future.wait([
        state.importHevy(sample),
        state.importHevy(sample),
      ]);
      expect(counts.reduce((a, b) => a + b), 2);
      expect(state.workouts, hasLength(2));
      expect(state.customExercises, hasLength(1));
      final again = AppState(store);
      await again.load();
      expect(again.workouts.map((w) => w.id), state.workouts.map((w) => w.id));
    },
  );

  test(
    'backup with duplicate IDs is rejected without touching local data',
    () async {
      await state.toggleDone(set);
      await state.finishActive();
      final json = jsonDecode(state.exportBackup()) as Map<String, dynamic>;
      (json['workouts'] as List).add((json['workouts'] as List).first);
      await expectLater(
        state.restoreBackup(jsonEncode(json)),
        throwsFormatException,
      );
      expect(state.workouts, hasLength(1));
    },
  );

  testWidgets('two taps during a slow confirm do not undo the set', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: WorkoutPage(state)));
    await tester.runAsync(() async {
      store.gate = Completer<void>();
      await tester.tap(byLabel('Potvrdit sérii'));
      await tester.pump();
      await tester.tap(byLabel('Zrušit potvrzení'));
      expect(set.done, isTrue);
      store.gate!.complete();
      await state.saveActive();
    });
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'invalid backup settings and collisions never alter consent or draft',
    () async {
      await state.acceptConsent(adult: true, guardianConsent: false);
      final activeId = state.active!.id;
      final valid = state.exportBackup();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['settings'] = {'split': 123},
        (j) => j['exercises'] = [
          {'id': 'profile', 'name': 'Bad'},
        ],
        (j) => j['workouts'] = [
          {
            'id': 'bad',
            'startedAt': 'nonsense',
            'finishedAt': '2026-10-06T12:00:00Z',
          },
        ],
        (j) => j['workouts'] = [
          {
            ...state.active!.toJson(),
            'finishedAt': DateTime.now().toUtc().toIso8601String(),
          },
        ],
      ]) {
        final json = jsonDecode(valid) as Map<String, dynamic>;
        mutate(json);
        await expectLater(
          state.restoreBackup(jsonEncode(json)),
          throwsFormatException,
        );
        final again = AppState(store);
        await again.load();
        expect(again.active!.id, activeId);
        expect(again.profile.hasValidConsent, isTrue);
        expect(again.workouts, isEmpty);
      }
    },
  );

  testWidgets(
    'corrected confirmed values are saved before an immediate finish',
    (tester) async {
      await tester.runAsync(() => state.toggleDone(set));
      await tester.pumpWidget(MaterialApp(home: WorkoutPage(state)));
      // Pole v sérii jen otevře list; čísla se píšou v něm.
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      final sheet = find.byType(SetSheet);
      await tester.runAsync(() async {
        await tester.enterText(
          find.descendant(of: sheet, matching: find.byType(TextField)).first,
          '82,5',
        );
        await tester.enterText(
          find.descendant(of: sheet, matching: find.byType(TextField)).last,
          '7',
        );
        final result = await state.finishActive();
        final again = AppState(store);
        await again.load();
        final saved = again.workouts.single.exercises.single.sets.single;
        expect((saved.weight, saved.reps, saved.done), (82.5, 7, true));
        expect(again.workouts.single.toJson(), result.workout!.toJson());
      });
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('double tap after a fast write still keeps confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: WorkoutPage(state)));
    await tester.tap(byLabel('Potvrdit sérii'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
    await tester.tap(byLabel('Zrušit potvrzení'));
    expect(set.done, isTrue);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(byLabel('Zrušit potvrzení'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump();
    expect(set.done, isFalse); // pozdější úmyslná oprava zůstává možná
    await tester.pumpWidget(const SizedBox());
  });
}
