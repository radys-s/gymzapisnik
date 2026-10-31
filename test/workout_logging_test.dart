import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/finders.dart';

import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/exercise_picker.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

/// Rozepsaný trénink s bench pressem (2 série) a dřepem.
Future<AppState> _state(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(() async {
    await state.load();
    await state.startWorkout();
    final bench = await state.addExercise('bench_press');
    bench.sets = [
      SetEntry(weight: 80, reps: 8, done: true),
      SetEntry(weight: 80, reps: 8),
    ];
    await state.addExercise('squat');
    await state.saveActive();
  });
  return state;
}

Future<void> _pump(WidgetTester tester, AppState state, {double scale = 1}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: WorkoutPage(state),
        ),
      ),
    );

/// Klepnutí, které zapisuje do databáze (v reálném čase).
Future<void> _write(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('deleted set comes back with Vrátit at the same place', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state);
    final bench = state.active!.exercises.first;
    final first = bench.sets.first;

    await tester.tap(find.byTooltip('Série 1, změnit typ').first);
    await tester.pumpAndSettle();
    await _write(tester, find.text('Smazat sérii'));
    expect(bench.sets, hasLength(1));
    expect(find.text('Série smazána'), findsOneWidget);

    // Lišta se zavírá animací ve falešném čase, zápis běží v reálném.
    await tester.tap(find.text('Vrátit'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    expect(bench.sets, hasLength(2));
    expect(bench.sets.first, same(first));
  });

  test('undo does nothing after the exercise was replaced', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    final entry = await state.addExercise('bench_press');
    entry.sets = [SetEntry(weight: 80, reps: 8), SetEntry(weight: 80, reps: 8)];
    final sets = entry.sets;
    final removed = sets.first;
    final index = await state.removeSet(entry, removed);
    await state.replaceExercise(entry, 'squat');
    final before = entry.sets.length;
    expect(await state.restoreSet(entry, removed, index, sets: sets), isFalse);
    expect(entry.sets, hasLength(before));
    expect(entry.sets, isNot(contains(removed)));

    // Odebraný cvik už sérii nevezme zpět.
    final other = await state.addExercise('bench_press');
    final otherSets = other.sets;
    final set = otherSets.first;
    final i = await state.removeSet(other, set);
    await state.removeExercise(other);
    expect(await state.restoreSet(other, set, i, sets: otherSets), isFalse);
  });

  testWidgets('set type menu switches a set to warm-up', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state);

    await tester.tap(find.byTooltip('Série 2, změnit typ'));
    await tester.pumpAndSettle();
    await _write(
      tester,
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Rozcvička'),
    );
    expect(state.active!.exercises.first.sets.last.warmup, isTrue);
    expect(find.byTooltip('Rozcvička, změnit typ'), findsOneWidget);
  });

  testWidgets('replacing an exercise with done sets asks first', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state);

    await tester.tap(byLabel('Vyměnit cvik').first);
    await tester.pumpAndSettle();
    expect(find.text('Nahradit cvik?'), findsOneWidget);
    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisePickerPage), findsNothing);
    expect(state.active!.exercises.first.exerciseId, 'bench_press');
  });

  testWidgets('exercise moves up from its menu', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state);

    await tester.tap(find.byTooltip('Možnosti cviku').first);
    await tester.pumpAndSettle();
    expect(find.text('Posunout výš'), findsNothing);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Možnosti cviku').last);
    await tester.pumpAndSettle();
    expect(find.text('Posunout níž'), findsNothing);
    await _write(tester, find.text('Posunout výš'));
    expect(
      [for (final e in state.active!.exercises) e.exerciseId],
      ['squat', 'bench_press'],
    );
  });

  testWidgets('picker adds several exercises in tap order', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state);

    await tester.tap(find.text('Přidat cvik'));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisePickerPage), findsOneWidget);
    // Hledání nemá automatický fokus (klávesnice nezakryje seznam).
    final search = tester.widget<TextField>(find.byType(TextField));
    expect(search.autofocus, isFalse);

    await tester.enterText(find.byType(TextField), 'press');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incline press'));
    await tester.tap(find.text('Chest press machine'));
    await tester.pump();
    expect(find.text('Přidat cviky (2)'), findsOneWidget);
    await _write(tester, find.text('Přidat cviky (2)'));

    expect(
      [for (final e in state.active!.exercises) e.exerciseId],
      ['bench_press', 'squat', 'incline_press', 'chest_press_machine'],
    );
  });

  testWidgets('workout fits a phone at text scale 1.5', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = await _state(tester);
    await _pump(tester, state, scale: 1.5);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(byLabel('Potvrdit sérii'), findsWidgets);

    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Váha v kg, Série 1')),
      findsNWidgets(2),
    );
    expect(find.bySemanticsLabel(RegExp('Opakování, Série 2')), findsOneWidget);
    semantics.dispose();
  });
}
