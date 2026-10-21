import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/anatomy.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/technique.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/exercises/exercise_detail_page.dart';

void main() {
  test('every catalog exercise has technique and two images', () {
    for (final e in builtInExercises) {
      final t = techniqueOf(e.id);
      expect(t, isNotNull, reason: e.id);
      expect(t!.steps, hasLength(3), reason: e.id);
      expect(t.mistakes, isNotEmpty, reason: e.id);
      expect(exerciseImages(e.id), hasLength(2), reason: e.id);
      expect(anatomyOf(e.id), isNotNull, reason: e.id);
    }
    expect(techniques.keys.toSet(), builtInExercises.map((e) => e.id).toSet());
    expect(exerciseImages('custom_x'), isEmpty);
  });

  testWidgets('exercise screen shows muscles, technique and alternatives', (
    tester,
  ) async {
    // Nejužší telefon a větší písmo: nic nesmí přetéct.
    tester.view
      ..physicalSize = const Size(320, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: ExerciseDetailPage(state, 'lateral_raise'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Svaly'), findsOneWidget);
    expect(find.text('Boční delt'), findsWidgets); // svaly i alternativy
    expect(find.text('Technika'), findsOneWidget);
    expect(find.text('Časté chyby'), findsOneWidget);
    expect(find.text('Alternativy'), findsOneWidget);
    expect(find.text('Začátek pohybu'), findsOneWidget);

    await tester.tap(find.text('Cable lateral raise'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final top = find.byType(ExerciseDetailPage).last;
    expect(
      tester.widget<ExerciseDetailPage>(top).exerciseId,
      'cable_lateral_raise',
    );
    expect(
      find.descendant(of: top, matching: find.text('Svaly')),
      findsOneWidget,
    );
  });
}
