import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/settings/my_gym_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Future<AppState> _fresh(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Equipment _gear(String id) => findExercise(id, const [])!.equipment;

void main() {
  test(
    'bodyweight drops barbell and machine exercises from generated days',
    () {
      const a = PlanAnswers(place: TrainingPlace.bodyweight);
      var adapted = 0;
      for (final f in dayFocuses) {
        final orig = dayFromFocuses([f.id]);
        final day = personalizeDay(orig, a);
        // Bez jakékoli náhrady zůstane původní den, ne prázdný.
        if (identical(day, orig)) continue;
        adapted++;
        for (final e in day.exercises) {
          expect(
            _gear(e.exerciseId),
            isNot(anyOf(Equipment.barbell, Equipment.machine, Equipment.cable)),
            reason: '${f.id}: ${e.exerciseId}',
          );
        }
      }
      expect(adapted, greaterThan(3));
    },
  );

  test('small gym misses plate machines unless the user has them', () {
    const a = PlanAnswers(place: TrainingPlace.smallGym);
    expect(a.unavailable, contains('hack_squat'));
    final b = a.copyWith(present: {'hack_squat'});
    expect(b.unavailable, isNot(contains('hack_squat')));
    final c = b.copyWith(missing: {'leg_press'});
    expect(c.unavailable, contains('leg_press'));
    expect(PlanAnswers.tryParse(c.toJson())!.unavailable, c.unavailable);
  });

  testWidgets('toggling a machine in Moje posilovna saves it', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(
      () => state.applyPlan(const PlanAnswers(place: TrainingPlace.gym)),
    );
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: MyGymPage(state)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Moje posilovna'), findsWidgets);
    final machine = gymMachinesByMuscle(TrainingPlace.gym).values.first.first;
    expect(state.gymHas(machine.id), isTrue);
    await tester.runAsync(() async {
      await tester.tap(find.text(machine.name));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(state.gymHas(machine.id), isFalse);
    expect(state.planAnswers!.missing, {machine.id});

    // Doma s činkami: stroje vůbec nejsou na výběr.
    await tester.runAsync(() async {
      await tester.tap(find.text('Jen vlastní váha'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(state.planAnswers!.place, TrainingPlace.bodyweight);
    expect(find.byType(Switch), findsNothing);
  });
}
