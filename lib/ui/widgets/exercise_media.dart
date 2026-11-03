import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../domain/movement.dart';
import '../design/tokens.dart';

/// Malý náhled cviku do seznamů: figurka v konečné poloze.
/// Vlastní cvik bez pohybového vzoru má ikonu činky.
class ExerciseThumb extends StatelessWidget {
  final String exerciseId;
  final double size;
  const ExerciseThumb(this.exerciseId, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final exercise = findExercise(exerciseId, const []);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        alignment: Alignment.center,
        child: exercise == null || exercise.pattern.isEmpty
            ? Icon(
                Icons.fitness_center_rounded,
                size: size * 0.5,
                color: p.secondaryLabel,
              )
            : CustomPaint(
                size: Size.square(size),
                painter: FigurePainter(
                  movementFor(exercise.pattern),
                  exercise.equipment,
                  1,
                  FigureColors.of(p),
                  thumb: true,
                ),
              ),
      ),
    );
  }
}

/// Figurka na detailu cviku: plynule se hýbe mezi začátkem a koncem
/// pohybu. Při omezeném pohybu stojí v konečné poloze.
class ExerciseAnimation extends StatefulWidget {
  final Exercise exercise;
  const ExerciseAnimation(this.exercise, {super.key});

  @override
  State<ExerciseAnimation> createState() => _ExerciseAnimationState();
}

class _ExerciseAnimationState extends State<ExerciseAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final _t = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_played) {
      _play();
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  bool _played = false;
  int _run = 0;

  /// Pohyb třikrát tam a dvakrát zpět, pak figurka stojí v konečné
  /// poloze. Nekonečná smyčka by rušila při čtení techniky.
  void _play() {
    _played = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    // Starý běh se při přehrání znovu zruší; jeho konec už nic nenastaví.
    final run = ++_run;
    _controller.stop();
    _controller.value = 0;
    _controller.repeat(reverse: true, count: 5).whenCompleteOrCancel(() {
      if (mounted && run == _run) _controller.value = 1;
    });
  }

  @override
  void dispose() {
    _t.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final movement = movementFor(widget.exercise.pattern);
    return Semantics(
      label: 'Figurka ukazuje pohyb cviku ${widget.exercise.name}',
      image: true,
      button: true,
      hint: 'Klepnutím přehraješ pohyb znovu',
      onTap: _play,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: _play,
        child: Container(
          decoration: ShapeDecoration(color: p.grouped, shape: p.cardShape()),
          padding: const EdgeInsets.all(Space.m),
          constraints: const BoxConstraints(maxHeight: 280),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _t,
                builder: (_, _) => CustomPaint(
                  painter: FigurePainter(
                    movement,
                    widget.exercise.equipment,
                    _t.value,
                    FigureColors.of(p),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FigureColors {
  final Color body, far, prop, gear, floor;
  const FigureColors(this.body, this.far, this.prop, this.gear, this.floor);

  @override
  bool operator ==(Object other) =>
      other is FigureColors &&
      other.body == body &&
      other.far == far &&
      other.prop == prop &&
      other.gear == gear &&
      other.floor == floor;

  @override
  int get hashCode => Object.hash(body, far, prop, gear, floor);

  factory FigureColors.of(AppPalette p) => FigureColors(
    p.label,
    p.tertiaryLabel,
    p.secondaryLabel.withValues(alpha: 0.55),
    p.accent,
    p.separator,
  );
}

/// Poloha s dopočítanými klouby, v souřadnicích pohybu.
class _Joints {
  final Pt hip, shoulder, head;
  final List<(Pt hip, Pt knee, Pt ankle)> legs;
  final List<(Pt shoulder, Pt elbow, Pt hand)> arms;

  /// Index vzdálenější nohy a ruky ze strany (kreslí se tlumeně).
  final int? farLeg, farArm;
  const _Joints(
    this.hip,
    this.shoulder,
    this.head,
    this.legs,
    this.arms,
    this.farLeg,
    this.farArm,
  );
}

Pt _norm(Pt v) {
  final l = v.length;
  return l == 0 ? const Pt(0, -1) : v * (1 / l);
}

double _dot(Pt a, Pt b) => a.x * b.x + a.y * b.y;

/// Prostřední kloub dvoučlánkové končetiny z [a] do [b] s délkami
/// [l1] a [l2]. Ohyb na stranu, kam míří [bend].
Pt _ik(Pt a, Pt b, double l1, double l2, Pt bend) {
  final d = b - a;
  final dist = d.length;
  if (dist < (l1 - l2).abs() + 0.01) return a + _norm(d) * l1;
  if (dist >= l1 + l2 - 0.01 || dist == 0) {
    return a + _norm(d) * (l1 * math.min(1, dist / (l1 + l2)).toDouble());
  }
  final along = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist);
  final h = math.sqrt(math.max(0, l1 * l1 - along * along));
  final u = _norm(d);
  var perp = Pt(-u.y, u.x);
  if (_dot(perp, bend) < 0) perp = perp * -1;
  return a + u * along + perp * h;
}

Pt _lerp(Pt a, Pt b, double t) => Pt.lerp(a, b, t);
Pt? _lerpN(Pt? a, Pt? b, double t) =>
    a == null || b == null ? (t < 0.5 ? a : b) : Pt.lerp(a, b, t);

_Joints _solve(Movement m, double t) {
  final s = m.start, e = m.end;
  Pt hand(Pose p) => p.handRel ? p.shoulder + p.hand : p.hand;
  Pt? hand2(Pose p) =>
      p.hand2 == null ? null : (p.handRel ? p.shoulder + p.hand2! : p.hand2);
  final hip = _lerp(s.hip, e.hip, t);
  final sh = _lerp(s.shoulder, e.shoulder, t);
  final ankle = _lerp(s.ankle, e.ankle, t);
  final ankle2 = _lerpN(s.ankle2, e.ankle2, t);
  final h1 = _lerp(hand(s), hand(e), t);
  final h2 = _lerpN(hand2(s), hand2(e), t);
  final pose = t < 0.5 ? s : e;
  final kneeDir = _lerp(s.kneeDir, e.kneeDir, t);
  final elbowDir = _lerp(s.elbowDir, e.elbowDir, t);
  final head = sh + _norm(sh - hip) * 11;

  if (m.view == FigureView.front) {
    const hipW = 5.0, shW = 9.0;
    final hipL = hip - const Pt(hipW, 0), hipR = hip + const Pt(hipW, 0);
    final shL = sh - const Pt(shW, 0), shR = sh + const Pt(shW, 0);
    final a2 = ankle2 ?? ankle.mirror(hip.x);
    final hand2 = h2 ?? h1.mirror(sh.x);
    final kneeL = _lerpN(s.knee, e.knee, t);
    final knee2 = _lerpN(s.knee2, e.knee2, t);
    final mirrorDir = Pt(-kneeDir.x, kneeDir.y);
    return _Joints(
      hip,
      sh,
      head,
      [
        (hipL, kneeL ?? _ik(hipL, ankle, thigh, shin, kneeDir), ankle),
        (
          hipR,
          knee2 ??
              kneeL?.mirror(hip.x) ??
              _ik(hipR, a2, thigh, shin, mirrorDir),
          a2,
        ),
      ],
      [
        (shL, _ik(shL, h1, upperArm, forearm, elbowDir), h1),
        (
          shR,
          _ik(shR, hand2, upperArm, forearm, Pt(-elbowDir.x, elbowDir.y)),
          hand2,
        ),
      ],
      null,
      null,
    );
  }

  final legs = [
    (hip, _ik(hip, ankle, thigh, shin, kneeDir), ankle),
    if (ankle2 != null)
      (hip, _ik(hip, ankle2, thigh, shin, pose.knee2Dir ?? kneeDir), ankle2),
  ];
  final arms = [
    (sh, _ik(sh, h1, upperArm, forearm, elbowDir), h1),
    if (h2 != null) (sh, _ik(sh, h2, upperArm, forearm, elbowDir), h2),
  ];
  return _Joints(
    hip,
    sh,
    head,
    legs,
    arms,
    legs.length > 1 ? 1 : null,
    arms.length > 1 ? 1 : null,
  );
}

/// Kreslí figurku pohybu [movement] v čase [t] (0 začátek, 1 konec)
/// s vybavením [equipment]. Jeden styl pro všechny cviky.
class FigurePainter extends CustomPainter {
  final Movement movement;
  final Equipment equipment;
  final double t;
  final FigureColors colors;

  /// Malý náhled: silnější čáry, bez podlahy.
  final bool thumb;

  FigurePainter(
    this.movement,
    this.equipment,
    this.t,
    this.colors, {
    this.thumb = false,
  });

  /// Výřez, do kterého se vejdou obě polohy, aby figurka při pohybu
  /// neskákala.
  Rect _bounds() {
    final pts = <Pt>[];
    for (final tt in const [0.0, 1.0]) {
      final j = _solve(movement, tt);
      pts.addAll([j.head, j.hip, j.shoulder]);
      for (final l in j.legs) {
        pts.addAll([l.$2, l.$3]);
      }
      for (final a in j.arms) {
        pts.addAll([a.$2, a.$3]);
      }
    }
    for (final pr in movement.props) {
      switch (pr) {
        case Pad(:final a, :final b) || Bar(:final a, :final b):
          pts.addAll([a, b]);
        case Box(:final topLeft, :final bottomRight):
          pts.addAll([topLeft, bottomRight]);
        case AttachedProp():
      }
    }
    var r = Rect.fromLTRB(
      pts.map((p) => p.x).reduce(math.min),
      pts.map((p) => p.y).reduce(math.min),
      pts.map((p) => p.x).reduce(math.max),
      pts.map((p) => p.y).reduce(math.max),
    );
    if (movement.floor) {
      r = r.expandToInclude(Rect.fromLTRB(r.left, r.top, r.right, floorY));
    }
    // Hlava je kruh, ne bod; okraj na čáry a náčiní.
    r = r.inflate(thumb ? 9 : 12);
    // Stejné měřítko napříč cviky: aspoň 100 × 100 bodů.
    final w = math.max(r.width, 100.0), h = math.max(r.height, 100.0);
    return Rect.fromCenter(center: r.center, width: w, height: h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final b = _bounds();
    final scale = math.min(size.width / b.width, size.height / b.height);
    canvas.save();
    canvas.translate(
      (size.width - b.width * scale) / 2 - b.left * scale,
      (size.height - b.height * scale) / 2 - b.top * scale,
    );
    canvas.scale(scale);

    final j = _solve(movement, t);
    final w = thumb ? 7.0 : 5.0;
    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = colors.body;
    Offset o(Pt p) => Offset(p.x, p.y);
    void line(Pt a, Pt b, Paint p) => canvas.drawLine(o(a), o(b), p);

    if (movement.floor && !thumb) {
      line(
        Pt(b.left + 6, floorY + w / 2),
        Pt(b.right - 6, floorY + w / 2),
        stroke(colors.floor, 2),
      );
    }
    _props(canvas, j, stroke, w);

    final body = stroke(colors.body, w);
    final far = stroke(colors.far, w);
    void limb((Pt, Pt, Pt) l, Paint p) {
      canvas.drawPath(
        Path()
          ..moveTo(l.$1.x, l.$1.y)
          ..lineTo(l.$2.x, l.$2.y)
          ..lineTo(l.$3.x, l.$3.y),
        p,
      );
    }

    // Vzdálenější končetiny pod tělem.
    if (j.farLeg != null) limb(j.legs[j.farLeg!], far);
    if (j.farArm != null) limb(j.arms[j.farArm!], far);
    for (var i = 0; i < j.legs.length; i++) {
      if (i != j.farLeg) limb(j.legs[i], body);
    }
    if (movement.view == FigureView.front) {
      line(j.legs[0].$1, j.legs[1].$1, body);
      line(j.arms[0].$1, j.arms[1].$1, body);
    }
    line(j.hip, j.shoulder, body);
    canvas.drawCircle(o(j.head), 6.5, fill);
    _gear(canvas, j, stroke, w);
    for (var i = 0; i < j.arms.length; i++) {
      if (i != j.farArm) limb(j.arms[i], body);
    }
    canvas.restore();
  }

  void _props(
    Canvas canvas,
    _Joints j,
    Paint Function(Color, double) stroke,
    double w,
  ) {
    final pad = stroke(colors.prop, w * 1.2);
    final thin = stroke(colors.prop, w * 0.5);
    Offset o(Pt p) => Offset(p.x, p.y);
    for (final pr in movement.props) {
      switch (pr) {
        case Pad(:final a, :final b, :final leg):
          canvas.drawLine(o(a), o(b), pad);
          if (leg && movement.floor) {
            final mid = Pt.lerp(a, b, 0.5);
            if (mid.y < floorY - 4) {
              canvas.drawLine(o(mid), Offset(mid.x, floorY), thin);
            }
          }
        case Bar(:final a, :final b):
          if (a.x == b.x && a.y == b.y) {
            canvas.drawCircle(o(a), w * 0.6, Paint()..color = colors.prop);
          } else {
            canvas.drawLine(o(a), o(b), stroke(colors.prop, w * 0.7));
          }
        case Box(:final topLeft, :final bottomRight):
          canvas.drawRect(Rect.fromPoints(o(topLeft), o(bottomRight)), thin);
        case AttachedProp(:final kind):
          switch (kind) {
            case Attached.footPlate:
              final leg = j.legs.first;
              final u = _norm(leg.$3 - leg.$1);
              final c = leg.$3 + u * (w * 0.7);
              final n = Pt(-u.y, u.x) * 10;
              canvas.drawLine(o(c - n), o(c + n), pad);
            case Attached.anklePad:
              canvas.drawCircle(
                o(j.legs.first.$3),
                w * 0.9,
                Paint()..color = colors.prop,
              );
            case Attached.ankle2Pad:
              canvas.drawCircle(
                o(j.legs.last.$3),
                w * 0.9,
                Paint()..color = colors.prop,
              );
            case Attached.kneePadsOuter || Attached.kneePadsInner:
              final out = kind == Attached.kneePadsOuter ? -1.0 : 1.0;
              for (final (i, l) in j.legs.indexed) {
                final side = i == 0 ? out : -out;
                final c = l.$2 + Pt(side * w * 1.2, 0);
                canvas.drawLine(
                  o(c - const Pt(0, 6)),
                  o(c + const Pt(0, 6)),
                  pad,
                );
              }
          }
      }
    }
  }

  void _gear(
    Canvas canvas,
    _Joints j,
    Paint Function(Color, double) stroke,
    double w,
  ) {
    final gear = Paint()..color = colors.gear;
    final line = stroke(colors.gear, w * 0.45);
    Offset o(Pt p) => Offset(p.x, p.y);
    final hands = [for (final a in j.arms) a.$3];
    final front = movement.view == FigureView.front;

    // Kladka a guma se kreslí i tam, kde ruce nic nedrží (kotník).
    if (equipment == Equipment.cable) {
      final targets = switch (movement.cableAt) {
        CableAt.hands => hands,
        CableAt.ankle => [j.legs.first.$3],
        CableAt.ankle2 => [j.legs.last.$3],
      };
      for (final (i, target) in targets.indexed) {
        final anchor = front && !movement.singleAnchor && i == 1
            ? movement.cableAnchor.mirror(50)
            : movement.cableAnchor;
        canvas.drawLine(o(anchor), o(target), line);
        canvas.drawCircle(o(anchor), w * 0.7, gear);
        canvas.drawCircle(o(target), w * 0.55, gear);
        if (movement.singleAnchor || !front) break;
      }
      return;
    }
    if (!movement.holds) {
      if (equipment == Equipment.band && j.legs.length == 2) {
        canvas.drawLine(o(j.legs[0].$2), o(j.legs[1].$2), line);
      }
      return;
    }
    if (movement.landmine != null) {
      final h = hands.first;
      final tip = h + _norm(h - movement.landmine!) * 6;
      canvas.drawLine(
        o(movement.landmine!),
        o(tip),
        stroke(colors.gear, w * 0.6),
      );
      canvas.drawCircle(o(tip), w * 1.3, gear);
      return;
    }
    switch (equipment) {
      case Equipment.barbell || Equipment.smith:
        if (equipment == Equipment.smith) {
          final x = front ? hands.first.x - 8 : hands.first.x;
          final rail = stroke(colors.prop, w * 0.35);
          canvas.drawLine(Offset(x, -20), Offset(x, floorY), rail);
          if (front) {
            final x2 = (hands.length > 1 ? hands[1].x : x) + 8;
            canvas.drawLine(Offset(x2, -20), Offset(x2, floorY), rail);
          }
        }
        if (front && hands.length == 2) {
          final a = hands[0] - const Pt(12, 0), c = hands[1] + const Pt(12, 0);
          canvas.drawLine(o(a), o(c), stroke(colors.gear, w * 0.5));
          for (final end in [a, c]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: o(end), width: w * 1.2, height: 16),
                const Radius.circular(1.5),
              ),
              gear,
            );
          }
        } else {
          // Ze strany je osa vidět z čela: kotouč.
          final c = hands.first;
          canvas.drawCircle(o(c), 9, stroke(colors.gear, w * 0.6));
          canvas.drawCircle(o(c), w * 0.45, gear);
        }
      case Equipment.dumbbell:
        for (final h in hands.take(front ? 2 : 1)) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: o(h), width: 12, height: 6.5),
              const Radius.circular(2),
            ),
            gear,
          );
        }
      case Equipment.kettlebell:
        final h = hands.first;
        canvas.drawCircle(o(h + const Pt(0, 6)), 5.5, gear);
        canvas.drawCircle(o(h + const Pt(0, 1)), 2.6, stroke(colors.gear, 1.6));
      case Equipment.plate:
        canvas.drawCircle(o(hands.first), 8, stroke(colors.gear, w * 0.6));
      case Equipment.machine:
        for (final h in hands.take(front ? 2 : 1)) {
          canvas.drawCircle(o(h), w * 0.85, gear);
        }
      case Equipment.band:
        final h = hands.first;
        final foot = j.legs.first.$3;
        canvas.drawLine(o(h), o(Pt(foot.x, foot.y)), line);
      case Equipment.cable || Equipment.bodyweight || Equipment.other:
    }
  }

  @override
  bool shouldRepaint(FigurePainter old) =>
      old.t != t ||
      old.movement != movement ||
      old.equipment != equipment ||
      old.colors != colors;
}
