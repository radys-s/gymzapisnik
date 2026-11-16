import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The app logo: a progress ring opened into a "G", closed by a dumbbell.
///
/// One painter draws the mark everywhere: in the app, on the launch screen,
/// and (through `tool/brand_assets_test.dart`) in the icon files.
class BrandPainter extends CustomPainter {
  /// Dark gradient plate behind the mark; without it only the mark is drawn.
  final bool plate;

  /// Rounded plate corners. Icon files are full squares the system masks.
  final bool rounded;

  /// Scale of the mark inside the plate (icon safe zones use less than 1).
  final double scale;

  const BrandPainter({this.plate = true, this.rounded = true, this.scale = 1});

  static const _ink = [Color(0xFF2A2E5C), Color(0xFF15172E), Color(0xFF0B0C14)];
  static const _ring = [
    AppPalette.violet,
    AppPalette.blue,
    AppPalette.cyan,
    AppPalette.teal,
    AppPalette.lime,
    AppPalette.lime,
  ];

  /// Opening of the ring above the dumbbell, in radians.
  static const _gap = 0.98;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Offset.zero & Size(side, side);
    if (plate) _paintPlate(canvas, rect);
    final u = side / 100 * scale;
    canvas
      ..save()
      ..translate(side / 2 - 50 * u, side / 2 - 50 * u);
    _paintMark(canvas, u);
    canvas.restore();
  }

  void _paintPlate(Canvas canvas, Rect rect) {
    final shape = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rounded ? rect.width * 0.225 : 0),
    );
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _ink,
            stops: [0, 0.55, 1],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.75, -0.85),
            radius: 0.95,
            colors: [
              AppPalette.violet.withValues(alpha: 0.5),
              AppPalette.violet.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0.85, 0.95),
            radius: 0.85,
            colors: [
              AppPalette.teal.withValues(alpha: 0.34),
              AppPalette.teal.withValues(alpha: 0),
            ],
          ).createShader(rect),
      )
      ..restore();
  }

  void _paintMark(Canvas canvas, double u) {
    final center = Offset(50 * u, 50 * u);
    final ring = Rect.fromCircle(center: center, radius: 26 * u);
    const sweep = math.pi * 2 - _gap;
    Paint arc(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: _ring,
        stops: [0, 0.2, 0.42, 0.6, 0.8, 1],
        // The color seam sits in the middle of the opening.
        transform: GradientRotation(-_gap / 2),
      ).createShader(ring);
    // Dumbbell docked inside the ring: its handle is the bar of the "G".
    RRect bar(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * u, y * u, w * u, h * u),
          Radius.circular(math.min(w, h) / 2 * u),
        );
    final steel = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFD5DAF0)],
      ).createShader(Rect.fromLTWH(0, 36 * u, 100 * u, 28 * u));
    canvas
      // Soft colored glow under the ring.
      ..drawArc(
        ring,
        0,
        sweep,
        false,
        arc(11 * u)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * u)
          ..color = const Color(0x8CFFFFFF),
      )
      // The ring is drawn over the handle, so the handle ends under it.
      ..drawRRect(bar(44, 46, 31, 8), steel)
      ..drawArc(ring, 0, sweep, false, arc(11 * u))
      ..drawRRect(bar(41, 36.5, 8, 27), steel)
      ..drawRRect(bar(32.5, 42.5, 6, 15), steel);
  }

  @override
  bool shouldRepaint(BrandPainter old) =>
      old.plate != plate || old.rounded != rounded || old.scale != scale;
}
