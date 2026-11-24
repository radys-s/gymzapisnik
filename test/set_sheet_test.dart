import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/finders.dart';

import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/exercises/exercise_detail_page.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/set_sheet.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

void main() {
  late AppState state;
  late WorkoutExercise bench;

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(320, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout();
      bench = await state.addExercise('bench_press');
      bench.sets = [
        SetEntry(weight: 60, reps: 8, done: true),
        SetEntry(weight: 60, reps: 8),
      ];
      await state.saveActive();
    });
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: WorkoutPage(state)),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.descendant(
    of: find.bySemanticsLabel(label),
    matching: find.byType(TextField),
  );

  Finder sheetField(int i) => find
      .descendant(of: find.byType(SetSheet), matching: find.byType(TextField))
      .at(i);

  testWidgets('card has no stepper row, tapping a value opens the sheet', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(byLabel('Přidat 2,5 kg'), findsNothing);

    await tester.tap(field('Váha v kg, Série 2'));
    await tester.pumpAndSettle();
    expect(find.text('Barbell Bench Press · Série 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(byLabel('Přidat 2,5 kg'));
    await tester.tap(byLabel('Přidat 2,5 kg'));
    await tester.tap(byLabel('Ubrat opakování'));
    await tester.pump();
    expect(bench.sets[1].weight, 65);
    expect(bench.sets[1].reps, 7);
    expect(bench.sets[0].weight, 60);

    // Pod nulu nejde.
    for (var i = 0; i < 30; i++) {
      await tester.tap(byLabel('Ubrat 2,5 kg'));
    }
    await tester.pump();
    expect(bench.sets[1].weight, 0);

    // Ručně vyšší váha se tlačítkem nesrazí, nečitelný text se nepřepíše.
    await tester.enterText(sheetField(0), '1200');
    await tester.tap(byLabel('Přidat 2,5 kg'));
    await tester.pump();
    expect(bench.sets[1].weight, 1200);
    await tester.enterText(sheetField(0), '1,2,5');
    await tester.tap(byLabel('Přidat 2,5 kg'));
    await tester.pump();
    expect(tester.widget<TextField>(sheetField(0)).controller!.text, '1,2,5');
    expect(find.textContaining('Oprav váhu'), findsOneWidget);
    // Nečitelná váha se neuloží jako 0, zůstane poslední platná.
    expect(bench.sets[1].weight, 1200);
    await tester.enterText(sheetField(0), '-5');
    await tester.pump();
    expect(bench.sets[1].weight, 1200);
    await tester.enterText(sheetField(0), '62,5');
    await tester.enterText(sheetField(1), '-2');
    await tester.pump();
    expect(bench.sets[1].reps, 7);
    // Pasted decimal reps must not silently turn 8.5 into 85 reps.
    await tester.enterText(sheetField(1), '8.5');
    await tester.pump();
    expect(bench.sets[1].reps, 7);
    await tester.enterText(sheetField(1), '1500');
    await tester.pump();
    expect(find.textContaining('do 999'), findsOneWidget);
    expect(bench.sets[1].reps, isNot(1500));

    await tester.enterText(sheetField(0), '62,5');
    await tester.enterText(sheetField(1), '10');
    // Jen uložit: hodnoty zůstanou, série se nepotvrdí.
    await tester.tap(find.text('Jen uložit'));
    await tester.pumpAndSettle();
    expect(find.byType(SetSheet), findsNothing);
    expect((bench.sets[1].weight, bench.sets[1].reps), (62.5, 10));
    expect(bench.sets[1].done, isFalse);
    expect(
      tester.widget<TextField>(field('Váha v kg, Série 2')).controller!.text,
      '62,5',
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  testWidgets('sheet uses the weight step from settings', (tester) async {
    await pump(tester);
    await tester.runAsync(() => state.setPreferences(weightStep: 1.25));
    await tester.pumpAndSettle();
    await tester.tap(field('Opakování, Série 2'));
    await tester.pumpAndSettle();
    expect(byLabel('Přidat 1,25 kg'), findsOneWidget);
    await tester.tap(byLabel('Přidat 1,25 kg'));
    await tester.pump();
    expect(bench.sets[1].weight, 61.25);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  testWidgets('card header opens exercise screen and offers swap', (
    tester,
  ) async {
    await pump(tester);
    expect(byLabel('Vyměnit cvik'), findsOneWidget);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailPage), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Technika'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Technika'), findsOneWidget);
  });

  testWidgets('sheet confirms the set and starts the rest', (tester) async {
    await pump(tester);
    await tester.tap(field('Váha v kg, Série 2'));
    await tester.pumpAndSettle();
    await tester.tap(byLabel('Přidat 2,5 kg'));
    await tester.pump();

    final confirm = find.descendant(
      of: find.byType(SetSheet),
      matching: find.text('Potvrdit sérii'),
    );
    expect(confirm, findsOneWidget);
    expect(state.restEndsAt, isNull);
    await tester.runAsync(() async {
      await tester.tap(confirm);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(SetSheet), findsNothing);
    expect(
      (bench.sets[1].weight, bench.sets[1].reps, bench.sets[1].done),
      (62.5, 8, true),
    );
    expect(state.restEndsAt, isNotNull);
  });

  testWidgets('done set keeps a plain Hotovo', (tester) async {
    await pump(tester);
    await tester.tap(field('Váha v kg, Série 1'));
    await tester.pumpAndSettle();
    final sheet = find.byType(SetSheet);
    expect(
      find.descendant(of: sheet, matching: find.text('Hotovo')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('Potvrdit sérii')),
      findsNothing,
    );
  });

  testWidgets('check on an empty set opens the sheet with the reason', (
    tester,
  ) async {
    await pump(tester);
    late WorkoutExercise curl;
    await tester.runAsync(() async {
      // Cvik bez historie začíná prázdnou sérií.
      curl = await state.addExercise('barbell_curl');
    });
    await tester.pumpAndSettle();
    expect((curl.sets.single.weight, curl.sets.single.reps), (0, 0));

    await tester.runAsync(() async {
      await tester.tap(byLabel('Potvrdit sérii').last);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    final sheet = find.byType(SetSheet);
    expect(sheet, findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.textContaining('Zadej')),
      findsOneWidget,
    );
    expect(curl.sets.single.done, isFalse);

    await tester.enterText(sheetField(0), '30');
    await tester.enterText(sheetField(1), '10');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Potvrdit sérii')),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SetSheet), findsNothing);
    final set = curl.sets.single;
    expect((set.weight, set.reps, set.done), (30, 10, true));
  });

  Finder sheetConfirm() => find.descendant(
    of: find.byType(SetSheet),
    matching: find.text('Potvrdit sérii'),
  );

  testWidgets('confirm with unreadable text keeps the sheet open', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field('Váha v kg, Série 2'));
    await tester.pumpAndSettle();
    await tester.enterText(sheetField(0), '62,5,');
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(sheetConfirm());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SetSheet), findsOneWidget);
    expect(find.textContaining('Váha musí být číslo od 0'), findsOneWidget);
    expect(bench.sets[1].done, isFalse);
  });

  testWidgets('keyboard Done on reps confirms the set', (tester) async {
    await pump(tester);
    await tester.tap(field('Opakování, Série 2'));
    await tester.pumpAndSettle();
    await tester.enterText(sheetField(1), '10');
    await tester.runAsync(() async {
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SetSheet), findsNothing);
    expect((bench.sets[1].reps, bench.sets[1].done), (10, true));
  });

  testWidgets('confirm never flips an already confirmed set back', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(field('Váha v kg, Série 2'));
    await tester.pumpAndSettle();
    // Série je mezitím potvrzená (např. první pokus uložil jen v paměti).
    bench.sets[1].done = true;
    await tester.runAsync(() async {
      await tester.tap(sheetConfirm());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(find.byType(SetSheet), findsNothing);
    expect(bench.sets[1].done, isTrue);
  });
}
