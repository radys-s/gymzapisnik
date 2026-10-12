import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/history/edit_workout_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Future<(AppState, Workout)> _setup(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  late Workout done;
  await tester.runAsync(() async {
    await state.load();
    await state.startWorkout(now: DateTime(2026, 10, 1, 17));
    final e = await state.addExercise('bench_press');
    e.sets = [
      SetEntry(weight: 40, reps: 10, done: true),
      SetEntry(weight: 60, reps: 8, done: true),
    ];
    done = (await state.finishActive(now: DateTime(2026, 10, 1, 18))).workout!;
  });
  tester.view
    ..physicalSize = const Size(390, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditWorkoutPage(state, done)),
            ),
            child: const Text('Otevřít'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Otevřít'));
  await tester.pumpAndSettle();
  return (state, done);
}

TextButton _saveButton(WidgetTester tester) => tester.widget<TextButton>(
  find.ancestor(of: find.text('Uložit'), matching: find.byType(TextButton)),
);

void main() {
  testWidgets('edit sets, mark warm-up and save', (tester) async {
    final (state, _) = await _setup(tester);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.byTooltip('Série 1, změnit typ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozcvička'));
    await tester.pumpAndSettle();
    expect(find.text('R'), findsOneWidget);
    expect(find.byTooltip('Série 1, změnit typ'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '8'), '9');
    await tester.pump();
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.runAsync(() async {
      await tester.tap(find.text('Uložit'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(find.text('Otevřít'), findsOneWidget);
    final sets = state.workouts.single.exercises.single.sets;
    expect(sets.first.warmup, isTrue);
    expect(sets.last.reps, 9);
  });

  testWidgets('removed set and exercise come back with Vrátit', (
    tester,
  ) async {
    await _setup(tester);
    await tester.tap(find.byTooltip('Série 2, změnit typ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat sérii'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Série 2, změnit typ'), findsNothing);
    await tester.tap(find.text('Vrátit'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Série 2, změnit typ'), findsOneWidget);

    await tester.tap(find.byTooltip('Odebrat cvik'));
    await tester.pumpAndSettle();
    expect(find.text('Žádný cvik'), findsOneWidget);
    await tester.tap(find.text('Vrátit'));
    await tester.pumpAndSettle();
    expect(find.text('Žádný cvik'), findsNothing);
    // Po vrácení je trénink stejný jako předtím.
    expect(_saveButton(tester).onPressed, isNull);

    // Série jde smazat i přímo křížkem v řádku.
    await tester.tap(find.byTooltip('Smazat sérii').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Série 2, změnit typ'), findsNothing);
    expect(_saveButton(tester).onPressed, isNotNull);
  });

  testWidgets('leaving with changes asks first', (tester) async {
    final (state, done) = await _setup(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Název'), 'Jiný');
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Zahodit změny?'), findsOneWidget);
    await tester.tap(find.text('Pokračovat v úpravách'));
    await tester.pumpAndSettle();
    expect(find.text('Upravit trénink'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zahodit změny'));
    await tester.pumpAndSettle();
    expect(find.text('Otevřít'), findsOneWidget);
    expect(state.workouts.single.name, done.name);
  });
}
