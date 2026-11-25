import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../domain/anatomy.dart';
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
                  work: bodyPartsOf(exerciseId).work,
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

/// One rep: lift (0.9 s), hold (0.3 s), slow lowering (1.6 s), pause.
const _rep = Duration(milliseconds: 3200);
const _reps = 3;

/// Rep phase boundaries as fractions of [_rep].
const _liftEnd = 0.28, _holdEnd = 0.38, _lowerEnd = 0.88;

/// Pose (0 start, 1 end) at rep progress [x].
double _repPose(double x) {
  if (x < _liftEnd) return Curves.easeOutCubic.transform(x / _liftEnd);
  if (x < _holdEnd) return 1;
  if (x < _lowerEnd) {
    return 1 -
        Curves.easeInOut.transform((x - _holdEnd) / (_lowerEnd - _holdEnd));
  }
  return 0;
}

/// Muscle effort at rep progress [x]: rises through the lift, peaks on
/// the squeeze, eases off while lowering and relaxes in the pause.
double _repEffort(double x) {
  if (x < _liftEnd) {
    return 0.35 + 0.65 * Curves.easeOut.transform(x / _liftEnd);
  }
  if (x < _holdEnd) return 1;
  if (x < _lowerEnd) {
    return 1 - 0.35 * ((x - _holdEnd) / (_lowerEnd - _holdEnd));
  }
  return 0.65 - 0.3 * ((x - _lowerEnd) / (1 - _lowerEnd));
}

String _phase(double x) => x < _liftEnd
    ? tr('Zaber', 'Lift')
    : x < _holdEnd
    ? tr('Zpevni', 'Squeeze')
    : x < _lowerEnd
    ? tr('Pomalu zpět · 2–3 s', 'Lower slowly · 2–3 s')
    : tr('Nádech', 'Breathe');

class _ExerciseAnimationState extends State<ExerciseAnimation>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: _rep * _reps,
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

  /// Three slow reps, then the figure rests in the end pose. An endless
  /// loop would distract while reading the technique.
  void _play() {
    _played = true;
    _controller.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _running => _controller.isAnimating;

  /// Rep progress 0–1 within the current rep.
  double get _x => (_controller.value * _reps) % 1;

  /// Pose for the painter; after the last rep the end pose stays.
  double get _pose => !_running && _controller.value >= 1 ? 1 : _repPose(_x);

  /// Effort for the painter; at rest after the reps the muscles stay lit.
  double get _effort =>
      !_running && _controller.value >= 1 ? 1 : _repEffort(_x);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final movement = movementFor(widget.exercise.pattern);
    final parts = bodyPartsOf(widget.exercise.id);
    final colors = FigureColors.of(p);
    FigurePainter painter(
      double t, {
      bool ghost = false,
      bool thumb = false,
      double effort = 1,
      bool path = false,
    }) => FigurePainter(
      movement,
      widget.exercise.equipment,
      t,
      colors,
      work: parts.work,
      help: parts.help,
      ghost: ghost,
      thumb: thumb,
      effort: effort,
      path: path,
    );
    Widget frame(String label, double t) => Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: CustomPaint(painter: painter(t), size: Size.infinite),
          ),
          Text(
            label,
            style: text.labelSmall?.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
    return Semantics(
      label: tr(
        'Figurka ukazuje pohyb cviku ${widget.exercise.name}',
        'Figure showing the movement of ${widget.exercise.name}',
      ),
      image: true,
      button: true,
      hint: tr('Klepnutím přehraješ pohyb znovu', 'Tap to replay'),
      onTap: _play,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: _play,
        child: Container(
          decoration: ShapeDecoration(color: p.grouped, shape: p.cardShape()),
          padding: const EdgeInsets.all(Space.m),
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, _) => CustomPaint(
                            painter: painter(
                              _pose,
                              ghost: true,
                              effort: _effort,
                              path: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) => Text(
                          _running
                              ? '${tr('Opakování', 'Rep')} '
                                    '${(_controller.value * _reps).floor() + 1}/$_reps'
                              : tr('Klepni pro přehrání', 'Tap to replay'),
                          style: text.labelSmall?.copyWith(
                            color: p.secondaryLabel,
                            fontFeatures: tabular,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.replay_rounded,
                        size: 18,
                        color: p.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _controller,
                builder: (_, _) => Text(
                  _running ? _phase(_x) : ' ',
                  style: text.titleSmall?.copyWith(color: p.accent),
                ),
              ),
              const SizedBox(height: 6),
              ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) => _TempoStrip(x: _running ? _x : null),
                ),
              ),
              const SizedBox(height: Space.s),
              Row(
                children: [
                  frame(tr('Začátek', 'Start'), 0),
                  frame(tr('Konec', 'End'), 1),
                  Expanded(child: _Legend(work: parts.work.isNotEmpty)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One rep as a timeline: lift, squeeze, slow lowering, pause. The
/// current phase is lit and a cursor runs along it. [x] is `null` when
/// nothing plays.
class _TempoStrip extends StatelessWidget {
  final double? x;
  const _TempoStrip({required this.x});

  static const _parts = [
    (0.0, _liftEnd),
    (_liftEnd, _holdEnd),
    (_holdEnd, _lowerEnd),
    (_lowerEnd, 1.0),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final labels = [
      tr('Zaber', 'Lift'),
      tr('Zpevni', 'Squeeze'),
      tr('Pomalu zpět', 'Lower slowly'),
      tr('Nádech', 'Breathe'),
    ];
    final now = x;
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) => SizedBox(
            height: 10,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    for (final (i, (a, b)) in _parts.indexed) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        flex: ((b - a) * 100).round(),
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: now != null && now >= a && now < b
                                ? p.accent
                                : now != null && now >= b
                                ? p.accent.withValues(alpha: 0.35)
                                : p.fill,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (now != null)
                  Positioned(
                    left: (box.maxWidth * now - 1.5).clamp(0, box.maxWidth - 3),
                    top: 0,
                    child: Container(
                      width: 3,
                      height: 10,
                      decoration: BoxDecoration(
                        color: p.label,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final (i, (a, b)) in _parts.indexed)
              Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: text.labelSmall?.copyWith(
                    color: now != null && now >= a && now < b
                        ? p.label
                        : p.tertiaryLabel,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// What the orange means.
class _Legend extends StatelessWidget {
  final bool work;
  const _Legend({required this.work});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: p.secondaryLabel);
    Widget row(Color c, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: style)),
      ],
    );
    if (!work) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(p.accent, tr('Pracuje', 'Works')),
        const SizedBox(height: 4),
        row(Color.lerp(p.label, p.accent, 0.5)!, tr('Pomáhá', 'Helps')),
      ],
    );
  }
}

class FigureColors {
  final Color body, far, prop, gear, floor;

  /// Working muscles; helpers get a mix of this and the body colour.
  final Color work;

  /// Background behind the figure: a thin cut-out edge in this colour
  /// keeps near and far limbs apart.
  final Color edge;
  const FigureColors(
    this.body,
    this.far,
    this.prop,
    this.gear,
    this.floor, {
    this.work = const Color(0xFFFF6B2C),
    this.edge = const Color(0xFF000000),
  });

  @override
  bool operator ==(Object other) =>
      other is FigureColors &&
      other.body == body &&
      other.far == far &&
      other.prop == prop &&
      other.gear == gear &&
      other.floor == floor &&
      other.work == work &&
      other.edge == edge;

  @override
  int get hashCode => Object.hash(body, far, prop, gear, floor, work, edge);

  /// Equipment is neutral so the accent marks only the working muscles.
  factory FigureColors.of(AppPalette p) => FigureColors(
    p.label,
    p.tertiaryLabel,
    p.secondaryLabel.withValues(alpha: 0.45),
    p.secondaryLabel,
    p.separator,
    work: p.accent,
    edge: p.grouped,
  );
}

/// Body parts the figure can light up.
enum BodyPart {
  chest,
  back,
  core,
  shoulders,
  upperArms,
  forearms,
  glutes,
  thighs,
  calves,
}

BodyPart _partOf(String head) => switch (head) {
  'chest_upper' || 'chest_mid' => BodyPart.chest,
  'lats' || 'upper_back' || 'lower_back' => BodyPart.back,
  'abs' || 'abs_lower' || 'obliques' => BodyPart.core,
  'delt_front' || 'delt_side' || 'delt_rear' => BodyPart.shoulders,
  'forearms' => BodyPart.forearms,
  'glutes' || 'glutes_med' => BodyPart.glutes,
  'quads' || 'hamstrings' || 'adductors' => BodyPart.thighs,
  'calves_gastro' || 'calves_soleus' => BodyPart.calves,
  _ => BodyPart.upperArms,
};

/// Working and helping body parts of a catalog exercise (empty for
/// custom exercises without anatomy).
({Set<BodyPart> work, Set<BodyPart> help}) bodyPartsOf(String exerciseId) {
  final a = anatomyOf(exerciseId);
  if (a == null) return (work: const {}, help: const {});
  final work = {for (final h in a.primary) _partOf(h)};
  return (
    work: work,
    help: {
      for (final h in a.secondary)
        if (!work.contains(_partOf(h))) _partOf(h),
    },
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

  /// Body parts drawn in the accent (working) or half accent (helping).
  final Set<BodyPart> work, help;

  /// Faint start pose behind the figure: shows the range of motion.
  final bool ghost;

  /// How hard the muscles work right now (0 relaxed, 1 full squeeze):
  /// working muscles brighten and swell with it.
  final double effort;

  /// Dotted path of the bar (or hands, or foot) from start to end, with
  /// a dot where it is now.
  final bool path;

  FigurePainter(
    this.movement,
    this.equipment,
    this.t,
    this.colors, {
    this.thumb = false,
    this.work = const {},
    this.help = const {},
    this.ghost = false,
    this.effort = 1,
    this.path = false,
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
    // Detail view fills its frame; thumbs keep one scale across exercises.
    final side = thumb ? 100.0 : 72.0;
    final w = math.max(r.width, side), h = math.max(r.height, side);
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
    if (movement.floor && !thumb) _shadows(canvas, j);
    if (path && !thumb) _path(canvas);

    if (ghost && !thumb) _body(canvas, _solve(movement, 0), w, faint: true);
    _body(canvas, j, w);
    _gear(canvas, j, stroke, w);
    // Near arms over the gear, so the hand grips the bar.
    _arms(canvas, j, w, near: true);
    canvas.restore();
  }

  /// Colour of a body part: working, helping or plain. Working parts
  /// follow [effort]: dimmer when relaxed, full accent on the squeeze.
  Color _tone(BodyPart part, {bool far = false, bool faint = false}) {
    if (faint) return colors.far.withValues(alpha: 0.22);
    final base = far ? colors.far : colors.body;
    final hot = far ? Color.lerp(colors.far, colors.work, 0.6)! : colors.work;
    final e = 0.45 + 0.55 * effort.clamp(0.0, 1.0);
    if (work.contains(part)) return Color.lerp(base, hot, e)!;
    if (help.contains(part)) return Color.lerp(base, hot, 0.5 * e)!;
    return base;
  }

  /// Tapered limbs and a thick torso. Thumbnails keep thinner volumes.
  double get _k => thumb ? 0.75 : 1.0;

  /// Scale of all body radii for this stroke width.
  double _f(double w) => w / 5 * _k;

  /// Width of the cut-out edge around each limb.
  static const _edgeW = 1.1;

  /// A limb segment as a tapered capsule: radius [r1] at [a], [r2] at [b].
  void _capsule(Canvas canvas, Pt a, Pt b, double r1, double r2, Color c) {
    final paint = Paint()..color = c;
    final d = b - a;
    final len = d.length;
    canvas.drawCircle(Offset(a.x, a.y), r1, paint);
    canvas.drawCircle(Offset(b.x, b.y), r2, paint);
    if (len < 0.01) return;
    final u = d * (1 / len);
    final n = Pt(-u.y, u.x);
    final path = Path()
      ..moveTo(a.x + n.x * r1, a.y + n.y * r1)
      ..lineTo(b.x + n.x * r2, b.y + n.y * r2)
      ..lineTo(b.x - n.x * r2, b.y - n.y * r2)
      ..lineTo(a.x - n.x * r1, a.y - n.y * r1)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// A muscle belly drawn over the segment [a]–[b], between fractions
  /// [from] and [to], when [part] works or helps. Working bellies swell
  /// a little with effort.
  void _belly(
    Canvas canvas,
    BodyPart part,
    Pt a,
    Pt b,
    double from,
    double to,
    double r1,
    double r2, {
    bool far = false,
    bool faint = false,
  }) {
    if (faint || !(work.contains(part) || help.contains(part))) return;
    final swell = work.contains(part) ? 1 + 0.12 * effort.clamp(0.0, 1.0) : 1;
    _capsule(
      canvas,
      Pt.lerp(a, b, from),
      Pt.lerp(a, b, to),
      r1 * swell,
      r2 * swell,
      _tone(part, far: far),
    );
  }

  Color _plain({bool far = false, bool faint = false}) => faint
      ? colors.far.withValues(alpha: 0.22)
      : far
      ? colors.far
      : colors.body;

  void _leg(Canvas canvas, (Pt, Pt, Pt) l, double w, bool far, bool faint) {
    final f = _f(w);
    final c = _plain(far: far, faint: faint);
    final (hip, knee, ankle) = l;
    _capsule(canvas, hip, knee, 4.6 * f, 3.0 * f, c);
    _capsule(canvas, knee, ankle, 3.0 * f, 1.9 * f, c);
    // Foot points forward, at a right angle to the shin.
    final u = _norm(ankle - knee);
    // From the front the foot is seen toe-on: a short stub.
    final toe = movement.view == FigureView.front
        ? ankle + u * (1.5 * f)
        : ankle + Pt(u.y, -u.x) * (5.5 * f);
    _capsule(canvas, ankle, toe, 1.9 * f, 1.4 * f, c);
    _belly(
      canvas,
      BodyPart.thighs,
      hip,
      knee,
      0.1,
      0.78,
      4.1 * f,
      2.7 * f,
      far: far,
      faint: faint,
    );
    _belly(
      canvas,
      BodyPart.calves,
      knee,
      ankle,
      0.12,
      0.62,
      2.9 * f,
      2.0 * f,
      far: far,
      faint: faint,
    );
  }

  void _arm(Canvas canvas, (Pt, Pt, Pt) a, double w, bool far, bool faint) {
    final f = _f(w);
    final (sh, elbow, hand) = a;
    for (final edge in [!faint, false]) {
      final c = edge ? colors.edge : _plain(far: far, faint: faint);
      final g = edge ? _edgeW * f : 0.0;
      _capsule(canvas, sh, elbow, 3.3 * f + g, 2.3 * f + g, c);
      _capsule(canvas, elbow, hand, 2.3 * f + g, 1.6 * f + g, c);
      canvas.drawCircle(
        Offset(hand.x, hand.y),
        2.2 * f + g,
        Paint()..color = c,
      );
    }
    // Delt cap over the top of the arm.
    _belly(
      canvas,
      BodyPart.shoulders,
      sh,
      elbow,
      0,
      0.18,
      3.9 * f,
      3.5 * f,
      far: far,
      faint: faint,
    );
    _belly(
      canvas,
      BodyPart.upperArms,
      sh,
      elbow,
      0.15,
      0.8,
      3.0 * f,
      2.3 * f,
      far: far,
      faint: faint,
    );
    _belly(
      canvas,
      BodyPart.forearms,
      elbow,
      hand,
      0.08,
      0.55,
      2.3 * f,
      1.7 * f,
      far: far,
      faint: faint,
    );
  }

  void _arms(Canvas canvas, _Joints j, double w, {required bool near}) {
    for (var i = 0; i < j.arms.length; i++) {
      if (i != j.farArm) _arm(canvas, j.arms[i], w, false, false);
    }
  }

  void _body(Canvas canvas, _Joints j, double w, {bool faint = false}) {
    final f = _f(w);
    if (j.farLeg != null) _leg(canvas, j.legs[j.farLeg!], w, true, faint);
    if (j.farArm != null) _arm(canvas, j.arms[j.farArm!], w, true, faint);
    for (var i = 0; i < j.legs.length; i++) {
      if (i != j.farLeg) _leg(canvas, j.legs[i], w, false, faint);
    }
    final plain = _plain(faint: faint);
    final front = movement.view == FigureView.front;
    final mid = Pt.lerp(j.hip, j.shoulder, 0.45);
    final upper = work.contains(BodyPart.chest) || work.contains(BodyPart.back)
        ? (work.contains(BodyPart.chest) ? BodyPart.chest : BodyPart.back)
        : help.contains(BodyPart.chest)
        ? BodyPart.chest
        : BodyPart.back;
    // Neck, then head: the head sits a little off the shoulders.
    final neckTop = Pt.lerp(j.shoulder, j.head, 0.55);
    final headR = 7.0 * (thumb ? 0.9 : 1);
    void trunk(Color c, double g) {
      _capsule(canvas, j.shoulder, neckTop, 2.4 * f + g, 2.0 * f + g, c);
      if (front) {
        _capsule(
          canvas,
          j.legs[0].$1,
          j.legs[1].$1,
          4.4 * f + g,
          4.4 * f + g,
          c,
        );
        _capsule(canvas, j.hip, j.shoulder, 5.6 * f + g, 7.2 * f + g, c);
        _capsule(
          canvas,
          j.arms[0].$1,
          j.arms[1].$1,
          3.4 * f + g,
          3.4 * f + g,
          c,
        );
      } else {
        _capsule(canvas, j.hip, j.shoulder, 5.0 * f + g, 6.2 * f + g, c);
      }
      canvas.drawCircle(
        Offset(j.head.x, j.head.y),
        headR + g,
        Paint()..color = c,
      );
    }

    if (!faint) trunk(colors.edge, _edgeW * f);
    trunk(plain, 0);
    if (front) {
      final hipL = j.legs[0].$1, hipR = j.legs[1].$1;
      _belly(
        canvas,
        BodyPart.core,
        j.hip,
        mid,
        0.0,
        1.0,
        3.6 * f,
        3.8 * f,
        faint: faint,
      );
      _belly(
        canvas,
        upper,
        mid,
        j.shoulder,
        0.25,
        0.85,
        4.8 * f,
        5.4 * f,
        faint: faint,
      );
      _belly(
        canvas,
        BodyPart.glutes,
        hipL,
        hipR,
        0.0,
        1.0,
        3.4 * f,
        3.4 * f,
        faint: faint,
      );
    } else {
      _capsule(canvas, j.hip, j.shoulder, 5.0 * f, 6.2 * f, plain);
      _belly(
        canvas,
        BodyPart.core,
        j.hip,
        mid,
        0.05,
        0.95,
        3.6 * f,
        4.0 * f,
        faint: faint,
      );
      // Chest sits in front of the spine, back behind it (figure faces +x).
      final up = _norm(j.shoulder - j.hip);
      // The chest faces the hands (bench: up, push-up: down, curl:
      // forward); with the hands on the spine line it faces +x.
      final n = Pt(-up.y, up.x);
      final reach = _dot(j.arms.first.$3 - mid, n);
      final fwd = reach.abs() > 3 ? (reach > 0 ? n : n * -1) : n;
      final side = upper == BodyPart.chest ? fwd : fwd * -1;
      _belly(
        canvas,
        upper,
        mid + side * (1.6 * f),
        j.shoulder + side * (1.6 * f),
        0.1,
        0.75,
        4.0 * f,
        4.4 * f,
        faint: faint,
      );
      _belly(
        canvas,
        BodyPart.glutes,
        j.hip,
        j.hip + side * 0,
        0,
        0,
        4.6 * f,
        4.6 * f,
        faint: faint,
      );
    }
    if (faint) {
      for (var i = 0; i < j.arms.length; i++) {
        _arm(canvas, j.arms[i], w, false, true);
      }
    }
  }

  /// Soft contact shadows under feet that touch the floor.
  void _shadows(Canvas canvas, _Joints j) {
    final paint = Paint()..color = colors.floor;
    for (final l in j.legs) {
      final ankle = l.$3;
      if ((floorY - ankle.y).abs() > 5) continue;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ankle.x + 2, floorY + 1.6),
          width: 13,
          height: 3,
        ),
        paint,
      );
    }
  }

  /// The point that travels: the bar or hands when something is held,
  /// otherwise the hands or the first foot, whichever moves more.
  Pt _tracked(_Joints j) {
    final hands = [for (final a in j.arms) a.$3];
    final h = movement.view == FigureView.front && hands.length == 2
        ? Pt.lerp(hands[0], hands[1], 0.5)
        : hands.first;
    return h;
  }

  void _path(Canvas canvas) {
    const n = 18;
    final hand = [
      for (var i = 0; i <= n; i++) _tracked(_solve(movement, i / n)),
    ];
    final foot = [
      for (var i = 0; i <= n; i++) _solve(movement, i / n).legs.first.$3,
    ];
    double span(List<Pt> ps) => (ps.last - ps.first).length;
    final pts = movement.holds || span(hand) >= span(foot) ? hand : foot;
    if (span(pts) < 6) return;
    final dot = Paint()..color = colors.work.withValues(alpha: 0.45);
    for (final p in pts) {
      canvas.drawCircle(Offset(p.x, p.y), 1.1, dot);
    }
    final now = movement.holds || span(hand) >= span(foot)
        ? _tracked(_solve(movement, t))
        : _solve(movement, t).legs.first.$3;
    canvas.drawCircle(
      Offset(now.x, now.y),
      2.4,
      Paint()
        ..color = colors.work
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
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
          // From the side the bar is seen end-on: a plate with a hub.
          final c = hands.first;
          canvas.drawCircle(o(c), 10, gear);
          canvas.drawCircle(o(c), 7, Paint()..color = colors.floor);
          canvas.drawCircle(o(c), w * 0.5, gear);
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
      old.colors != colors ||
      old.ghost != ghost ||
      old.effort != effort ||
      old.path != path ||
      !setEquals(old.work, work) ||
      !setEquals(old.help, help);
}
