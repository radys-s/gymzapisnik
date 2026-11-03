import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/welcome/whats_new.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

Future<AppState> _app(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(390, 1400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(() async {
    await state.load();
    await state.acceptConsent(adult: true, guardianConsent: false);
    await state.finishWelcome(whatsNewRelease);
  });
  await tester.pumpWidget(GymApp(state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> _tapReal(WidgetTester tester, Finder f) async {
  await tester.runAsync(() async {
    await tester.tap(f);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('four tabs: Domů, Trénink, Strava, Profil', (tester) async {
    await _app(tester);
    for (final t in ['Domů', 'Trénink', 'Strava', 'Profil']) {
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(t)),
        findsOneWidget,
      );
    }
    await _tapReal(tester, find.text('Profil'));
    expect(find.text('Nastavení'), findsWidgets);
    expect(find.text('Cviky a rekordy'), findsOneWidget);
  });

  testWidgets('empty workout from Trénink, bar shows it on other tabs', (
    tester,
  ) async {
    final state = await _app(tester);
    final tabs = find.byType(NavigationBar);
    await _tapReal(
      tester,
      find.descendant(of: tabs, matching: find.text('Trénink')),
    );
    expect(find.text('Moje rutiny'), findsOneWidget);
    await _tapReal(tester, find.text('Začít prázdný trénink'));
    expect(state.active, isNotNull);
    expect(find.byType(WorkoutPage), findsOneWidget);

    // Zpět z tréninku: trénink běží dál a lišta je vidět i ve Stravě.
    await tester.runAsync(() async {
      await tester.binding.handlePopRoute();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(state.active, isNotNull);
    await _tapReal(
      tester,
      find.descendant(of: tabs, matching: find.text('Strava')),
    );
    final bar = find.bySemanticsLabel(RegExp('^Běžící trénink'));
    expect(bar, findsOneWidget);
    expect(find.textContaining('Přidej první cvik'), findsOneWidget);

    await _tapReal(tester, bar);
    expect(find.byType(WorkoutPage), findsOneWidget);
  });

  testWidgets('no bar without a running workout', (tester) async {
    await _app(tester);
    expect(find.bySemanticsLabel(RegExp('^Běžící trénink')), findsNothing);
  });
}
