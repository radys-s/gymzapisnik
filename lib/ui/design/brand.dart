import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The app logo: a thick ring opened into a "G", closed by a dumbbell,
/// in ink on a flat ember plate. Without the plate the mark is ember.
///
/// One painter draws the mark everywhere: in the app, on the launch screen,
/// and (through `tool/brand_assets_test.dart`) in the icon files.
class BrandPainter extends CustomPainter {
  /// Ember plate behind the mark; without it only the mark is drawn.
  final bool plate;

  /// Rounded plate corners. Icon files are full squares the system masks.
  final bool rounded;

  /// Scale of the mark inside the plate (icon safe zones use less than 1).
  final double scale;

  const BrandPainter({this.plate = true, this.rounded = true, this.scale = 1});

  /// Opening of the ring above the dumbbell, in radians.
  static const _gap = 0.98;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Offset.zero & Size(side, side);
    if (plate) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(rounded ? side * 0.225 : 0),
        ),
        Paint()..color = AppPalette.ember,
      );
    }
    final u = side / 100 * scale;
    canvas
      ..save()
      ..translate(side / 2 - 50 * u, side / 2 - 50 * u);
    _paintMark(canvas, u, plate ? AppPalette.ink : AppPalette.ember);
    canvas.restore();
  }

  void _paintMark(Canvas canvas, double u, Color color) {
    final center = Offset(50 * u, 50 * u);
    final ring = Rect.fromCircle(center: center, radius: 26 * u);
    const sweep = math.pi * 2 - _gap;
    final ink = Paint()..color = color;
    RRect bar(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * u, y * u, w * u, h * u),
          Radius.circular(math.min(w, h) / 2 * u),
        );
    canvas
      // Dumbbell docked inside the ring: its handle is the bar of the "G".
      ..drawRRect(bar(44, 45.5, 32, 9), ink)
      ..drawArc(
        ring,
        0,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12 * u
          ..strokeCap = StrokeCap.round,
      )
      ..drawRRect(bar(40, 35.5, 9, 29), ink)
      ..drawRRect(bar(31.5, 41.5, 7, 17), ink);
  }

  @override
  bool shouldRepaint(BrandPainter old) =>
      old.plate != plate || old.rounded != rounded || old.scale != scale;
}
