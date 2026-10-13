import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/theme.dart';

double _ratio(Color fg, Color bg) {
  final f = Color.alphaBlend(fg, bg).computeLuminance();
  final b = bg.computeLuminance();
  final hi = f > b ? f : b;
  final lo = f > b ? b : f;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('text and icons stay readable in every look, accent and surface', () {
    final fails = <String>[];
    void check(String what, Color fg, Color bg, double min) {
      final r = _ratio(fg, bg);
      if (r < min) fails.add('$what ${r.toStringAsFixed(2)} < $min');
    }

    for (final accent in Accent.values) {
      for (final b in Brightness.values) {
        for (final look in Look.values) {
          for (final surface in [null, ...HeroSurface.values]) {
            // HeroCard dává světlý podklad jen motivům s tmavým písmem.
            if (surface == HeroSurface.bright &&
                accent.onGradient != Colors.black) {
              continue;
            }
            final p = AppPalette.of(b, accent, look, surface);
            final tag = '${accent.name}/${b.name}/${look.name}/$surface';
            // Na barevné kartě leží text přímo na přechodu.
            final grounds = switch (surface) {
              HeroSurface.bright => p.gradient,
              // Záře: nejsvětlejší místo je plný tmavý tón motivu.
              HeroSurface.glow => [
                const Color(0xFF111113),
                for (final c in accent.gradient(b).skip(1)) deepTone(c),
              ],
              null => [p.background, p.grouped],
            };
            for (final g in grounds) {
              check('$tag label', p.label, g, 4.5);
              check('$tag secondary', p.secondaryLabel, g, 4.5);
              if (surface != null) check('$tag accent', p.accent, g, 3);
            }
            if (surface == null) {
              check('$tag accent', p.accent, p.grouped, 3);
              check('$tag onAccent', p.onAccent, p.accent, 4.5);
              for (final g in p.gradient) {
                check('$tag onGradient', p.onGradient, g, 3);
              }
              if (p.cta != null) check('$tag onCta', p.onCta, p.cta!, 4.5);
            }
          }
        }
      }
    }
    expect(fails, isEmpty);
  });
}
