import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/finders.dart';

import 'package:gymzapisnik/coach/plates.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

PersonalRecord _rec(RecordKind kind, double value) => PersonalRecord(
  exerciseId: 'bench_press',
  kind: kind,
  value: value,
  set: SetEntry(),
  workoutId: 'old',
  date: DateTime(2026),
);

void main() {
  group('live records', () {
    final before = {
      RecordKind.maxWeight: _rec(RecordKind.maxWeight, 80),
      RecordKind.bestE1rm: _rec(RecordKind.bestE1rm, e1rm(80, 8)),
    };

    test('heavier set beats both records, first of equal sets wins', () {
      final a = SetEntry(weight: 85, reps: 8, done: true);
      final b = SetEntry(weight: 85, reps: 8, done: true);
      final session = [a, b];
      List<RecordKind> kinds(SetEntry s) => liveRecordKinds(
        set: s,
        sessionSets: session,
        before: before,
        type: ExerciseType.weighted,
      );
      expect(kinds(a), [RecordKind.maxWeight, RecordKind.bestE1rm]);
      expect(kinds(b), isEmpty);
      // Lepší pozdější série rekord převezme.
      b.reps = 9;
      expect(kinds(b), [RecordKind.bestE1rm]);
      expect(kinds(a), [RecordKind.maxWeight]);
    });

    test('no record without history, for warm-ups or open sets', () {
      final s = SetEntry(weight: 200, reps: 1, done: true);
      expect(
        liveRecordKinds(
          set: s,
          sessionSets: [s],
          before: const {},
          type: ExerciseType.weighted,
        ),
        isEmpty,
      );
      for (final x in [
        SetEntry(weight: 200, reps: 1, done: true, warmup: true),
        SetEntry(weight: 200, reps: 1),
      ]) {
        expect(
          liveRecordKinds(
            set: x,
            sessionSets: [x],
            before: before,
            type: ExerciseType.weighted,
          ),
          isEmpty,
        );
      }
    });
  });

  group('plates and warm-ups', () {
    test('plates per side', () {
      expect(platesFor(100).perSide, [25.0, 15.0]);
      expect(platesFor(102.5).perSide, [25.0, 15.0, 1.25]);
      expect(platesFor(20).perSide, isEmpty);
      expect(platesFor(1e15).perSide, isEmpty); // bez zamrznutí
      expect(platesFor(61, bar: 20).missing, closeTo(1, 0.001));
      expect(platesFor(60, bar: 15).perSide, [20.0, 2.5]);
    });

    test('warm-up ramps to the working weight', () {
      expect(warmupPlan(100), [
        (weight: 40.0, reps: 10),
        (weight: 60.0, reps: 5),
        (weight: 80.0, reps: 3),
      ]);
      expect(warmupPlan(15), isEmpty);
      expect(warmupPlan(20).every((w) => w.weight < 20), isTrue);
    });
  });

  testWidgets('confirming a record set shows a trophy and a message', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout(
        now: DateTime.now().subtract(const Duration(days: 3)),
      );
      final old = await state.addExercise('bench_press');
      old.sets = [SetEntry(weight: 80, reps: 8, done: true)];
      await state.finishActive(
        now: DateTime.now().subtract(const Duration(days: 3)),
      );
      await state.startWorkout();
      final bench = await state.addExercise('bench_press');
      bench.sets = [SetEntry(weight: 85, reps: 8)];
      await state.saveActive();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: WorkoutPage(state),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    await tester.runAsync(() async {
      await tester.tap(byLabel('Potvrdit sérii').first);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.textContaining('Nový osobní rekord'), findsOneWidget);
    // Pohár u série a v hlášce.
    expect(find.byIcon(Icons.emoji_events_rounded), findsNWidgets(2));
  });

  test('warm-ups replace open warm-ups before the working sets', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    await state.startWorkout();
    final bench = await state.addExercise('bench_press');
    bench.sets = [
      SetEntry(weight: 30, reps: 10, warmup: true),
      SetEntry(weight: 100, reps: 5),
    ];
    expect(await state.addWarmups(bench), 3);
    expect(bench.sets.map((s) => (s.weight, s.warmup)), [
      (40.0, true),
      (60.0, true),
      (80.0, true),
      (100.0, false),
    ]);
    bench.sets.first.done = true;
    expect(await state.addWarmups(bench), isNull);
  });
}
