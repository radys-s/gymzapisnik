/// Pohybové vzory pro figurky cviků: začátek a konec pohybu jako body
/// kloubů. Figurka je ze strany čelem doprava (nebo zepředu), plátno má
/// zhruba 0–100 bodů, y roste dolů a podlaha je na y = 92.
library;

import 'dart:math' as math;

class Pt {
  final double x, y;
  const Pt(this.x, this.y);

  Pt operator +(Pt o) => Pt(x + o.x, y + o.y);
  Pt operator -(Pt o) => Pt(x - o.x, y - o.y);
  Pt operator *(double k) => Pt(x * k, y * k);
  double get length => math.sqrt(x * x + y * y);

  /// Zrcadlo kolem svislé osy [axis] (druhá strana těla zepředu).
  Pt mirror(double axis) => Pt(2 * axis - x, y);

  static Pt lerp(Pt a, Pt b, double t) =>
      Pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
}

const floorY = 92.0;
const thigh = 22.0, shin = 22.0, upperArm = 16.0, forearm = 15.0;

/// Pohled na figurku.
enum FigureView { side, front }

/// Poloha těla v jednom okamžiku. Kolena a lokty se dopočítají
/// (dvoukloubová inverzní kinematika), pokud nejsou dané přímo.
class Pose {
  final Pt hip, shoulder;

  /// Bližší noha (zepředu levá) a vzdálenější (zepředu pravá).
  final Pt ankle;
  final Pt? ankle2;
  final Pt hand;
  final Pt? hand2;

  /// Ruka je posunutá od ramene, ne absolutní bod.
  final bool handRel;

  /// Kam se ohýbá koleno a loket, když je kloub potřeba dopočítat.
  final Pt kneeDir, elbowDir;
  final Pt? knee2Dir;

  /// Koleno daná přímo (sed zepředu, kde je stehno zkrácené).
  final Pt? knee, knee2;

  const Pose({
    required this.hip,
    required this.shoulder,
    required this.ankle,
    required this.hand,
    this.ankle2,
    this.hand2,
    this.handRel = false,
    this.kneeDir = const Pt(1, 0),
    this.knee2Dir,
    this.elbowDir = const Pt(0, 1),
    this.knee,
    this.knee2,
  });
}

/// Nábytek a části strojů, které patří k pohybu (ne k vybavení).
sealed class Prop {
  const Prop();
}

/// Polstrování: lavice, sedák, opěrka. Tlustá čára z [a] do [b].
class Pad extends Prop {
  final Pt a, b;

  /// Nožička k podlaze ze středu.
  final bool leg;
  const Pad(this.a, this.b, {this.leg = true});
}

/// Hrazda nebo bradla v řezu (bod) nebo zepředu (vodorovná čára).
class Bar extends Prop {
  final Pt a, b;
  const Bar(this.a, this.b);
}

/// Bedna nebo vyvýšení pod chodidly.
class Box extends Prop {
  final Pt topLeft, bottomRight;
  const Box(this.topLeft, this.bottomRight);
}

/// Část stroje, která se hýbe s končetinou: deska pod chodidly
/// nebo polštář u kotníku.
enum Attached { footPlate, anklePad, ankle2Pad, kneePadsOuter, kneePadsInner }

class AttachedProp extends Prop {
  final Attached kind;
  const AttachedProp(this.kind);
}

/// Kde je lanko kladky připnuté.
enum CableAt { hands, ankle, ankle2 }

class Movement {
  final FigureView view;
  final Pose start, end;
  final List<Prop> props;

  /// Kladka: kotva a místo úchopu. Zepředu se kotva zrcadlí pro druhou
  /// ruku, pokud [singleAnchor] není true.
  final Pt cableAnchor;
  final CableAt cableAt;
  final bool singleAnchor;

  /// Drží ruce zátěž (činku, rukojeť)? Jinak se vybavení nekreslí.
  final bool holds;

  /// Visí na hrazdě nebo na bradlech, podlaha se nekreslí.
  final bool floor;

  /// Činka s kotvou na zemi (landmine).
  final Pt? landmine;

  const Movement({
    required this.start,
    required this.end,
    this.view = FigureView.side,
    this.props = const [],
    this.cableAnchor = const Pt(98, 20),
    this.cableAt = CableAt.hands,
    this.singleAnchor = false,
    this.holds = true,
    this.floor = true,
    this.landmine,
  });
}

// ---- Sdílené polohy ----

const _hip = Pt(50, 48), _sh = Pt(50, 18), _ank = Pt(50, floorY);
const _down = Pt(1, 30); // ruka volně podél těla (od ramene)

Pose _stand({
  Pt hand = _down,
  bool rel = true,
  Pt elbow = const Pt(0, 1),
  Pt? hand2,
}) => Pose(
  hip: _hip,
  shoulder: _sh,
  ankle: _ank,
  hand: hand,
  hand2: hand2,
  handRel: rel,
  elbowDir: elbow,
);

/// Stoj zepředu: levá noha a levá ruka, pravé se zrcadlí.
Pose _front({
  Pt hip = _hip,
  Pt sh = _sh,
  Pt ankle = const Pt(45, floorY),
  Pt? ankle2,
  Pt hand = const Pt(38, 48),
  Pt? hand2,
  Pt elbow = const Pt(-1, 1),
  Pt knee = const Pt(-1, 0),
  Pt? kneeAt,
  Pt? knee2At,
}) => Pose(
  hip: hip,
  shoulder: sh,
  ankle: ankle,
  ankle2: ankle2,
  hand: hand,
  hand2: hand2,
  elbowDir: elbow,
  kneeDir: knee,
  knee: kneeAt,
  knee2: knee2At,
);

// Leh na lavici (hlava vlevo).
const _benchFlat = [Pad(Pt(10, 77), Pt(66, 77))];
Pose _lying(Pt hand, {Pt elbow = const Pt(0, 1)}) => Pose(
  hip: const Pt(58, 72),
  shoulder: const Pt(28, 72),
  ankle: const Pt(78, floorY),
  kneeDir: const Pt(1, -1),
  hand: hand,
  elbowDir: elbow,
);

// Předklon (přítahy, rozpažování v předklonu, zapažování).
Pose _bent(Pt hand, {bool rel = false, Pt elbow = const Pt(0, 1)}) => Pose(
  hip: const Pt(38, 50),
  shoulder: const Pt(66, 38),
  ankle: _ank,
  hand: hand,
  handRel: rel,
  elbowDir: elbow,
);

// Sed na stroji ze strany.
const _seat = [Pad(Pt(28, 70), Pt(50, 70)), Pad(Pt(28, 70), Pt(24, 38))];
Pose _seated({
  required Pt ankle,
  Pt hand = const Pt(46, 68),
  Pt knee = const Pt(1, -1),
  Pt elbow = const Pt(0, 1),
  Pt shoulder = const Pt(36, 36),
}) => Pose(
  hip: const Pt(40, 66),
  shoulder: shoulder,
  ankle: ankle,
  hand: hand,
  kneeDir: knee,
  elbowDir: elbow,
);

// Sed zepředu (stroje na adduktory a abduktory, stahování kladky).
const _frontSeat = [Pad(Pt(34, 68), Pt(66, 68))];
Pose _frontSeated({
  required Pt knee,
  required Pt ankle,
  Pt hand = const Pt(36, 66),
  Pt elbow = const Pt(-1, 1),
}) => Pose(
  hip: const Pt(50, 64),
  shoulder: const Pt(50, 34),
  ankle: ankle,
  knee: knee,
  hand: hand,
  elbowDir: elbow,
);

/// Pohybový vzor podle `Exercise.pattern`. Neznámý vzor dostane stoj.
Movement movementFor(String pattern) => movements[pattern] ?? _fallback;

const _fallback = Movement(
  start: Pose(
    hip: _hip,
    shoulder: _sh,
    ankle: _ank,
    hand: _down,
    handRel: true,
  ),
  end: Pose(hip: _hip, shoulder: _sh, ankle: _ank, hand: _down, handRel: true),
  holds: false,
);

final Map<String, Movement> movements = {
  // ---- Nohy ----
  'squat': Movement(
    start: _stand(hand: const Pt(-5, 4), elbow: const Pt(-1, 1)),
    end: const Pose(
      hip: Pt(36, 70),
      shoulder: Pt(56, 46),
      ankle: Pt(52, floorY),
      hand: Pt(-5, 4),
      handRel: true,
      elbowDir: Pt(-1, 1),
    ),
  ),
  'sumo_squat': Movement(
    view: FigureView.front,
    start: _front(ankle: const Pt(34, floorY), hand: const Pt(47, 50)),
    end: _front(
      hip: const Pt(50, 66),
      sh: const Pt(50, 36),
      ankle: const Pt(32, floorY),
      hand: const Pt(47, 68),
      elbow: const Pt(-1, 0),
    ),
  ),
  'lunge': const Movement(
    start: Pose(
      hip: _hip,
      shoulder: _sh,
      ankle: Pt(57, floorY),
      ankle2: Pt(43, floorY),
      hand: _down,
      handRel: true,
    ),
    end: Pose(
      hip: Pt(46, 68),
      shoulder: Pt(47, 38),
      ankle: Pt(66, floorY),
      ankle2: Pt(24, floorY),
      knee2Dir: Pt(0, 1),
      hand: _down,
      handRel: true,
    ),
  ),
  'step_up': const Movement(
    props: [Box(Pt(58, 74), Pt(86, floorY))],
    start: Pose(
      hip: Pt(44, 50),
      shoulder: Pt(46, 20),
      ankle: Pt(66, 74),
      ankle2: Pt(42, floorY),
      kneeDir: Pt(1, -1),
      hand: _down,
      handRel: true,
    ),
    end: Pose(
      hip: Pt(64, 32),
      shoulder: Pt(65, 2),
      ankle: Pt(66, 74),
      ankle2: Pt(52, 64),
      knee2Dir: Pt(1, 0),
      hand: _down,
      handRel: true,
    ),
  ),
  'leg_press': const Movement(
    props: [
      Pad(Pt(14, 48), Pt(36, 80)),
      Pad(Pt(36, 80), Pt(52, 82)),
      AttachedProp(Attached.footPlate),
    ],
    start: Pose(
      hip: Pt(42, 76),
      shoulder: Pt(22, 52),
      ankle: Pt(62, 52),
      kneeDir: Pt(0, -1),
      hand: Pt(40, 82),
    ),
    end: Pose(
      hip: Pt(42, 76),
      shoulder: Pt(22, 52),
      ankle: Pt(72, 44),
      kneeDir: Pt(0, -1),
      hand: Pt(40, 82),
    ),
  ),
  'calf_press': const Movement(
    props: [
      Pad(Pt(14, 48), Pt(36, 80)),
      Pad(Pt(36, 80), Pt(52, 82)),
      AttachedProp(Attached.footPlate),
    ],
    start: Pose(
      hip: Pt(42, 76),
      shoulder: Pt(22, 52),
      ankle: Pt(71, 45),
      kneeDir: Pt(0, -1),
      hand: Pt(40, 82),
    ),
    end: Pose(
      hip: Pt(42, 76),
      shoulder: Pt(22, 52),
      ankle: Pt(75, 41),
      kneeDir: Pt(0, -1),
      hand: Pt(40, 82),
    ),
  ),
  'leg_ext': Movement(
    props: const [..._seat, AttachedProp(Attached.anklePad)],
    start: _seated(ankle: const Pt(62, 90)),
    end: _seated(ankle: const Pt(84, 62)),
  ),
  'leg_curl_seated': Movement(
    props: const [..._seat, AttachedProp(Attached.anklePad)],
    start: _seated(ankle: const Pt(84, 62)),
    end: _seated(ankle: const Pt(60, 88)),
  ),
  'leg_curl': const Movement(
    props: [Pad(Pt(10, 71), Pt(76, 71)), AttachedProp(Attached.anklePad)],
    start: Pose(
      hip: Pt(52, 66),
      shoulder: Pt(22, 66),
      ankle: Pt(94, 66),
      hand: Pt(12, 74),
    ),
    end: Pose(
      hip: Pt(52, 66),
      shoulder: Pt(22, 66),
      ankle: Pt(70, 44),
      kneeDir: Pt(1, 1),
      hand: Pt(12, 74),
    ),
  ),
  'leg_curl_standing': const Movement(
    props: [
      Pad(Pt(70, 24), Pt(70, floorY), leg: false),
      AttachedProp(Attached.ankle2Pad),
    ],
    start: Pose(
      hip: _hip,
      shoulder: _sh,
      ankle: _ank,
      ankle2: Pt(51, floorY),
      hand: Pt(68, 40),
    ),
    end: Pose(
      hip: _hip,
      shoulder: _sh,
      ankle: _ank,
      ankle2: Pt(34, 66),
      knee2Dir: Pt(1, 1),
      hand: Pt(68, 40),
    ),
  ),
  'nordic': const Movement(
    holds: false,
    props: [AttachedProp(Attached.anklePad)],
    start: Pose(
      hip: Pt(50, 66),
      shoulder: Pt(52, 36),
      ankle: Pt(28, 90),
      kneeDir: Pt(1, 1),
      hand: Pt(10, 16),
      handRel: true,
    ),
    end: Pose(
      hip: Pt(64, 74),
      shoulder: Pt(88, 58),
      ankle: Pt(28, 90),
      kneeDir: Pt(1, 1),
      hand: Pt(8, 18),
      handRel: true,
    ),
  ),
  'hip_thrust': const Movement(
    props: [Pad(Pt(4, 64), Pt(30, 64))],
    start: Pose(
      hip: Pt(46, 80),
      shoulder: Pt(24, 62),
      ankle: Pt(70, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(46, 74),
      elbowDir: Pt(0, -1),
    ),
    end: Pose(
      hip: Pt(50, 62),
      shoulder: Pt(22, 60),
      ankle: Pt(70, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(50, 56),
      elbowDir: Pt(0, -1),
    ),
  ),
  'glute_bridge': const Movement(
    start: Pose(
      hip: Pt(46, 86),
      shoulder: Pt(17, 87),
      ankle: Pt(68, floorY),
      kneeDir: Pt(0, -1),
      hand: Pt(46, 82),
      elbowDir: Pt(0, -1),
    ),
    end: Pose(
      hip: Pt(48, 72),
      shoulder: Pt(21, 86),
      ankle: Pt(68, floorY),
      kneeDir: Pt(0, -1),
      hand: Pt(48, 66),
      elbowDir: Pt(0, -1),
    ),
  ),
  'kickback': const Movement(
    props: [
      Pad(Pt(80, 20), Pt(80, floorY), leg: false),
      AttachedProp(Attached.ankle2Pad),
    ],
    cableAt: CableAt.ankle2,
    cableAnchor: Pt(4, 90),
    start: Pose(
      hip: Pt(50, 50),
      shoulder: Pt(66, 26),
      ankle: _ank,
      ankle2: Pt(52, 90),
      hand: Pt(78, 40),
    ),
    end: Pose(
      hip: Pt(50, 50),
      shoulder: Pt(66, 26),
      ankle: _ank,
      ankle2: Pt(12, 66),
      hand: Pt(78, 40),
    ),
  ),
  'abduction': Movement(
    view: FigureView.front,
    props: const [..._frontSeat, AttachedProp(Attached.kneePadsOuter)],
    start: _frontSeated(knee: const Pt(43, 74), ankle: const Pt(44, floorY)),
    end: _frontSeated(knee: const Pt(25, 72), ankle: const Pt(33, floorY)),
  ),
  'adduction': Movement(
    view: FigureView.front,
    props: const [..._frontSeat, AttachedProp(Attached.kneePadsInner)],
    start: _frontSeated(knee: const Pt(25, 72), ankle: const Pt(33, floorY)),
    end: _frontSeated(knee: const Pt(43, 74), ankle: const Pt(44, floorY)),
  ),
  'cable_abduction': Movement(
    view: FigureView.front,
    cableAt: CableAt.ankle,
    cableAnchor: const Pt(98, floorY),
    singleAnchor: true,
    start: _front(ankle2: const Pt(55, floorY), hand: const Pt(30, 44)),
    end: _front(
      ankle: const Pt(26, 86),
      ankle2: const Pt(55, floorY),
      hand: const Pt(30, 44),
    ),
  ),
  'cable_adduction': Movement(
    view: FigureView.front,
    cableAt: CableAt.ankle,
    cableAnchor: const Pt(2, floorY),
    singleAnchor: true,
    start: _front(
      ankle: const Pt(26, 86),
      ankle2: const Pt(55, floorY),
      hand: const Pt(30, 44),
    ),
    end: _front(
      ankle: const Pt(54, 88),
      ankle2: const Pt(56, floorY),
      hand: const Pt(30, 44),
    ),
  ),
  'lateral_walk': Movement(
    view: FigureView.front,
    holds: false,
    start: _front(
      hip: const Pt(50, 52),
      sh: const Pt(50, 22),
      ankle: const Pt(41, floorY),
      hand: const Pt(46, 44),
    ),
    end: _front(
      hip: const Pt(50, 52),
      sh: const Pt(50, 22),
      ankle: const Pt(31, floorY),
      hand: const Pt(46, 44),
    ),
  ),
  'calf': const Movement(
    props: [Box(Pt(40, 86), Pt(66, floorY))],
    start: Pose(
      hip: Pt(50, 42),
      shoulder: Pt(50, 12),
      ankle: Pt(50, 85),
      hand: _down,
      handRel: true,
    ),
    end: Pose(
      hip: Pt(50, 36),
      shoulder: Pt(50, 6),
      ankle: Pt(50, 79),
      hand: _down,
      handRel: true,
    ),
  ),
  'calf_seated': Movement(
    props: const [..._seat, Pad(Pt(52, 56), Pt(70, 56), leg: false)],
    start: _seated(
      ankle: const Pt(62, 88),
      hand: const Pt(58, 58),
      shoulder: const Pt(40, 36),
    ),
    end: _seated(
      ankle: const Pt(62, 82),
      hand: const Pt(58, 54),
      shoulder: const Pt(40, 36),
    ),
  ),
  'carry': const Movement(
    start: Pose(
      hip: _hip,
      shoulder: Pt(51, 18),
      ankle: Pt(60, floorY),
      ankle2: Pt(40, floorY),
      hand: _down,
      handRel: true,
    ),
    end: Pose(
      hip: Pt(52, 47),
      shoulder: Pt(53, 17),
      ankle: Pt(42, floorY),
      ankle2: Pt(62, floorY),
      hand: _down,
      handRel: true,
    ),
  ),

  // ---- Kyčelní pohyb ----
  'hinge': Movement(
    start: _stand(),
    end: const Pose(
      hip: Pt(36, 58),
      shoulder: Pt(64, 47),
      ankle: Pt(52, floorY),
      hand: Pt(0, 30),
      handRel: true,
    ),
  ),
  'good_morning': Movement(
    start: _stand(hand: const Pt(-5, 4), elbow: const Pt(-1, 1)),
    end: const Pose(
      hip: Pt(40, 50),
      shoulder: Pt(70, 46),
      ankle: Pt(50, floorY),
      hand: Pt(-5, 4),
      handRel: true,
      elbowDir: Pt(-1, 1),
    ),
  ),
  'swing': Movement(
    start: const Pose(
      hip: Pt(36, 58),
      shoulder: Pt(62, 46),
      ankle: Pt(50, floorY),
      hand: Pt(48, 74),
    ),
    end: _stand(hand: const Pt(80, 16), rel: false),
  ),
  'back_ext': const Movement(
    holds: false,
    props: [Pad(Pt(34, 72), Pt(52, 58)), AttachedProp(Attached.anklePad)],
    start: Pose(
      hip: Pt(44, 62),
      shoulder: Pt(60, 88),
      ankle: Pt(14, 88),
      hand: Pt(6, 6),
      handRel: true,
    ),
    end: Pose(
      hip: Pt(44, 62),
      shoulder: Pt(67, 42),
      ankle: Pt(14, 88),
      hand: Pt(6, 6),
      handRel: true,
    ),
  ),

  // ---- Tlaky ----
  'push_flat': Movement(
    props: _benchFlat,
    start: _lying(const Pt(28, 42)),
    end: _lying(const Pt(30, 62)),
  ),
  'push_incline': const Movement(
    props: [Pad(Pt(14, 44), Pt(50, 80))],
    start: Pose(
      hip: Pt(56, 74),
      shoulder: Pt(34, 52),
      ankle: Pt(76, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(34, 22),
    ),
    end: Pose(
      hip: Pt(56, 74),
      shoulder: Pt(34, 52),
      ankle: Pt(76, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(38, 42),
      elbowDir: Pt(-0.5, 1),
    ),
  ),
  'push_up': const Movement(
    holds: false,
    start: Pose(
      hip: Pt(59, 75),
      shoulder: Pt(32, 62),
      ankle: Pt(92, 90),
      kneeDir: Pt(0, 1),
      hand: Pt(32, 91),
    ),
    end: Pose(
      hip: Pt(62, 85),
      shoulder: Pt(32, 80),
      ankle: Pt(92, 90),
      kneeDir: Pt(0, 1),
      hand: Pt(32, 91),
      elbowDir: Pt(1, -1),
    ),
  ),
  'push_vertical': Movement(
    start: _stand(hand: const Pt(58, 16), rel: false),
    end: _stand(hand: const Pt(52, -12), rel: false),
  ),
  'landmine': Movement(
    landmine: const Pt(4, floorY),
    start: const Pose(
      hip: _hip,
      shoulder: _sh,
      ankle: Pt(57, floorY),
      ankle2: Pt(40, floorY),
      hand: Pt(60, 20),
    ),
    end: const Pose(
      hip: _hip,
      shoulder: Pt(52, 18),
      ankle: Pt(57, floorY),
      ankle2: Pt(40, floorY),
      hand: Pt(74, -3),
    ),
  ),
  'dip': const Movement(
    floor: false,
    props: [Bar(Pt(50, 52), Pt(50, 52))],
    start: Pose(
      hip: Pt(47, 50),
      shoulder: Pt(49, 20),
      ankle: Pt(32, 80),
      hand: Pt(50, 50),
    ),
    end: Pose(
      hip: Pt(45, 68),
      shoulder: Pt(52, 38),
      ankle: Pt(30, 98),
      hand: Pt(50, 50),
      elbowDir: Pt(-1, 0),
    ),
  ),
  'bench_dip': const Movement(
    holds: false,
    props: [Pad(Pt(14, 61), Pt(40, 61))],
    start: Pose(
      hip: Pt(48, 60),
      shoulder: Pt(44, 30),
      ankle: Pt(80, 90),
      kneeDir: Pt(0, -1),
      hand: Pt(38, 58),
      elbowDir: Pt(-1, 0),
    ),
    end: Pose(
      hip: Pt(50, 76),
      shoulder: Pt(46, 46),
      ankle: Pt(80, 90),
      kneeDir: Pt(0, -1),
      hand: Pt(38, 58),
      elbowDir: Pt(-1, 0),
    ),
  ),

  // ---- Hrudník a ramena (rozpažování) ----
  'fly': Movement(
    view: FigureView.front,
    cableAnchor: const Pt(-4, 10),
    start: _front(hand: const Pt(14, 22), elbow: const Pt(0, 1)),
    end: _front(hand: const Pt(46, 26), elbow: const Pt(-1, 1)),
  ),
  'fly_lying': Movement(
    view: FigureView.front,
    props: const [Pad(Pt(50, 6), Pt(50, 60), leg: false)],
    start: _front(hand: const Pt(46, 24), elbow: const Pt(-1, 1)),
    end: _front(hand: const Pt(12, 26), elbow: const Pt(0, 1)),
  ),
  'pullover': const Movement(
    props: [Pad(Pt(14, 75), Pt(40, 75))],
    start: Pose(
      hip: Pt(56, 82),
      shoulder: Pt(28, 70),
      ankle: Pt(74, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(30, 40),
    ),
    end: Pose(
      hip: Pt(56, 82),
      shoulder: Pt(28, 70),
      ankle: Pt(74, floorY),
      kneeDir: Pt(1, -1),
      hand: Pt(0, 70),
      elbowDir: Pt(0, -1),
    ),
  ),
  'lateral_raise': Movement(
    view: FigureView.front,
    cableAnchor: const Pt(58, floorY),
    start: _front(),
    end: _front(hand: const Pt(12, 22), elbow: const Pt(0, 1)),
  ),
  'front_raise': Movement(
    start: _stand(),
    end: _stand(hand: const Pt(80, 14), rel: false),
  ),
  'rear_fly': Movement(
    start: _bent(const Pt(0, 30), rel: true),
    end: _bent(const Pt(68, 10)),
  ),
  'rear_fly_standing': Movement(
    view: FigureView.front,
    cableAnchor: const Pt(70, 10),
    start: _front(hand: const Pt(46, 24), elbow: const Pt(-1, 1)),
    end: _front(hand: const Pt(10, 20), elbow: const Pt(0, 1)),
  ),
  'upright_row': Movement(
    start: _stand(hand: const Pt(3, 30)),
    end: _stand(hand: const Pt(56, 18), rel: false, elbow: const Pt(-0.3, -1)),
  ),
  'shrug': const Movement(
    start: Pose(
      hip: _hip,
      shoulder: _sh,
      ankle: _ank,
      hand: _down,
      handRel: true,
    ),
    end: Pose(
      hip: _hip,
      shoulder: Pt(50, 14),
      ankle: _ank,
      hand: _down,
      handRel: true,
    ),
  ),
  'face_pull': Movement(
    cableAnchor: const Pt(98, 10),
    start: _stand(hand: const Pt(78, 14), rel: false),
    end: _stand(hand: const Pt(56, 10), rel: false, elbow: const Pt(-1, -1)),
  ),

  // ---- Záda (přítahy) ----
  'pull_up': Movement(
    view: FigureView.front,
    floor: false,
    holds: false,
    props: const [Bar(Pt(22, -6), Pt(78, -6))],
    start: _front(
      hip: const Pt(50, 52),
      sh: const Pt(50, 22),
      ankle: const Pt(47, 96),
      hand: const Pt(36, -6),
    ),
    end: _front(
      hip: const Pt(50, 32),
      sh: const Pt(50, 2),
      ankle: const Pt(47, 76),
      hand: const Pt(36, -6),
      elbow: const Pt(-1, 0.5),
    ),
  ),
  'pulldown': Movement(
    view: FigureView.front,
    cableAnchor: const Pt(50, -16),
    singleAnchor: true,
    props: _frontSeat,
    start: _frontSeated(
      knee: const Pt(38, 72),
      ankle: const Pt(40, floorY),
      hand: const Pt(30, 0),
      elbow: const Pt(-1, 0),
    ),
    end: _frontSeated(
      knee: const Pt(38, 72),
      ankle: const Pt(40, floorY),
      hand: const Pt(32, 30),
      elbow: const Pt(-1, 1),
    ),
  ),
  'straight_pulldown': const Movement(
    cableAnchor: Pt(96, -10),
    start: Pose(
      hip: Pt(48, 50),
      shoulder: Pt(58, 22),
      ankle: _ank,
      hand: Pt(84, 6),
    ),
    end: Pose(
      hip: Pt(48, 50),
      shoulder: Pt(58, 22),
      ankle: _ank,
      hand: Pt(60, 52),
    ),
  ),
  'row': const Movement(
    cableAnchor: Pt(98, 66),
    props: [Pad(Pt(24, 83), Pt(48, 83)), AttachedProp(Attached.footPlate)],
    start: Pose(
      hip: Pt(38, 79),
      shoulder: Pt(42, 49),
      ankle: Pt(78, 80),
      kneeDir: Pt(0, -1),
      hand: Pt(72, 54),
    ),
    end: Pose(
      hip: Pt(38, 79),
      shoulder: Pt(40, 49),
      ankle: Pt(78, 80),
      kneeDir: Pt(0, -1),
      hand: Pt(52, 64),
      elbowDir: Pt(-1, 0),
    ),
  ),
  'row_bent': Movement(
    start: _bent(const Pt(0, 30), rel: true),
    end: _bent(const Pt(58, 56), elbow: const Pt(-1, -1)),
  ),
  'inverted_row': const Movement(
    holds: false,
    props: [Bar(Pt(34, 31), Pt(34, 31))],
    start: Pose(
      hip: Pt(63, 75),
      shoulder: Pt(36, 62),
      ankle: Pt(96, 90),
      kneeDir: Pt(0, -1),
      hand: Pt(34, 32),
    ),
    end: Pose(
      hip: Pt(61, 60),
      shoulder: Pt(38, 40),
      ankle: Pt(96, 90),
      kneeDir: Pt(0, -1),
      hand: Pt(34, 32),
      elbowDir: Pt(1, 1),
    ),
  ),

  // ---- Paže ----
  'curl': Movement(
    cableAnchor: const Pt(72, floorY),
    start: _stand(hand: const Pt(2, 30)),
    end: _stand(hand: const Pt(60, 18), rel: false, elbow: const Pt(-0.3, 1)),
  ),
  'curl_seated': Movement(
    props: const [..._seat, Pad(Pt(52, 44), Pt(66, 58), leg: false)],
    start: _seated(
      ankle: const Pt(62, 92),
      shoulder: const Pt(42, 36),
      hand: const Pt(65, 57),
    ),
    end: _seated(
      ankle: const Pt(62, 92),
      shoulder: const Pt(42, 36),
      hand: const Pt(58, 26),
      elbow: const Pt(1, 1),
    ),
  ),
  'pushdown': Movement(
    cableAnchor: const Pt(66, -12),
    start: _stand(hand: const Pt(62, 30), rel: false, elbow: const Pt(-0.2, 1)),
    end: _stand(hand: const Pt(56, 48), rel: false),
  ),
  'triceps_ext': Movement(
    cableAnchor: const Pt(8, 74),
    start: _stand(hand: const Pt(42, 10), rel: false, elbow: const Pt(0.3, -1)),
    end: _stand(hand: const Pt(52, -12), rel: false),
  ),
  'triceps_kickback': Movement(
    start: _bent(const Pt(64, 62), elbow: const Pt(-1, 0)),
    end: _bent(const Pt(40, 46)),
  ),
  'skull': Movement(
    props: _benchFlat,
    start: _lying(const Pt(28, 42)),
    end: _lying(const Pt(14, 56), elbow: const Pt(0, -1)),
  ),
  'wrist_curl': Movement(
    props: const [Pad(Pt(28, 70), Pt(50, 70))],
    start: _seated(
      ankle: const Pt(66, 92),
      shoulder: const Pt(46, 36),
      hand: const Pt(70, 70),
    ),
    end: _seated(
      ankle: const Pt(66, 92),
      shoulder: const Pt(46, 36),
      hand: const Pt(72, 62),
    ),
  ),

  // ---- Střed těla ----
  'crunch': const Movement(
    holds: false,
    start: Pose(
      hip: Pt(52, 86),
      shoulder: Pt(22, 87),
      ankle: Pt(72, floorY),
      kneeDir: Pt(0, -1),
      hand: Pt(14, 82),
      elbowDir: Pt(0, -1),
    ),
    end: Pose(
      hip: Pt(52, 86),
      shoulder: Pt(28, 68),
      ankle: Pt(72, floorY),
      kneeDir: Pt(0, -1),
      hand: Pt(22, 62),
      elbowDir: Pt(1, -1),
    ),
  ),
  'leg_raise': const Movement(
    floor: false,
    holds: false,
    props: [Bar(Pt(50, -8), Pt(50, -8))],
    start: Pose(
      hip: Pt(50, 50),
      shoulder: Pt(50, 20),
      ankle: Pt(50, 94),
      hand: Pt(50, -8),
    ),
    end: Pose(
      hip: Pt(50, 50),
      shoulder: Pt(49, 20),
      ankle: Pt(92, 46),
      hand: Pt(50, -8),
    ),
  ),
  'leg_raise_lying': const Movement(
    holds: false,
    start: Pose(
      hip: Pt(50, 86),
      shoulder: Pt(20, 87),
      ankle: Pt(92, 85),
      hand: Pt(44, 90),
    ),
    end: Pose(
      hip: Pt(50, 86),
      shoulder: Pt(20, 87),
      ankle: Pt(56, 44),
      hand: Pt(44, 90),
    ),
  ),
  'rollout': const Movement(
    start: Pose(
      hip: Pt(30, 68),
      shoulder: Pt(54, 56),
      ankle: Pt(8, 90),
      kneeDir: Pt(0, 1),
      hand: Pt(52, 86),
    ),
    end: Pose(
      hip: Pt(48, 80),
      shoulder: Pt(76, 74),
      ankle: Pt(8, 90),
      kneeDir: Pt(0, 1),
      hand: Pt(104, 84),
    ),
  ),
  'side_bend': Movement(
    view: FigureView.front,
    start: _front(hand: const Pt(38, 48), hand2: const Pt(62, 48)),
    end: _front(
      sh: const Pt(42, 20),
      hand: const Pt(30, 50),
      hand2: const Pt(56, 46),
    ),
  ),
  'rotation': Movement(
    view: FigureView.front,
    start: _front(
      hip: const Pt(50, 74),
      sh: const Pt(50, 44),
      ankle: const Pt(38, floorY),
      hand: const Pt(30, 58),
      hand2: const Pt(34, 60),
    ),
    end: _front(
      hip: const Pt(50, 74),
      sh: const Pt(50, 44),
      ankle: const Pt(38, floorY),
      hand: const Pt(66, 60),
      hand2: const Pt(70, 58),
    ),
  ),
  'woodchop': Movement(
    view: FigureView.front,
    cableAnchor: const Pt(100, -8),
    singleAnchor: true,
    start: _front(
      ankle: const Pt(38, floorY),
      hand: const Pt(74, 6),
      hand2: const Pt(78, 4),
    ),
    end: _front(
      ankle: const Pt(38, floorY),
      hand: const Pt(24, 70),
      hand2: const Pt(28, 72),
    ),
  ),
};
