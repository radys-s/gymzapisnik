import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/nutrition_target.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/nutrition/nutrition_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Future<AppState> _state(WidgetTester tester, {bool adult = true}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(() async {
    await state.load();
    await state.acceptConsent(adult: adult, guardianConsent: !adult);
  });
  return state;
}

Future<void> _show(WidgetTester tester, AppState state) async {
  tester.view
    ..physicalSize = const Size(400, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: NutritionPage(state, initialDay: DateTime(2026, 10, 5)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('targets follow bodyweight and goal, minors get protein only', () {
    // 80 kg × 2,0 g = 160 g; 80 × 33 + 250 = 2890 → 2900 kcal.
    final muscle = suggestTargets(kg: 80, goal: PlanGoal.muscle, adult: true);
    expect(muscle.protein, 160);
    expect(muscle.kcal, 2900);
    // 63 kg × 1,6 = 100,8 → 100 g; 63 × 33 = 2079 → 2100 kcal.
    final fit = suggestTargets(kg: 63, goal: PlanGoal.fitness, adult: true);
    expect(fit.protein, 100);
    expect(fit.kcal, 2100);
    final minor = suggestTargets(kg: 60, goal: PlanGoal.strength, adult: false);
    expect(minor.protein, 110); // 60 × 1,8 = 108 → 110
    expect(minor.kcal, isNull);
  });

  testWidgets('without bodyweight Strava asks for it', (tester) async {
    final state = await _state(tester);
    await _show(tester, state);
    expect(
      find.text('Zapiš tělesnou váhu a doporučím ti cíl bílkovin.'),
      findsOneWidget,
    );
    expect(find.text('Zapsat váhu'), findsOneWidget);
  });

  testWidgets('bodyweight gives a suggested target that can be accepted', (
    tester,
  ) async {
    final state = await _state(tester);
    await tester.runAsync(() => state.addBodyweight(80));
    await _show(tester, state);
    expect(find.text('Doporučeno z tvé váhy 80 kg.'), findsOneWidget);
    expect(find.text('z 160 g'), findsOneWidget);
    expect(find.text('z 2900 kcal'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Nastavit jako cíl'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(state.profile.proteinTarget, 160);
    expect(state.profile.kcalTarget, 2900);
    expect(find.textContaining('Doporučeno z tvé váhy'), findsNothing);
  });

  testWidgets('minor sees only the protein suggestion', (tester) async {
    final state = await _state(tester, adult: false);
    await tester.runAsync(() => state.addBodyweight(60));
    await _show(tester, state);
    expect(find.text('z 120 g'), findsOneWidget); // 60 × 2,0 (výchozí cíl)
    // Bez kalorického cíle: jen kruh bílkovin.
    expect(find.text('Energie'), findsNothing);
    expect(find.text('Bílkoviny'), findsOneWidget);
  });
}
