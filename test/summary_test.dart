import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/summary/summary_page.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/widgets/labels.dart';

void main() {
  test('labels', () {
    expect(
      setLabel(ExerciseType.weighted, SetEntry(weight: 77.5, reps: 8)),
      '77,5×8',
    );
    expect(setLabel(ExerciseType.bodyweight, SetEntry(reps: 12)), '12 opak.');
    expect(
      setLabel(ExerciseType.bodyweight, SetEntry(weight: 10, reps: 6)),
      '+10 kg × 6',
    );
    expect(recordLabel(RecordKind.bestE1rm, 101.333), '101,3 kg');
    expect(recordLabel(RecordKind.maxReps, 15), '15 opak.');
    expect(durationLabel(const Duration(minutes: 52)), '52 min');
    expect(durationLabel(const Duration(seconds: 30)), '< 1 min');
    expect(durationLabel(const Duration(minutes: 65)), '1 h 05 min');
  });

  testWidgets('summary compares with last time and shows new record', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout today;
    await tester.runAsync(() async {
      await state.load();
      Future<Workout> log(DateTime at, double kg) async {
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        return (await state.finishActive(
          now: at.add(const Duration(minutes: 50)),
        )).workout!;
      }

      await log(DateTime(2026, 10, 1, 17), 80);
      today = await log(DateTime(2026, 10, 3, 17), 82.5);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: SummaryPage(state, today, justFinished: true),
      ),
    );
    expect(find.text('50 min'), findsOneWidget);
    expect(find.textContaining('Lepší než minule'), findsOneWidget);
    expect(find.text('minule 80×8'), findsOneWidget);
    expect(find.textContaining('Nové osobní rekordy'), findsOneWidget);
    expect(find.textContaining('Max váha: 82,5 kg'), findsOneWidget);
    expect(find.textContaining('(+20 kg)'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text('Hotovo'), findsOneWidget);
    // Kouč řekne verdikt a konkrétní cíl na příště.
    expect(
      find.text('Nové rekordy: Bench press. Takhle vypadá progres.'),
      findsOneWidget,
    );
    expect(find.text('Příště'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^Bench press [\d,]+ kg × \d+$')),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('from history: delete asks first and closes the page', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout done;
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout(now: DateTime(2026, 10, 1, 17));
      final e = await state.addExercise('bench_press');
      e.sets = [SetEntry(weight: 60, reps: 8, done: true)];
      done = (await state.finishActive(now: DateTime(2026, 10, 1, 18)))
          .workout!;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SummaryPage(state, done)),
              ),
              child: const Text('Otevřít'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Otevřít'));
    await tester.pumpAndSettle();
    expect(find.text('Zopakovat trénink'), findsOneWidget);
    expect(find.text('Hotovo'), findsNothing);

    await tester.tap(find.byTooltip('Možnosti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat'));
    await tester.pumpAndSettle();
    expect(find.text('Smazat trénink?'), findsOneWidget);
    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    expect(state.workouts, hasLength(1));

    await tester.tap(find.byTooltip('Možnosti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Smazat').last);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(state.workouts, isEmpty);
    expect(find.text('Otevřít'), findsOneWidget);
    expect(find.text('Trénink smazán.'), findsOneWidget);
  });

  testWidgets('from history: compare two workouts set by set', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    final saved = <Workout>[];
    await tester.runAsync(() async {
      await state.load();
      for (final (day, kg, extra) in [
        (1, 60.0, 'squat'),
        (8, 65.0, 'leg_press'),
      ]) {
        await state.startWorkout(now: DateTime(2026, 10, day, 17));
        final e = await state.addExercise('bench_press');
        e.sets = [
          SetEntry(weight: kg, reps: 8, done: true),
          SetEntry(weight: kg, reps: 6, done: true),
        ];
        final o = await state.addExercise(extra);
        o.sets = [SetEntry(weight: 100, reps: 5, done: true)];
        saved.add(
          (await state.finishActive(now: DateTime(2026, 10, day, 18))).workout!,
        );
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        // Otevřeno ze staršího: porovnání stejně dá novější vlevo.
        home: SummaryPage(state, saved.first),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Možnosti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Porovnat s jiným'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 společný cvik'), findsOneWidget);
    await tester.tap(find.textContaining('8. 10. 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Porovnání'), findsWidgets);
    expect(find.text('Zlepšení proti 1. 10. 2026'), findsOneWidget);
    expect(find.text('65×8'), findsOneWidget);
    expect(find.text('60×8'), findsOneWidget);
    expect(find.text('Jen 8. 10. 2026'), findsOneWidget);
    expect(find.text('Jen 1. 10. 2026'), findsOneWidget);
    // Bench: celkově i obě série nahoru (65 proti 60 kg).
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
