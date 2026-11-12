part of '../components.dart';

// Hlavní karta, startovní světla a živý štítek.

/// Výrazná karta pro to nejdůležitější na obrazovce.
///
/// `vivid` = datový displej: jemná mřížka, zelená rohová značka a velké
/// číslo v pozadí. Jinak obyčejná karta se zkoseným rohem.
class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool vivid;

  /// Velké číslo v pozadí výrazné karty, jen ozdoba.
  final String? watermark;
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.xl),
    this.vivid = false,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (vivid) {
      return _TensorHero(padding: padding, watermark: watermark, child: child);
    }
    return Material(
      color: p.grouped,
      shape: p.cardShape(),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Hlavní karta Tensoru jako datový displej: černá s jemnou mřížkou,
/// tenká linka, zkosený roh a zelená značka vlevo nahoře. Velké číslo
/// v pozadí je plné a skoro splývá s podkladem.
class _TensorHero extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final String? watermark;
  const _TensorHero({
    required this.child,
    required this.padding,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final still = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: p.grouped,
      shape: p.cardShape(),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: const _GridPainter(Color(0xFF141414)),
        child: Stack(
          children: [
            // Zelená rohová značka: tady se rozhoduje.
            Positioned(
              left: 0,
              top: 0,
              child: Container(width: 28, height: 3, color: p.accent),
            ),
            if (watermark != null)
              Positioned(
                right: 44,
                top: 0,
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: still ? 0 : 1, end: 0),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder: (context, t, child) => Opacity(
                      opacity: 1 - t,
                      child: Transform.translate(
                        offset: Offset(0, 24 * t),
                        child: child,
                      ),
                    ),
                    child: Text(
                      watermark!,
                      textScaler: TextScaler.noScaling,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        fontFamily: condensedFont,
                        fontSize: 132,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Jemná mřížka 22 px jako na měřicím displeji.
class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 22.0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 22.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// Startovní dílky, jeden na cvik: rozsvítí se jeden po druhém (jednou)
/// a pak zůstanou svítit. Bez animací svítí rovnou.
class StartLights extends StatefulWidget {
  /// Jedno světlo na cvik dnešního tréninku; víc než 8 se nevejde,
  /// přesný počet říká [caption].
  final int count;

  /// Popisek pod světly, např. „5 cviků · ~55 min“.
  final String? caption;
  const StartLights({super.key, this.count = 5, this.caption});

  @override
  State<StartLights> createState() => _StartLightsState();
}

class _StartLightsState extends State<StartLights>
    with SingleTickerProviderStateMixin {
  static const _delay = 0.5;
  static const _step = 0.3;
  int get _n => widget.count.clamp(1, 8);
  double get _total => _delay + _n * _step;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(StartLights old) {
    super.didUpdateWidget(old);
    if (old.count == widget.count) return;
    // Jiný den: nový počet světel a start znovu.
    _c.duration = Duration(milliseconds: (_total * 1000).round());
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caption = widget.caption;
    return _segments(context, caption);
  }
}

extension on _StartLightsState {
  /// Jeden dílek na cvik, dílky se postupně rozsvítí zeleně.
  Widget _segments(BuildContext context, String? caption) {
    final p = context.palette;
    return Semantics(
      label: caption,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final at = _c.value * _total;
              return Row(
                children: [
                  for (var i = 0; i < _n; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      child: _Segment(
                        on:
                            at >=
                            _StartLightsState._delay +
                                i * _StartLightsState._step,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                fontFamily: condensedFont,
                color: p.secondaryLabel,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final bool on;
  const _Segment({required this.on});

  @override
  Widget build(BuildContext context) {
    final a = context.palette.accent;
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: on ? a : const Color(0xFF1A1A1A),
        boxShadow: on
            ? [BoxShadow(color: a.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
    );
  }
}

/// Štítek „ŽIVĚ" s tečkou, která třikrát blikne a pak svítí.
class LiveTag extends StatefulWidget {
  final String label;
  const LiveTag({super.key, this.label = 'ŽIVĚ'});

  @override
  State<LiveTag> createState() => _LiveTagState();
}

class _LiveTagState extends State<LiveTag> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _blink = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 1),
  ]).animate(_c);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || MediaQuery.disableAnimationsOf(context)) return;
    _started = true;
    _c.repeat(count: 3);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette.positive;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _blink,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c,
              boxShadow: [BoxShadow(color: c, blurRadius: 8)],
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: c,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}
