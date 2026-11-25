import 'dart:ui' show PointerDeviceKind, SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/native.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/onboarding/onboarding_page.dart';
import 'package:gymzapisnik/ui/onboarding/question.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/brand_stage.dart';
import 'package:gymzapisnik/ui/design/motion.dart';
import 'package:gymzapisnik/ui/theme.dart';

Widget app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: buildTheme(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('brand entrance finishes and stops scheduling frames', (t) async {
    await t.pumpWidget(app(const BrandStage()));
    await t.pumpAndSettle();
    expect(t.hasRunningAnimations, isFalse);
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion immediately completes the brand entrance', (
    t,
  ) async {
    await t.pumpWidget(app(const SizedBox()));
    await t.pumpAndSettle();
    await t.pumpWidget(app(const BrandStage()));
    await t.pump(const Duration(milliseconds: 70));
    await t.pumpWidget(app(const BrandStage(), reduce: true));
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    final builder = t.widget<AnimatedBuilder>(
      find.descendant(
        of: find.byType(BrandStage),
        matching: find.byType(AnimatedBuilder),
      ),
    );
    expect((builder.animation as AnimationController).isAnimating, isFalse);
  });

  testWidgets(
    'welcome keeps Start accessible on a small phone with large text',
    (t) async {
      t.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final state = AppState(LocalStore(db));
      await t.runAsync(() async {
        await state.load();
        await state.setOnboardingStep(1);
      });
      await t.pumpWidget(
        MaterialApp(theme: buildTheme(), home: OnboardingPage(state)),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text('Začít').hitTestable(), findsOneWidget);
      await t.tap(find.text('Začít'));
      await t.pumpAndSettle();
      expect(find.text('Než začneš'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'choices expose a screen-reader action and disable it while saving',
    (t) async {
      var taps = 0;
      final semantics = t.ensureSemantics();
      Widget choice(bool enabled) => app(
        ChoiceCard(
          label: 'English',
          selected: false,
          enabled: enabled,
          onTap: () => taps++,
        ),
      );
      await t.pumpWidget(choice(true));
      await t.pumpAndSettle();
      expect(
        t
            .getSemantics(find.bySemanticsLabel('English'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      await t.pumpWidget(choice(false));
      await t.pumpAndSettle();
      expect(
        t
            .getSemantics(find.bySemanticsLabel('English'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await t.tap(find.text('English'), warnIfMissed: false);
      expect(taps, 0);
      semantics.dispose();
    },
  );

  testWidgets('hover lifts once, preserves taps, and returns on exit', (
    t,
  ) async {
    var taps = 0;
    final button = TextButton(
      onPressed: () => taps++,
      child: const Text('Start'),
    );
    await t.pumpWidget(
      app(
        HoverLift(
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange,
          child: button,
        ),
      ),
    );
    final before = t.getRect(find.byType(TextButton));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(before.center);
    await t.pumpAndSettle();
    expect(
      t.getRect(find.byType(TextButton)).top,
      closeTo(before.top - 2, 0.01),
    );
    await t.tap(find.text('Start'));
    expect(taps, 1);
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(t.getRect(find.byType(TextButton)).top, closeTo(before.top, 0.01));
    await mouse.removePointer();
  });

  testWidgets('keyboard focus reaches the real control without an extra stop', (
    t,
  ) async {
    var taps = 0;
    await t.pumpWidget(
      app(
        HoverLift(
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange,
          child: TextButton(
            autofocus: true,
            onPressed: () => taps++,
            child: const Text('Start'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(taps, 1);
  });
}
