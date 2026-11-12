import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/onboarding/onboarding_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Future<AppState> _fresh(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Klepnutí, které ukládá do databáze, musí běžet v reálném čase.
Future<void> _tapAndSave(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await _settle(tester);
}

/// Jedna volba: zvýraznění a po chvíli sama další otázka.
Future<void> _pick(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
  await _settle(tester);
}

Future<void> _open(WidgetTester tester, AppState state) async {
  tester.view
    ..physicalSize = const Size(400, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlanSetupPage(state)),
            ),
            child: const Text('Otevřít'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Otevřít'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plan setup asks the onboarding questions plus focus', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await _open(tester, state);

    // Bez uvítání: rovnou první otázka, s počtem otázek včetně zaměření.
    expect(find.text('Co chceš hlavně?'), findsOneWidget);
    expect(find.bySemanticsLabel('Otázka 1 ze 8'), findsOneWidget);
    expect(find.text('Přeskočit'), findsNothing);

    await _pick(tester, find.text(PlanGoal.strength.label));
    await _pick(tester, find.text(Experience.values.first.label));
    expect(find.text('Kolik času máš?'), findsOneWidget);
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
    await _pick(tester, find.text(TrainingPlace.gym.label));
    await _tapAndSave(tester, find.text('Nic mě nebolí').hitTestable());
    expect(find.text('Něco o tobě'), findsOneWidget);
    await _tapAndSave(tester, find.text('Doplním později'));

    expect(find.text('Na co se zaměřit?'), findsOneWidget);
    final focus = focusChoices.first;
    await tester.tap(find.widgetWithText(FilterChip, focusName(focus)));
    await tester.pump();
    final favorite = favoriteChoices.first;
    await tester.ensureVisible(
      find.widgetWithText(FilterChip, state.exercise(favorite).name),
    );
    await tester.tap(
      find.widgetWithText(FilterChip, state.exercise(favorite).name),
    );
    await tester.pump();
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());

    expect(find.text('Jak chceš začít?'), findsOneWidget);
    await _tapAndSave(tester, find.text('Vyber za mě'));
    expect(find.text('Plán je hotový'), findsOneWidget);
    expect(state.planAnswers?.goal, PlanGoal.strength);
    expect(state.planAnswers?.focus, {focus});
    expect(state.planAnswers?.favorites, {favorite});

    await _tapAndSave(tester, find.text('Hotovo').hitTestable());
    expect(find.text('Otevřít'), findsOneWidget);
    expect(find.textContaining('je nastavený'), findsOneWidget);
    // Nastavení plánu nemění krok úvodu.
    expect(state.onboardingStep, 0);
  });

  testWidgets('back on the first plan question closes the page', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await _open(tester, state);
    await tester.tap(find.byTooltip('Zpět'));
    await tester.pumpAndSettle();
    expect(find.text('Otevřít'), findsOneWidget);
    expect(find.text('Co chceš hlavně?'), findsNothing);
  });
}
