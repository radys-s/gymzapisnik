import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/builder_page.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

Future<AppState> _state(WidgetTester tester, {bool active = false}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(() async {
    await state.load();
    if (active) {
      await state.startWorkout();
      await state.addExercise('lateral_raise');
    }
  });
  return state;
}

void _tall(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('builder picks groups, count, swaps and returns the day', (
    tester,
  ) async {
    _tall(tester);
    final state = await _state(tester);
    SplitDay? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.push<SplitDay>(
              context,
              MaterialPageRoute(builder: (_) => WorkoutBuilderPage(state)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Vyber aspoň jednu partii'), findsOneWidget);
    expect(find.text('Začít trénink'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Ramena'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Méně: Počet cviků'));
    await tester.pump();
    await tester.tap(find.byTooltip('Méně: Počet cviků'));
    await tester.pumpAndSettle();
    expect(find.text('Lateral raise'), findsOneWidget);

    // Výměna bočního deltu za alternativu na stejnou hlavu.
    await tester.tap(find.text('Lateral raise'));
    await tester.pumpAndSettle();
    expect(find.text('Stejná hlava: Boční delt'), findsOneWidget);
    await tester.tap(find.text('Cable lateral raise'));
    await tester.pumpAndSettle();
    expect(find.text('Lateral raise'), findsNothing);

    await tester.tap(find.text('Začít trénink'));
    await tester.pumpAndSettle();
    expect(result!.name, 'Ramena');
    final ids = result!.exercises.map((p) => p.exerciseId).toList();
    expect(ids, hasLength(3));
    expect(ids, contains('cable_lateral_raise'));
    expect(ids, isNot(contains('lateral_raise')));

    await tester.runAsync(() => state.startPlanned(result!));
    expect(state.active!.name, 'Ramena');
    expect(state.active!.exercises.map((e) => e.exerciseId), ids);
  });

  testWidgets('workout replace offers alternatives by head', (tester) async {
    _tall(tester);
    final state = await _state(tester, active: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: WorkoutPage(state),
      ),
    );
    await tester.tap(find.byTooltip('Možnosti cviku').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nahradit'));
    await tester.pumpAndSettle();
    expect(find.text('Stejná hlava: Boční delt'), findsOneWidget);
    expect(find.text('Zadní delt'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.text('Face pull'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(state.active!.exercises.single.exerciseId, 'face_pull');
  });

  test('startPlanned refuses an empty day and a running workout', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    expect(() => state.startPlanned(const SplitDay('X', [])), throwsStateError);
    await state.startPlanned(buildDay(['legs'], 2));
    expect(() => state.startPlanned(buildDay(['legs'], 2)), throwsStateError);
  });
}
