import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/ambient.dart';
import 'package:gymzapisnik/ui/design/motion.dart';
import 'package:gymzapisnik/ui/home/home_technical.dart';
import 'package:gymzapisnik/ui/theme.dart';

Widget app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: buildTheme(),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('background never intercepts a foreground action', (t) async {
    var taps = 0;
    await t.pumpWidget(
      app(
        Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: TextButton(
                onPressed: () => taps++,
                child: const Text('Start'),
              ),
            ),
            // Even above the action, the decorative layer must pass through input.
            const Positioned.fill(child: HomeTechnicalBackground()),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Start'));
    expect(taps, 1);
    expect(find.text('01'), findsNothing);
  });

  testWidgets('switching away from Home detaches the ambient clock', (t) async {
    Ambient.enabled = true;
    addTearDown(() => Ambient.enabled = false);
    var tab = 0;
    late StateSetter select;
    await t.pumpWidget(
      app(
        StatefulBuilder(
          builder: (_, set) {
            select = set;
            return FadeIndexedStack(
              index: tab,
              children: const [
                Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(child: HomeTechnicalBackground()),
                    Center(child: HomeConsoleSurface(child: Text('Workout'))),
                  ],
                ),
                SizedBox.expand(),
              ],
            );
          },
        ),
      ),
    );
    await t.pump();
    expect(Ambient.clock.isRunning, isTrue);
    select(() => tab = 1);
    await t.pump();
    expect(Ambient.clock.isRunning, isFalse);
    select(() => tab = 0);
    await t.pump();
    expect(Ambient.clock.isRunning, isTrue);
    await t.pumpWidget(const SizedBox());
    expect(Ambient.clock.isRunning, isFalse);
  });

  testWidgets('reduced motion renders the texture without starting a clock', (
    t,
  ) async {
    Ambient.enabled = true;
    addTearDown(() => Ambient.enabled = false);
    await t.pumpWidget(app(const HomeTechnicalBackground(), reduce: true));
    await t.pump();
    expect(Ambient.clock.isRunning, isFalse);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
