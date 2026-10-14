import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/coach/tips.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/welcome/whats_new.dart';

Future<AppState> _fresh(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

/// Klepnutí, které ukládá do databáze, musí běžet v reálném čase.
Future<void> _tapAndSave(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome, accent and consent run once on first launch', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.pumpWidget(GymApp(state));

    expect(find.text('Gym zápisník'), findsOneWidget);
    await tester.tap(find.text('Pokračovat'));
    await tester.pumpAndSettle();
    expect(find.text('Trénink i jídlo na jednom místě'), findsOneWidget);

    // Přeskočit vede na výběr barvy, ne rovnou na souhlas.
    await tester.tap(find.text('Přeskočit'));
    await tester.pumpAndSettle();
    expect(find.text('Vyber si vzhled'), findsOneWidget);
    await _tapAndSave(tester, find.text('Studio'));
    expect(state.profile.look, 'studio');
    await tester.ensureVisible(find.text('Západ'));
    await tester.pumpAndSettle();
    await _tapAndSave(tester, find.text('Západ'));
    expect(state.profile.accent, 'sunset');

    await tester.tap(find.text('Pokračovat'));
    await tester.pumpAndSettle();
    expect(find.text('Než začneš'), findsOneWidget);
    await tester.tap(find.text('Souhlasím s podmínkami používání'));
    await tester.tap(find.text('Je mi 18 let nebo víc'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Pokračovat'));

    expect(find.text('Cvičení'), findsWidgets);
    expect(state.profile.welcomeSeen, isTrue);
    // Nová instalace nemá dostat okno s novinkami hned po uvítání.
    expect(state.profile.seenVersion, whatsNewRelease);
    expect(find.text('Co je nového'), findsNothing);
  });

  testWidgets('minor needs guardian consent before entering the app', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() => state.finishWelcome(whatsNewRelease));
    await tester.pumpWidget(GymApp(state));

    // Uvítání už proběhlo: rovnou jen souhlas.
    expect(find.text('Než začneš'), findsOneWidget);
    PrimaryButton button() =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button().onPressed, isNull);

    await tester.tap(find.text('Souhlasím s podmínkami používání'));
    await tester.tap(find.text('Je mi méně než 18 let'));
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.tap(find.text('Mám souhlas rodiče nebo zákonného zástupce'));
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await _tapAndSave(tester, find.text('Pokračovat'));
    expect(find.text('Cvičení'), findsWidgets);
    expect(state.profile.adult, isFalse);
    expect(state.profile.restrictWeightLoss, isTrue);

    final reloaded = AppState(LocalStore(state.store.db));
    await tester.runAsync(reloaded.load);
    expect(reloaded.profile.hasValidConsent, isTrue);
  });

  testWidgets('existing user with outdated consent skips the welcome', (
    tester,
  ) async {
    final state = await _fresh(tester);
    // Souhlas ze starší verze podmínek, uvítání nikdy neviděl.
    final old = Profile(
      consentVersion: currentConsentVersion - 1,
      consentAt: DateTime(2026, 9, 1),
      adult: true,
    );
    await tester.runAsync(() async {
      await state.store.put(Kinds.profile, old.toJson());
      await state.load();
    });
    expect(state.profile.hasValidConsent, isFalse);
    await tester.pumpWidget(GymApp(state));
    expect(find.text('Než začneš'), findsOneWidget);
    expect(find.text('Přeskočit'), findsNothing);
  });

  testWidgets('terms open from consent', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(() => state.finishWelcome(whatsNewRelease));
    await tester.pumpWidget(GymApp(state));
    await tester.tap(find.text('Přečíst podmínky a soukromí'));
    await tester.pumpAndSettle();
    expect(find.text('Podmínky a soukromí'), findsOneWidget);
  });

  testWidgets('what is new shows once per release after an update', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(
      () => state.acceptConsent(adult: true, guardianConsent: false),
    );
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();
    expect(find.text('Co je nového'), findsOneWidget);
    await tester.ensureVisible(find.text('Pokračovat'));
    await tester.pumpAndSettle();
    await _tapAndSave(tester, find.text('Pokračovat'));
    expect(find.text('Co je nového'), findsNothing);
    expect(state.profile.seenVersion, whatsNewRelease);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();
    expect(find.text('Co je nového'), findsNothing);
  });

  testWidgets('boot shows mark, indicator only when loading is slow', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.markVersionSeen(whatsNewRelease);
    });

    // Rychlé načtení: žádné kolečko, rovnou aplikace.
    await tester.pumpWidget(
      AppLoader(open: () async => state, minShow: Duration.zero),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Cvičení'), findsWidgets);

    // Pomalé načtení: značka hned, kolečko až po chvíli.
    await tester.pumpWidget(const SizedBox());
    final slow = Completer<AppState>();
    await tester.pumpWidget(
      AppLoader(open: () => slow.future, minShow: Duration.zero),
    );
    expect(find.byType(AppMark), findsOneWidget);
    final ring = find.byType(AnimatedOpacity);
    expect(tester.widget<AnimatedOpacity>(ring).opacity, 0);
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.widget<AnimatedOpacity>(ring).opacity, 1);
    slow.complete(state);
    await tester.pumpAndSettle();
    expect(find.text('Cvičení'), findsWidgets);
  });

  testWidgets('boot keeps a tip readable, a tap skips it', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.markVersionSeen(whatsNewRelease);
    });
    await tester.pumpWidget(
      AppLoader(
        open: () async => state,
        minShow: const Duration(seconds: 2),
        tipSeed: 0,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('RADA'), findsOneWidget);
    expect(find.text(trainingTips.first), findsOneWidget);
    expect(find.text('Cvičení'), findsNothing);
    // Po minimální době aplikace sama naběhne.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Cvičení'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      AppLoader(
        open: () async => state,
        minShow: const Duration(seconds: 30),
        tipSeed: trainingTips.length,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('MOTIVACE'), findsOneWidget);
    await tester.tap(find.byType(BootScreen));
    await tester.pumpAndSettle();
    expect(find.text('Cvičení'), findsWidgets);
  });

  testWidgets('startup error offers retry', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.markVersionSeen(whatsNewRelease);
    });
    var attempts = 0;
    await tester.pumpWidget(
      AppLoader(
        minShow: Duration.zero,
        open: () async {
          attempts++;
          if (attempts == 1) throw StateError('úložiště je zamčené');
          return state;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aplikaci se nepodařilo spustit'), findsOneWidget);
    expect(find.textContaining('úložiště je zamčené'), findsOneWidget);
    await tester.tap(find.text('Zkusit znovu'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Cvičení'), findsWidgets);
  });
}
