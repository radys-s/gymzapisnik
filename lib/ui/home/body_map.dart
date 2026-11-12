import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../coach/recovery.dart';
import '../design/tokens.dart';

/// Oranžová pro partie, které ještě regenerují.
const recoveringColor = Color(0xFFFF9F0A);

/// Tvar v souřadnicích postavy 120 × 260.
class _Shape {
  final double l, t, w, h;
  final double radius;
  const _Shape(this.l, this.t, this.w, this.h, [this.radius = 8]);

  Rect get rect => Rect.fromLTWH(l, t, w, h);
}

/// Tělo bez partií (hlava, krk, trup, ruce, nohy).
const _body = [
  _Shape(46, 6, 28, 28, 14),
  _Shape(54, 30, 12, 14, 4),
  _Shape(32, 42, 56, 94, 18),
  _Shape(15, 46, 17, 56, 9),
  _Shape(88, 46, 17, 56, 9),
  _Shape(11, 98, 15, 50, 8),
  _Shape(94, 98, 15, 50, 8),
  _Shape(35, 128, 50, 26, 12),
  _Shape(35, 148, 24, 62, 11),
  _Shape(61, 148, 24, 62, 11),
  _Shape(37, 206, 20, 48, 9),
  _Shape(63, 206, 20, 48, 9),
];

/// Partie zepředu: id partie -> tvary.
const _front = {
  'shoulders': [_Shape(23, 43, 22, 19, 10), _Shape(75, 43, 22, 19, 10)],
  'chest': [_Shape(36, 52, 23, 24, 9), _Shape(61, 52, 23, 24, 9)],
  'biceps': [_Shape(17, 64, 13, 30, 7), _Shape(90, 64, 13, 30, 7)],
  'core': [_Shape(44, 80, 32, 48, 9)],
  'legs': [_Shape(37, 154, 20, 50, 9), _Shape(63, 154, 20, 50, 9)],
  'calves': [_Shape(40, 214, 14, 32, 7), _Shape(66, 214, 14, 32, 7)],
};

/// Partie zezadu.
const _back = {
  'shoulders': [_Shape(23, 43, 22, 19, 10), _Shape(75, 43, 22, 19, 10)],
  'back': [_Shape(38, 50, 44, 60, 14)],
  'triceps': [_Shape(17, 62, 13, 32, 7), _Shape(90, 62, 13, 32, 7)],
  'glutes': [_Shape(37, 128, 22, 26, 11), _Shape(61, 128, 22, 26, 11)],
  'legs': [_Shape(37, 158, 20, 46, 9), _Shape(63, 158, 20, 46, 9)],
  'calves': [_Shape(39, 210, 18, 36, 8), _Shape(63, 210, 18, 36, 8)],
};

/// Barva partie: zelená odpočatá, oranžová tím sytější, čím čerstvěji
/// odcvičená.
Color recoveryColor(FocusRecovery? r, AppPalette p) {
  if (r == null) return p.tertiaryLabel.withValues(alpha: 0.35);
  if (r.isReady) return p.positive.withValues(alpha: 0.75);
  return recoveringColor.withValues(
    alpha: 0.6 + 0.4 * (1 - r.ready.clamp(0.0, 1.0)),
  );
}

/// Postava zepředu a zezadu obarvená podle regenerace. Klepnutí na partii
/// volá [onTap] s id partie.
class BodyMap extends StatelessWidget {
  final Map<String, FocusRecovery> recovery;
  final Map<String, String> names;
  final String Function(FocusRecovery r) status;
  final void Function(String focusId) onTap;
  const BodyMap({
    super.key,
    required this.recovery,
    required this.names,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    // Partie na obou postavách čte čtečka jen jednou (zepředu).
    Widget figure(
      String label,
      Map<String, List<_Shape>> parts, {
      Set<String> silent = const {},
    }) => Expanded(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 120 / 260,
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = box.maxWidth / 120;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BodyPainter(
                          parts: parts,
                          colors: {
                            for (final id in parts.keys)
                              id: recoveryColor(recovery[id], p),
                          },
                          body: p.fill,
                        ),
                      ),
                    ),
                    // Klikací plochy; pro čtečku každá partie jako tlačítko.
                    for (final MapEntry(key: id, value: shapes)
                        in parts.entries)
                      for (final (i, s) in shapes.indexed)
                        Positioned(
                          // Plocha klepnutí o kus větší než tvar.
                          left: (s.l - 4) * scale,
                          top: (s.t - 4) * scale,
                          width: (s.w + 8) * scale,
                          height: (s.h + 8) * scale,
                          child: i == 0 && !silent.contains(id)
                              ? Semantics(
                                  button: true,
                                  label: [
                                    names[id] ?? id,
                                    if (recovery[id] case final r?) status(r),
                                  ].join(', '),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(id),
                                  ),
                                )
                              : ExcludeSemantics(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(id),
                                  ),
                                ),
                        ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Space.xs),
          ExcludeSemantics(
            child: Text(
              label,
              style: text.labelMedium?.copyWith(color: p.secondaryLabel),
            ),
          ),
        ],
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          figure('Zepředu', _front),
          const SizedBox(width: Space.l),
          figure('Zezadu', _back, silent: _front.keys.toSet()),
        ],
      ),
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Map<String, List<_Shape>> parts;
  final Map<String, Color> colors;
  final Color body;
  _BodyPainter({required this.parts, required this.colors, required this.body});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final base = Paint()..color = body;
    for (final s in _body) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(s.rect, Radius.circular(s.radius)),
        base,
      );
    }
    for (final MapEntry(key: id, value: shapes) in parts.entries) {
      final paint = Paint()..color = colors[id] ?? body;
      for (final s in shapes) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(s.rect, Radius.circular(s.radius)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) =>
      !mapEquals(old.colors, colors) ||
      old.body != body ||
      !identical(old.parts, parts);
}

/// Partie, které jsou vidět jen zezadu.
const _backOnly = {'back', 'triceps', 'glutes'};

/// Výřez postavy kolem jedné partie: partie svítí podle [lit] (0–1),
/// zbytek těla je tlumený. Pro dlaždice výběru partií.
class MuscleSilhouette extends StatelessWidget {
  final String focusId;

  /// 0 = nevybráno (šedá), 1 = vybráno (barva motivu).
  final double lit;
  const MuscleSilhouette({super.key, required this.focusId, this.lit = 0});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final back = _backOnly.contains(focusId);
    final shapes = (back ? _back : _front)[focusId] ?? const <_Shape>[];
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _FocusPainter(
          shapes: shapes,
          body: p.fill,
          off: p.tertiaryLabel.withValues(alpha: 0.45),
          on: p.accent,
          lit: lit.clamp(0.0, 1.0),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _FocusPainter extends CustomPainter {
  final List<_Shape> shapes;
  final Color body, off, on;
  final double lit;
  _FocusPainter({
    required this.shapes,
    required this.body,
    required this.off,
    required this.on,
    required this.lit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (shapes.isEmpty || size.isEmpty) return;
    // Výřez kolem partie s kusem okolního těla.
    var focus = shapes.first.rect;
    for (final s in shapes.skip(1)) {
      focus = focus.expandToInclude(s.rect);
    }
    final side = (focus.longestSide + 36).clamp(56.0, 140.0);
    final scale = size.shortestSide / side;
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-focus.center.dx, -focus.center.dy);
    final base = Paint()..color = body;
    for (final s in _body) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(s.rect, Radius.circular(s.radius)),
        base,
      );
    }
    final paint = Paint()..color = Color.lerp(off, on, lit)!;
    for (final s in shapes) {
      final r = RRect.fromRectAndRadius(s.rect, Radius.circular(s.radius));
      // Jemná záře kolem vybrané partie.
      if (lit > 0.01) {
        canvas.drawRRect(
          r.inflate(2.5 * lit),
          Paint()
            ..color = on.withValues(alpha: 0.28 * lit)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * lit),
        );
      }
      canvas.drawRRect(r, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FocusPainter old) =>
      old.lit != lit ||
      old.body != body ||
      old.on != on ||
      old.off != off ||
      !identical(old.shapes, shapes);
}
