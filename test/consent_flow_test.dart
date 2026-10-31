import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/tips.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/program/program_widgets.dart';
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
  // Animace spuštěná v reálné zóně dokončí až její mikroúloha.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome, quiz, plan reveal and consent run once', (
    tester,
  ) async {
    final state = await _fresh(tester);
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();

    // Jeden slide s hodnotou, žádné brožurkové stránky ani výběr barvy.
    expect(find.text('Gym zápisník'), findsOneWidget);
    expect(find.text('Každý den víš, co cvičit'), findsOneWidget);
    await _tapAndSave(tester, find.text('Sestavit můj plán'));
    expect(find.text('Vyber si vzhled'), findsNothing);

    // Dotazník: 4 dny vybrané v týdnu, váha a doporučení podle nich.
    expect(find.text('Tvůj plán'), findsOneWidget);
    for (final d in ['Po', 'Út', 'Čt', 'Pá']) {
      await tester.ensureVisible(find.widgetWithText(DayToggle, d));
      await tester.tap(find.widgetWithText(DayToggle, d));
      await tester.pump();
    }
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '80');
    await _tapAndSave(tester, find.text('Ukázat plán'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(state.profile.splitId, 'upper_lower');
    expect(state.profile.weekGoal, 4);
    expect(state.profile.trainingDays, [1, 2, 4, 5]);
    expect(state.planAnswers?.days, 4);
    expect(state.bodyweights.first.kg, 80);

    // Odhalení plánu ukazuje uložený program a první trénink.
    expect(find.text('Plán je hotový'), findsOneWidget);
    expect(find.text('Upper / Lower'), findsOneWidget);
    expect(find.textContaining('První trénink · '), findsOneWidget);
    await _tapAndSave(tester, find.text('Pokračovat'));

    // Na webu/testu (bez oznámení) krok připomínky odpadá.
    expect(find.text('Než začneš'), findsOneWidget);
    await tester.tap(find.text('Souhlasím s podmínkami používání'));
    await tester.tap(find.text('Je mi 18 let nebo víc'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Pokračovat'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trénink'), findsWidgets);
    expect(state.profile.welcomeSeen, isTrue);
    expect(state.onboardingStep, 0);
    // Nová instalace nemá dostat okno s novinkami hned po uvítání.
    expect(state.profile.seenVersion, whatsNewRelease);
    expect(find.text('Co je nového'), findsNothing);
  });

  testWidgets('onboarding resumes on the saved step with saved answers', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.applyPlan(
        const PlanAnswers(days: 5, level: PlanLevel.advanced),
      );
      await state.setOnboardingStep(1);
    });
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();
    // Rovnou dotazník, s dřívějšími odpověďmi místo výchozích.
    expect(find.text('Tvůj plán'), findsOneWidget);
    final days = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>).first,
    );
    expect(days.selected, {5});
    // Zpět na úvod jde šipkou.
    await _tapAndSave(tester, find.byIcon(Icons.arrow_back_rounded));
    expect(find.text('Sestavit můj plán'), findsOneWidget);
    expect(state.onboardingStep, 0);
  });

  testWidgets('days removed in the quiz do not stay saved', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.applyPlan(const PlanAnswers(days: 3));
      await state.setFrequency(days: [1, 3, 5]);
      await state.setOnboardingStep(1);
    });
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GymApp(state));
    await tester.pumpAndSettle();
    for (final d in ['Po', 'St', 'Pá']) {
      await tester.tap(find.widgetWithText(DayToggle, d));
      await tester.pump();
    }
    await _tapAndSave(tester, find.text('Ukázat plán'));
    expect(state.profile.trainingDays, isNull);
    expect(find.text('Plán je hotový'), findsOneWidget);
  });

  testWidgets('minor needs guardian consent before entering the app', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() => state.finishWelcome(whatsNewRelease));
    // Celý souhlas na jedné obrazovce (tlačítko je až pod textem o AI).
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    expect(find.text('Trénink'), findsWidgets);
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
    // Velký nadpis + skrytý malý v liště.
    expect(find.text('Podmínky a soukromí'), findsNWidgets(2));
    expect(find.text('Co aplikace je'), findsOneWidget);
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
    expect(find.text('Trénink'), findsWidgets);

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
    expect(find.text('Trénink'), findsWidgets);
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
    expect(find.text('Trénink'), findsNothing);
    // Po minimální době aplikace sama naběhne.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Trénink'), findsWidgets);

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
    expect(find.text('Trénink'), findsWidgets);
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
    expect(find.text('Trénink'), findsWidgets);
  });
}
