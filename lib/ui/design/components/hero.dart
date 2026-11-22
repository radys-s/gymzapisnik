part of '../components.dart';

// Hlavní karta, startovní světla a živý štítek.

/// Emphasized card for the most important action on a screen.
///
/// `vivid` adds a soft green gradient and a subtle grid.
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
    if (vivid) {
      return _WorkoutHero(padding: padding, watermark: watermark, child: child);
    }
    return CardSurface(
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Main workout card: the same flat surface, a little more padding.
class _WorkoutHero extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final String? watermark;
  const _WorkoutHero({
    required this.child,
    required this.padding,
    this.watermark,
  });

  @override
  Widget build(BuildContext context) => CardSurface(
    child: Padding(padding: padding, child: child),
  );
}

/// Startovní dílky, jeden na cvik: rozsvítí se jeden po druhém (jednou)
/// a pak zůstanou svítit. Bez animací svítí rovnou.
class StartLights extends StatefulWidget {
  /// Jedno světlo na cvik dnešního tréninku; víc než 8 se nevejde,
  /// přesný počet říká [caption].
  final int count;

  /// Popisek pod světly, např. „5 cviků · ~55 min“.
  final String? caption;

  /// Malá akce na řádku popisku vpravo (např. „Jiný trénink“).
  final Widget? trailing;
  const StartLights({super.key, this.count = 5, this.caption, this.trailing});

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
  /// Jeden dílek na cvik, dílky se postupně rozsvítí v barvách tréninku.
  Widget _segments(BuildContext context, String? caption) {
    final p = context.palette;
    final trailing = widget.trailing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: caption,
          excludeSemantics: true,
          child: AnimatedBuilder(
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
                        color: p.accent,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        if (caption != null || trailing != null) ...[
          if (trailing == null) const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: caption == null
                    ? const SizedBox.shrink()
                    : ExcludeSemantics(
                        child: Text(
                          caption,
                          style: TextStyle(
                            fontFamily: textFont,
                            color: p.secondaryLabel,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
              ?trailing,
            ],
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final bool on;
  final Color color;
  const _Segment({required this.on, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    height: 4,
    decoration: BoxDecoration(
      color: on ? color : context.palette.fill,
      borderRadius: BorderRadius.circular(2),
    ),
  );
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
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
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
