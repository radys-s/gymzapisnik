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
import 'package:gymzapisnik/ui/onboarding/question.dart';
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

/// Jedna volba: zvýraznění a po chvíli sama další otázka.
Future<void> _pick(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Stav uprostřed úvodu: souhlas je daný a úvod pokračuje krokem [step]
/// (0 uvítání, 1 souhlas, 2 cíl, 3 zkušenost, 4 čas, 5 posilovna,
/// 6 bolest, 7 hotový plán).
Future<void> _midway(AppState state, int step) => state.acceptConsent(
  adult: true,
  guardianConsent: false,
  onboardingStep: step,
);

Future<void> _open(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GymApp(state));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome, consent, quiz and plan reveal run once', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await _open(tester, state);

    // Language step first.
    expect(find.text('Choose your language'), findsOneWidget);
    await _tapAndSave(tester, find.text('Continue').hitTestable());

    // Welcome value slide.
    expect(find.text('Gym zápisník'), findsOneWidget);
    expect(find.text('Každý den víš, co cvičit'), findsOneWidget);
    await _tapAndSave(tester, find.text('Začít'));
    expect(find.text('Vyber si vzhled'), findsNothing);

    // Consent.
    expect(find.text('Než začneš'), findsOneWidget);
    await tester.tap(find.text('Souhlasím s podmínkami používání'));
    await tester.tap(find.text('Je mi 18 let nebo víc'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
    expect(state.profile.hasValidConsent, isTrue);
    expect(state.profile.ready, isFalse);

    expect(find.text('Co chceš hlavně?'), findsOneWidget);
    expect(find.byType(WhyLine), findsOneWidget);
    await _pick(tester, find.text('Svaly'));
    expect(find.text('Jak dlouho cvičíš?'), findsOneWidget);
    await _pick(tester, find.text('Rok'));

    // New path step - 6+ months defaults to own, switch to guided.
    expect(find.text('How do you want to start?'), findsOneWidget);
    await tester.ensureVisible(find.text('Build a recommended plan'));
    await tester.tap(find.text('Build a recommended plan'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Continue').hitTestable());

    expect(find.text('Kolik času máš?'), findsOneWidget);
    for (final d in ['Po', 'Út', 'Čt', 'Pá']) {
      await tester.ensureVisible(find.widgetWithText(DayToggle, d));
      await tester.tap(find.widgetWithText(DayToggle, d));
      await tester.pump();
    }
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());

    expect(find.text('Kde cvičíš?'), findsOneWidget);
    await _pick(tester, find.text('Doma s činkami'));

    expect(find.text('Bolí tě něco?'), findsOneWidget);
    await tester.tap(find.text('Kolena'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(state.profile.splitId, 'upper_lower');
    expect(state.profile.weekGoal, 4);
    expect(state.profile.trainingDays, [1, 2, 4, 5]);
    expect(state.planAnswers?.days, 4);
    expect(state.planAnswers?.experience, Experience.year);
    expect(state.planAnswers?.place, TrainingPlace.home);
    expect(state.planAnswers?.avoid, {Joint.knees});
    for (final d in state.split!.days) {
      for (final e in d.exercises) {
        expect(e.exerciseId, isNot(contains('squat')), reason: d.name);
      }
    }

    expect(find.text('Něco o tobě'), findsNothing);
    expect(find.text('Plán je hotový'), findsOneWidget);
    expect(find.text('Upper / Lower'), findsOneWidget);
    expect(find.textContaining('První trénink · '), findsOneWidget);
    expect(find.text('Složím si vlastní'), findsOneWidget);
    await _tapAndSave(tester, find.text('Beru tenhle plán'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trénink'), findsWidgets);
    expect(state.profile.ready, isTrue);
    expect(state.profile.welcomeSeen, isTrue);
    expect(state.onboardingStep, 0);
    expect(state.profile.seenVersion, whatsNewRelease);
    expect(find.text('Co je nového'), findsNothing);
  });

  testWidgets('own program opens from the plan and the plan stays', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.applyPlan(const PlanAnswers(days: 3));
      await _midway(state, 10);
    });
    await _open(tester, state);
    expect(find.text('Plán je hotový'), findsOneWidget);
    await _tapAndSave(tester, find.text('Složím si vlastní'));
    expect(find.text('Nový program'), findsWidgets);

    // Návrat bez uložení: návrh platí dál a úvod čeká na rozhodnutí.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Plán je hotový'), findsOneWidget);
    expect(state.profile.splitId, 'full_body_3');
    expect(state.profile.ready, isFalse);
  });

  testWidgets('onboarding resumes on the saved step with saved answers', (
    tester,
  ) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.applyPlan(
        const PlanAnswers(days: 5, experience: Experience.two),
      );
      await _midway(state, 6);
    });
    await _open(tester, state);
    expect(find.text('Kolik času máš?'), findsOneWidget);
    expect(
      tester.widget<ChoiceTile>(find.widgetWithText(ChoiceTile, '5×')).selected,
      isTrue,
    );
    // Zpět jde šipkou na předchozí otázku.
    await _tapAndSave(tester, find.byTooltip('Zpět'));
    expect(find.text('How do you want to start?'), findsOneWidget);
    expect(state.onboardingStep, 5);
  });

  testWidgets('a step saved before consent resumes on the consent', (
    tester,
  ) async {
    final state = await _fresh(tester);
    // Starší verze se na souhlas ptala až na konci.
    await tester.runAsync(() => state.setOnboardingStep(5));
    await _open(tester, state);
    expect(find.text('Než začneš'), findsOneWidget);
  });

  testWidgets('days removed in the quiz do not stay saved', (tester) async {
    final state = await _fresh(tester);
    await tester.runAsync(() async {
      await state.applyPlan(const PlanAnswers(days: 3));
      await state.setFrequency(days: [1, 3, 5]);
      await _midway(state, 6);
    });
    await _open(tester, state);
    for (final d in ['Po', 'St', 'Pá']) {
      await tester.tap(find.widgetWithText(DayToggle, d));
      await tester.pump();
    }
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
    await _pick(tester, find.text('Velké komerční fitko'));
    await _tapAndSave(tester, find.text('Nic mě nebolí'));
    // Přeskoč volitelné kroky (tělo, zaměření) až na hotový plán.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      if (find.text('Plán je hotový').evaluate().isNotEmpty) break;
      final skip = find.text('Přeskočit');
      if (skip.evaluate().isNotEmpty) {
        await _tapAndSave(tester, skip.hitTestable());
        continue;
      }
      final cont = find.text('Pokračovat');
      if (cont.evaluate().isNotEmpty) {
        await _tapAndSave(tester, cont.hitTestable());
        continue;
      }
      final contEn = find.text('Continue');
      if (contEn.evaluate().isNotEmpty) {
        await _tapAndSave(tester, contEn.hitTestable());
      }
    }
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

    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
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
    await _tapAndSave(tester, find.text('Pokračovat').hitTestable());
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
