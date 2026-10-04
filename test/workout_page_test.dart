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
  testWidgets('set identical to last time is logged with one tap', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout(now: DateTime(2026, 10, 1));
      final entry = await state.addExercise('bench_press');
      entry.sets = [SetEntry(weight: 77.5, reps: 8, done: true)];
      await state.finishActive(now: DateTime(2026, 10, 1, 1));
      await state.startWorkout();
      await state.addExercise('bench_press');
    });
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.dark), home: WorkoutPage(state)),
    );

    expect(find.text('77,5×8'), findsOneWidget);
    expect(find.widgetWithText(TextField, '77,5'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('Potvrdit sérii'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final set = state.active!.exercises.single.sets.single;
    expect((set.weight, set.reps, set.done), (77.5, 8, true));
    expect(find.byTooltip('Zrušit potvrzení'), findsOneWidget);
  });
}
