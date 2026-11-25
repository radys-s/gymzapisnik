import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'brand.dart';
import 'motion.dart';
import 'tokens.dart';

/// A single, finite brand entrance. The same mark as the installed icon,
/// surrounded by quiet calibration rings rather than a looping decoration.
class BrandStage extends StatefulWidget {
  final double height;
  const BrandStage({super.key, this.height = 196});

  @override
  State<BrandStage> createState() => _BrandStageState();
}

class _BrandStageState extends State<BrandStage>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.on(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = Motion.curve.transform(_controller.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StagePainter(t, context.palette.accent),
                  ),
                ),
                Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - t)),
                    child: Transform.rotate(
                      angle: -0.08 * (1 - t),
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * t,
                        child: const SizedBox.square(
                          dimension: 88,
                          child: CustomPaint(painter: BrandPainter()),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _StagePainter extends CustomPainter {
  final double progress;
  final Color accent;
  _StagePainter(this.progress, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width * 0.4, size.height * 0.44);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final factor in [0.83, 1.0]) {
      canvas.drawCircle(
        center,
        radius * factor,
        stroke..color = accent.withValues(alpha: 0.07 * progress),
      );
    }
    final arc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 1.35 * progress,
      false,
      stroke
        ..color = Colors.white
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [
            accent.withValues(alpha: 0.02),
            accent.withValues(alpha: 0.38 * progress),
          ],
        ).createShader(arc),
    );
    stroke.shader = null;
    for (var i = 0; i < 24; i++) {
      final angle = math.pi * 2 * i / 24;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius + 6),
        center + direction * (radius + (i % 6 == 0 ? 13 : 9)),
        stroke
          ..color = accent.withValues(
            alpha: (i % 6 == 0 ? 0.28 : 0.1) * progress,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) =>
      old.progress != progress || old.accent != accent;
}
