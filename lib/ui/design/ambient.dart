import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'motion.dart';
import 'tokens.dart';

/// Quiet background life: color that drifts, a sheen that passes now and
/// then. It never carries information, so it is off with reduced motion,
/// off for pages that are covered, and off in widget tests.
abstract final class Ambient {
  /// `main` turns this on. Tests leave it off so `pumpAndSettle` settles.
  static bool enabled = false;

  /// One shared clock for every ambient effect on screen.
  static final clock = AmbientClock._();

  /// Should ambient effects run for this widget right now?
  static bool on(BuildContext context) =>
      enabled && Motion.on(context) && TickerMode.valuesOf(context).enabled;
}

/// Seconds since the first ambient widget appeared. Ticks at a low frame
/// rate and only while something listens, so an idle screen costs nothing
/// more than the effects it shows.
class AmbientClock extends ChangeNotifier implements ValueListenable<double> {
  AmbientClock._();

  static const frame = Duration(milliseconds: 40);
  Timer? _timer;
  int _listeners = 0;
  int _ticks = 0;

  @override
  double get value => _ticks * frame.inMilliseconds / 1000;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (++_listeners == 1) {
      _timer = Timer.periodic(frame, (_) {
        _ticks++;
        notifyListeners();
      });
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (--_listeners == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

/// Rebuilds with the ambient clock. [seconds] is `null` while ambient
/// effects are off, so the builder can draw its resting state.
class AmbientBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, double? seconds, Widget? child)
  builder;
  final Widget? child;

  /// Rebuilds per second; slow drifts need far fewer than the clock gives.
  final int fps;

  const AmbientBuilder({
    super.key,
    required this.builder,
    this.child,
    this.fps = 25,
  });

  @override
  State<AmbientBuilder> createState() => _AmbientBuilderState();
}

class _AmbientBuilderState extends State<AmbientBuilder>
    with WidgetsBindingObserver {
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync(_foreground && Ambient.on(context));
    setState(() {});
  }

  bool _listening = false;
  int _step = -1;

  void _sync(bool run) {
    if (run == _listening) return;
    _listening = run;
    if (run) {
      Ambient.clock.addListener(_tick);
    } else {
      Ambient.clock.removeListener(_tick);
    }
  }

  void _tick() {
    final step = (Ambient.clock.value * widget.fps).floor();
    if (step == _step) return;
    setState(() => _step = step);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(_foreground && Ambient.on(context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sync(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    _listening ? Ambient.clock.value : null,
    widget.child,
  );
}

/// Page background: three soft color clouds that drift slowly behind the
/// content. The top-left cloud is always the brand violet; the other two
/// take the section [tone].
class AuroraBackground extends StatelessWidget {
  final Tone tone;
  final Widget child;
  const AuroraBackground({
    super.key,
    this.tone = Tone.training,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: AmbientBuilder(
                fps: 12,
                builder: (context, seconds, _) =>
                    CustomPaint(painter: _AuroraPainter(seconds ?? 0, tone)),
              ),
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _AuroraPainter extends CustomPainter {
  final double seconds;
  final Tone tone;
  const _AuroraPainter(this.seconds, this.tone);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // One slow lap takes about 40 seconds.
    final a = seconds * math.pi * 2 / 40;
    void cloud(Color color, double alpha, double x, double y, double r) {
      final rect = Rect.fromCircle(center: Offset(w * x, h * y), radius: w * r);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }

    cloud(
      AppPalette.violet,
      0.18,
      0.04 + 0.10 * math.sin(a),
      0.02 + 0.03 * math.cos(a * 1.3),
      0.95,
    );
    cloud(
      tone.colors.last,
      0.12,
      1.0 + 0.08 * math.cos(a * 0.8),
      0.34 + 0.05 * math.sin(a),
      0.8,
    );
    cloud(
      tone.colors.first,
      0.07,
      0.22 + 0.10 * math.sin(a * 0.6 + 1),
      0.98 + 0.03 * math.cos(a),
      0.9,
    );
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.seconds != seconds || old.tone != tone;
}

/// A band of light that crosses [child] once every [every] seconds: enough
/// to catch the eye on the main action, never a blinking light.
class Sheen extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool enabled;

  /// Seconds between two passes.
  final double every;

  /// Shifts the pass so neighbors do not flash together.
  final double delay;

  /// How long one pass takes, in seconds.
  static const pass = 1.1;

  const Sheen({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enabled = true,
    this.every = 7,
    this.delay = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return AmbientBuilder(
      child: child,
      builder: (context, seconds, child) {
        if (seconds == null) return child!;
        final at = (seconds - delay) % every;
        final t = at / pass;
        return CustomPaint(
          foregroundPainter: seconds < delay || t >= 1
              ? null
              : _SheenPainter(t, borderRadius),
          child: child,
        );
      },
    );
  }
}

class _SheenPainter extends CustomPainter {
  final double t;
  final BorderRadius radius;
  const _SheenPainter(this.t, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Ease in and out so the band does not start or stop abruptly.
    final eased = (1 - math.cos(t * math.pi)) / 2;
    final center = -0.25 + 1.5 * eased;
    double stop(double v) => v.clamp(0.0, 1.0);
    canvas
      ..save()
      ..clipRRect(radius.toRRect(rect))
      ..drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = LinearGradient(
            begin: const Alignment(-1, -0.6),
            end: const Alignment(1, 0.6),
            colors: const [
              Color(0x00FFFFFF),
              Color(0x00FFFFFF),
              Color(0x52FFFFFF),
              Color(0x00FFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: [0, stop(center - 0.2), stop(center), stop(center + 0.2), 1],
          ).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t || old.radius != radius;
}

/// A thin gradient edge whose colors travel slowly around [child]. At rest
/// (ambient off) the edge is still drawn, just not moving.
class AuraEdge extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final List<Color> colors;
  final double width;

  const AuraEdge({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.colors,
    this.width = 1.5,
  });

  @override
  Widget build(BuildContext context) => AmbientBuilder(
    fps: 12,
    child: child,
    builder: (context, seconds, child) => CustomPaint(
      foregroundPainter: _AuraPainter(
        (seconds ?? 0) * 0.35,
        borderRadius,
        colors,
        width,
      ),
      child: child,
    ),
  );
}

class _AuraPainter extends CustomPainter {
  final double angle;
  final BorderRadius radius;
  final List<Color> colors;
  final double width;
  const _AuraPainter(this.angle, this.radius, this.colors, this.width);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final faint = colors.first.withValues(alpha: 0.08);
    canvas.drawRRect(
      radius.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..shader = SweepGradient(
          colors: [faint, ...colors, faint, faint],
          stops: [
            0,
            for (var i = 0; i < colors.length; i++)
              0.12 + 0.36 * i / (colors.length - 1),
            0.62,
            1,
          ],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AuraPainter old) =>
      old.angle != angle ||
      old.radius != radius ||
      old.width != width ||
      !listEquals(old.colors, colors);
}
