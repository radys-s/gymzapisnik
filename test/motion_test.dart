import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/motion.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: reduce),
  child: Directionality(textDirection: TextDirection.ltr, child: child),
);

void main() {
  testWidgets('CountUp skončí na cílové hodnotě', (t) async {
    await t.pumpWidget(
      _wrap(CountUp(value: 1250, format: (v) => '${v.round()} kg')),
    );
    await t.pumpAndSettle();
    expect(find.text('1250 kg'), findsOneWidget);
    expect(find.bySemanticsLabel('1250 kg'), findsOneWidget);
  });

  testWidgets('CountUp při omezených animacích ukáže hodnotu hned', (t) async {
    await t.pumpWidget(
      _wrap(CountUp(value: 42, format: (v) => '${v.round()}'), reduce: true),
    );
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('Reveal je v stromu hned a dojede do plna', (t) async {
    await t.pumpWidget(_wrap(const Reveal(index: 2, child: Text('Ahoj'))));
    expect(find.text('Ahoj'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    final o = t.widget<Opacity>(find.byType(Opacity));
    expect(o.opacity, 1);
  });

  testWidgets('Reveal při omezených animacích je hned viditelný', (t) async {
    await t.pumpWidget(_wrap(const Reveal(child: Text('Ahoj')), reduce: true));
    await t.pump();
    final o = t.widget<Opacity>(find.byType(Opacity));
    expect(o.opacity, 1);
  });
}
