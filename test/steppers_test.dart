import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

void main() {
  testWidgets('steppers change the next set and save it', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late WorkoutExercise bench;
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout();
      bench = await state.addExercise('bench_press');
      bench.sets = [
        SetEntry(weight: 60, reps: 8, done: true),
        SetEntry(weight: 60, reps: 8),
        SetEntry(weight: 60, reps: 8),
      ];
      await state.saveActive();
    });
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.dark), home: WorkoutPage(state)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Jen jedna řada: u druhé série (první nepotvrzená).
    expect(
      find.byTooltip('Přidat 2,5 kg, Bench press, Série 2'),
      findsOneWidget,
    );
    expect(find.byTooltip('Přidat 2,5 kg, Bench press, Série 3'), findsNothing);

    await tester.tap(find.byTooltip('Přidat 2,5 kg, Bench press, Série 2'));
    await tester.tap(find.byTooltip('Přidat 2,5 kg, Bench press, Série 2'));
    await tester.tap(find.byTooltip('Ubrat opakování, Bench press, Série 2'));
    await tester.pump();
    expect(bench.sets[1].weight, 65);
    expect(bench.sets[1].reps, 7);
    expect(bench.sets[2].weight, 60);

    // Pod nulu nejde.
    for (var i = 0; i < 30; i++) {
      await tester.tap(find.byTooltip('Ubrat 2,5 kg, Bench press, Série 2'));
    }
    await tester.pump();
    expect(bench.sets[1].weight, 0);

    // Ručně zadaná vyšší váha se tlačítkem nesrazí, nečitelný text se nepřepíše.
    final kg = find.bySemanticsLabel('Váha v kg, Série 2');
    final field = find.descendant(of: kg, matching: find.byType(TextField));
    await tester.enterText(field, '1200');
    await tester.tap(find.byTooltip('Přidat 2,5 kg, Bench press, Série 2'));
    await tester.pump();
    expect(bench.sets[1].weight, 1200);
    await tester.enterText(field, '1,2,5');
    await tester.tap(find.byTooltip('Přidat 2,5 kg, Bench press, Série 2'));
    await tester.pump();
    expect(tester.widget<TextField>(field).controller!.text, '1,2,5');

    await tester.runAsync(() => state.setPreferences(weightStep: 1.25));
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Přidat 1,25 kg, Bench press, Série 2'),
      findsOneWidget,
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
