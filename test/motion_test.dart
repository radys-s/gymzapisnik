import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      _app(
        const StaggerColumn(children: [Text('A'), Text('B')]),
        reduce: true,
      ),
    );
    await t.pump();
    for (final o in t.widgetList<Opacity>(find.byType(Opacity))) {
      expect(o.opacity, 1);
    }
    expect(t.hasRunningAnimations, isFalse);
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
}
