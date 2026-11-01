import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/theme.dart';

double _ratio(Color fg, Color bg) {
  final f = Color.alphaBlend(fg, bg).computeLuminance();
  final b = bg.computeLuminance();
  final hi = f > b ? f : b;
  final lo = f > b ? b : f;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('text and icons stay readable on the gym palette', () {
    final fails = <String>[];
    void check(String what, Color fg, Color bg, double min) {
      final r = _ratio(fg, bg);
      if (r < min) fails.add('$what ${r.toStringAsFixed(2)} < $min');
    }

    const p = AppPalette.gym;
    for (final g in [p.background, p.grouped, p.elevated]) {
      check('label', p.label, g, 7);
      check('secondary', p.secondaryLabel, g, 4.5);
      check('accent', p.accent, g, 3);
    }
    check('onAccent', p.onAccent, p.accent, 4.5);
    check('onCta', p.onCta, p.cta, 4.5);
    for (final g in [...AppPalette.training, ...AppPalette.food]) {
      check('onGradient', p.onGradient, g, 4.5);
    }
    expect(fails, isEmpty);
  });
}
