import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/ambient.dart';
import '../design/tokens.dart';
import '../widgets/labels.dart';
import '../program/program_widgets.dart' show weekdayLong;

/// Decorative, cached glyphs drift a few pixels at eight frames per second.
/// This layer never rebuilds Home's data or participates in input/semantics.
class HomeTechnicalBackground extends StatefulWidget {
  const HomeTechnicalBackground({super.key});

  @override
  State<HomeTechnicalBackground> createState() =>
      _HomeTechnicalBackgroundState();
}

class _HomeTechnicalBackgroundState extends State<HomeTechnicalBackground> {
  Color? _color;
  List<TextPainter> _glyphs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final color = context.palette.label.withValues(alpha: 0.045);
    if (_color == color) return;
    for (final glyph in _glyphs) {
      glyph.dispose();
    }
    _glyphs = [];
    _color = color;
    for (final symbol in ['+', '·', '/', ':', '[', ']', '_', '01']) {
      _glyphs.add(
        TextPainter(
          text: TextSpan(
            text: symbol,
            style: TextStyle(
              fontFamily: technicalFont,
              fontSize: 10,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
    }
  }

  @override
  void dispose() {
    for (final glyph in _glyphs) {
      glyph.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AmbientBuilder(
          fps: 8,
          builder: (context, seconds, _) => CustomPaint(
            painter: _TechnicalPainter(
              _glyphs,
              seconds ?? 0,
              context.palette.accent,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    ),
  );
}

class _TechnicalPainter extends CustomPainter {
  final List<TextPainter> glyphs;
  final double seconds;
  final Color accent;
  _TechnicalPainter(this.glyphs, this.seconds, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    if (glyphs.isEmpty) return;
    final drift = math.sin(seconds / 14) * 4;
    for (var row = 0; row * 54 < size.height + 54; row++) {
      for (var col = 0; col * 48 < size.width; col++) {
        if ((row * 7 + col * 3) % 5 == 0) continue;
        final glyph = glyphs[(row * 13 + col * 7) % glyphs.length];
        glyph.paint(canvas, Offset(col * 48 + 16, row * 54 + 12 + drift));
      }
    }
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final y = size.height * (0.24 + 0.015 * math.sin(seconds / 18));
    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), stroke);
    for (final x in [12.0, size.width - 12]) {
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), stroke);
    }
  }

  @override
  bool shouldRepaint(_TechnicalPainter old) =>
      old.seconds != seconds ||
      old.accent != accent ||
      !identical(old.glyphs, glyphs);
}

/// The workout is the main module, with a hairline frame and corner marks.
class HomeConsoleSurface extends StatelessWidget {
  final Widget child;
  const HomeConsoleSurface({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.grouped,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.accent.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: AmbientBuilder(
        fps: 8,
        child: RepaintBoundary(
          child: Padding(padding: const EdgeInsets.all(Space.l), child: child),
        ),
        builder: (_, seconds, child) => CustomPaint(
          foregroundPainter: _ConsoleCorners(p.accent, seconds),
          child: child,
        ),
      ),
    );
  }
}

class _ConsoleCorners extends CustomPainter {
  final Color color;
  final double? seconds;
  _ConsoleCorners(this.color, this.seconds);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5;
    for (final origin in [
      const Offset(8, 8),
      Offset(size.width - 8, size.height - 8),
    ]) {
      final direction = origin.dx < size.width / 2 ? 1.0 : -1.0;
      canvas.drawLine(origin, origin + Offset(0, 6 * direction), stroke);
      canvas.drawLine(origin, origin + Offset(6 * direction, 0), stroke);
    }
    // A two-second edge sweep, then twelve seconds of rest. It stays
    // outside the text area and vanishes entirely when motion is off.
    final time = seconds;
    if (time != null && time % 14 < 2 && size.width > 64) {
      final phase = (time % 14) / 2;
      final x = 24 + (size.width - 64) * phase;
      canvas.drawLine(
        Offset(x, 0.5),
        Offset(x + 20, 0.5),
        stroke
          ..color = color.withValues(alpha: math.sin(math.pi * phase) * 0.32),
      );
    }
  }

  @override
  bool shouldRepaint(_ConsoleCorners old) =>
      old.color != color || old.seconds != seconds;
}

class HomeSystemLine extends StatelessWidget {
  final DateTime now;
  final int workouts;
  const HomeSystemLine({super.key, required this.now, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontFamily: technicalFont,
      fontSize: 10,
      letterSpacing: 0.6,
      color: context.palette.secondaryLabel,
    );
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs, bottom: Space.m),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: Space.m,
        runSpacing: Space.xs,
        children: [
          Text(
            '// ${weekdayLong[now.weekday - 1].toUpperCase()} · ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}',
            semanticsLabel:
                '${weekdayLong[now.weekday - 1]}, ${now.day}.${now.month}.',
            style: style,
          ),
          Text(workoutsLabel(workouts).toUpperCase(), style: style),
        ],
      ),
    );
  }
}
