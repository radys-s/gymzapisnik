import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/ambient.dart';
import 'package:gymzapisnik/ui/design/motion.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('stagger column shows every child and ends fully opaque', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        StaggerColumn(
          gap: 8,
          children: [for (var i = 0; i < 12; i++) Text('Řádek $i')],
        ),
      ),
    );
    // Obsah je ve stromu hned, i během animace.
    expect(find.text('Řádek 11'), findsOneWidget);
    await t.pumpAndSettle();
    for (final o in t.widgetList<Opacity>(find.byType(Opacity))) {
      expect(o.opacity, 1);
    }
  });

  testWidgets('reduced motion shows the final state without animating', (
    t,
  ) async {
    await t.pumpWidget(
      _app(const StaggerColumn(children: [Text('A'), Text('B')]), reduce: true),
    );
    await t.pump();
    for (final o in t.widgetList<Opacity>(find.byType(Opacity))) {
      expect(o.opacity, 1);
    }
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('enabling reduced motion completes an in-flight reveal', (
    t,
  ) async {
    await t.pumpWidget(_app(const Reveal(index: 8, child: Text('Ready'))));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, lessThan(1));
    await t.pumpWidget(
      _app(const Reveal(index: 8, child: Text('Ready')), reduce: true),
    );
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    await t.pump(const Duration(seconds: 1));
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('reduced motion completes a tab transition immediately', (
    t,
  ) async {
    Widget tabs(int index, bool reduce) => _app(
      FadeIndexedStack(index: index, children: const [Text('A'), Text('B')]),
      reduce: reduce,
    );
    await t.pumpWidget(tabs(0, false));
    await t.pumpWidget(tabs(1, false));
    await t.pump(const Duration(milliseconds: 30));
    await t.pumpWidget(tabs(1, true));
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('animated values expose only the latest value to accessibility', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(_app(const AnimatedLabel('10 kg')));
    await t.pumpWidget(_app(const AnimatedLabel('20 kg')));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('20 kg'), findsOneWidget);
    expect(find.bySemanticsLabel('10 kg'), findsNothing);
    await t.pumpWidget(_app(const AnimatedLabel('20 kg'), reduce: true));
    expect(find.text('10 kg'), findsNothing);
    expect(t.hasRunningAnimations, isFalse);
    semantics.dispose();
  });

  testWidgets('press scale never swallows the tap', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _app(
        PressScale(
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Klik'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Klik'));
    await t.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('fade stack keeps tab state and settles opaque', (t) async {
    var index = 0;
    late StateSetter set;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (_, s) {
            set = s;
            return FadeIndexedStack(
              index: index,
              children: const [Text('Domů'), Text('Trénink')],
            );
          },
        ),
      ),
    );
    set(() => index = 1);
    await t.pump(const Duration(milliseconds: 50));
    final mid = t.widget<Opacity>(find.byType(Opacity).first).opacity;
    expect(mid, lessThan(1));
    await t.pumpAndSettle();
    expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    expect(find.text('Domů', skipOffstage: false), findsOneWidget);
  });

  testWidgets('sheen passes over its child, then rests until the next pass', (
    t,
  ) async {
    Ambient.enabled = true;
    addTearDown(() => Ambient.enabled = false);
    await t.pumpWidget(
      _app(
        const Sheen(
          borderRadius: BorderRadius.zero,
          delay: 0,
          child: SizedBox(width: 120, height: 40),
        ),
      ),
    );
    CustomPaint paint() => t.widget<CustomPaint>(
      find.descendant(
        of: find.byType(Sheen),
        matching: find.byType(CustomPaint),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    expect(paint().foregroundPainter, isNotNull);
    await t.pump(const Duration(seconds: 2));
    expect(paint().foregroundPainter, isNull);
    // Leaving the screen stops the shared clock; a timer left running
    // would fail this test.
    await t.pumpWidget(_app(const SizedBox()));
  });

  testWidgets('ambient clock pauses when the app goes into the background', (
    t,
  ) async {
    Ambient.enabled = true;
    addTearDown(() => Ambient.enabled = false);
    await t.pumpWidget(
      _app(
        AmbientBuilder(
          builder: (_, time, _) => Text(time == null ? 'Paused' : 'Running'),
        ),
      ),
    );
    expect(find.text('Running'), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(find.text('Paused'), findsOneWidget);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(find.text('Running'), findsOneWidget);
    await t.pumpWidget(_app(const SizedBox()));
  });

  testWidgets('ambient effects stay still with reduced motion', (t) async {
    Ambient.enabled = true;
    addTearDown(() => Ambient.enabled = false);
    await t.pumpWidget(
      _app(const AuroraBackground(child: SizedBox.expand()), reduce: true),
    );
    await t.pump(const Duration(seconds: 1));
    expect(t.binding.hasScheduledFrame, isFalse);
  });
}
