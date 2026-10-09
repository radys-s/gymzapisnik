import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/premium/entitlements.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

AppState newState({required bool paywall}) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return AppState(LocalStore(db), paywall: paywall);
}

DateTime monday() => DateTime(2026, 10, 5, 12);

void main() {
  test('paywall is off for testers: everything unlocked', () {
    expect(paywallEnabled, isFalse);
    for (final f in ProFeature.values) {
      expect(Entitlements.has(const Profile(), f), isTrue);
    }
  });

  test('with paywall on, only Pro profiles are unlocked', () {
    const free = Profile();
    final pro = free.withExtra({'pro': true});
    for (final f in ProFeature.values) {
      expect(Entitlements.has(free, f, paywall: true), isFalse);
      expect(Entitlements.has(pro, f, paywall: true), isTrue);
    }
  });

  test('locked coach plans without weight suggestions', () async {
    final state = newState(paywall: true);
    await state.load();
    await state.setSplit('ppl');
    // historie, ze které by kouč navrhl váhu
    for (final daysAgo in [10, 3]) {
      final at = DateTime.now().subtract(Duration(days: daysAgo));
      await state.startWorkout(now: at);
      final e = await state.addExercise('bench_press');
      e.sets = [
        for (var i = 0; i < 4; i++) SetEntry(weight: 80, reps: 8, done: true),
      ];
      await state.finishActive(now: at.add(const Duration(hours: 1)));
    }
    final day = state.split!.day(0);
    final locked = state.plan(day).first.$2;
    expect(locked.weight, 0);
    expect(locked.reason, contains('Pro'));

    await state.setPro(true);
    final unlocked = state.plan(day).first.$2;
    expect(unlocked.weight, greaterThan(0));
  });

  testWidgets('locked cards open the Pro overview; unlocked show content', (
    tester,
  ) async {
    final state = newState(paywall: true);
    await tester.runAsync(state.load);
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(body: HomePage(state, now: monday)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Denní mise a streak'), findsOneWidget);
    expect(find.text('Dnes je dobrý den na trénink'), findsNothing);

    await tester.tap(find.text('Denní mise a streak'));
    await tester.pumpAndSettle();
    expect(find.text('Gym zápisník Pro'), findsOneWidget);
    expect(find.text('Nákup zatím není k dispozici'), findsOneWidget);
    expect(find.text('Rychlý progres'), findsOneWidget);
  });

  testWidgets('with paywall off, home shows the mission and no locks', (
    tester,
  ) async {
    final state = newState(paywall: false);
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(body: HomePage(state, now: monday)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dnes je dobrý den na trénink'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
