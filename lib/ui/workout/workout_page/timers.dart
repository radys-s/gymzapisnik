part of '../workout_page.dart';

// Čas tréninku a lišta pauzy.

/// Uplynulý čas tréninku; překresluje jen sebe.
class _Elapsed extends StatefulWidget {
  final DateTime start;
  final TextStyle? style;
  const _Elapsed(this.start, {this.style});

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.start);
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    final text = s >= 3600
        ? '${s ~/ 3600}:${two(s % 3600 ~/ 60)}:${two(s % 60)}'
        : '${s ~/ 60}:${two(s % 60)}';
    final style =
        widget.style ??
        Theme.of(context).textTheme.bodySmall?.copyWith(fontFeatures: tabular);
    return Text(text, style: style, maxLines: 1);
  }
}

/// Souhrn rozepsaného tréninku pod lištou: čas, objem, série a pruh
/// hotových sérií (jako v Hevy).
class _SessionStrip extends StatelessWidget {
  final Workout workout;
  const _SessionStrip(this.workout);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final working = [
      for (final e in workout.exercises)
        for (final s in e.sets)
          if (!s.warmup) s,
    ];
    final done = working.where((s) => s.counts).toList();
    final volume = done.fold<double>(0, (a, s) => a + s.weight * s.reps);
    final value = TextStyle(
      fontFamily: condensedFont,
      fontSize: 22,
      height: 1.1,
      fontWeight: FontWeight.w700,
      color: p.label,
      fontFeatures: tabular,
    );
    Widget cell(String label, Widget child) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: text.labelSmall),
          child,
        ],
      ),
    );
    final progress = working.isEmpty ? 0.0 : done.length / working.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, 8),
          child: Row(
            children: [
              cell('ČAS', _Elapsed(workout.startedAt, style: value)),
              cell('OBJEM', Text('${formatKg(volume)} kg', style: value)),
              cell(
                'SÉRIE',
                Text('${done.length}/${working.length}', style: value),
              ),
            ],
          ),
        ),
        Semantics(
          label: 'Hotovo ${done.length} z ${working.length} sérií',
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: Motion.of(context, Motion.quick),
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 2,
              backgroundColor: p.separator,
              color: p.positive,
            ),
          ),
        ),
      ],
    );
  }
}

/// Odpočet pauzy. Konec se počítá z časového razítka, takže sedí i po
/// návratu do aplikace. Na konci zavibruje a pípne (jen když je otevřená).
class _RestBar extends StatefulWidget {
  final AppState state;
  final DateTime endsAt;
  const _RestBar({required this.state, required this.endsAt});

  @override
  State<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends State<_RestBar> {
  late final Timer timer;
  DateTime? _alertedFor;

  /// Jak dlouho po konci zůstane lišta „Pauza hotová“ a počítá přesčas.
  static const _linger = Duration(seconds: 90);

  @override
  void initState() {
    super.initState();
    // Pauza, která skončila dřív, než se lišta ukázala, už nepípá.
    if (!widget.endsAt.isAfter(DateTime.now())) _alertedFor = widget.endsAt;
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  @override
  void didUpdateWidget(_RestBar old) {
    super.didUpdateWidget(old);
    if (old.endsAt != widget.endsAt && !widget.endsAt.isAfter(DateTime.now())) {
      _alertedFor = widget.endsAt;
    }
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final end = widget.endsAt;
    if (!end.isAfter(now) && _alertedFor != end) {
      _alertedFor = end;
      Haptics.alert();
      SystemSound.play(SystemSoundType.alert);
    }
    if (now.isAfter(end.add(_linger))) {
      widget.state.skipRest();
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(DateTime.now());
    final seconds = (left.inMilliseconds / 1000).ceil();
    final finished = seconds <= 0;
    final p = context.palette;
    final total = widget.state.restTotal;
    final fraction = finished || total == null || total.inMilliseconds <= 0
        ? 1.0
        : 1 - left.inMilliseconds / total.inMilliseconds;
    final bg = p.elevated;
    final fg = finished ? AppPalette.ink : p.label;
    final chipFg = fg;
    final over = -left.inSeconds;
    final text = finished
        ? over < 1
              ? 'Pauza hotová'
              : 'Pauza hotová · +${over ~/ 60}:${(over % 60).toString().padLeft(2, '0')}'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    Widget chip(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: chipFg,
          backgroundColor: chipFg.withValues(alpha: 0.1),
          minimumSize: const Size(minTap, minTap),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontFeatures: tabular),
        ),
        child: Text(label),
      ),
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.m, Space.xs, Space.m, Space.s),
        child: Material(
          color: finished ? p.positive : bg,
          borderRadius: BorderRadius.circular(Radii.card),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            // Uběhlá část pauzy prosvítá akcentem zleva.
            painter: finished
                ? null
                : _RestFill(fraction, p.accent.withValues(alpha: 0.16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: LayoutBuilder(
                builder: (context, bar) => Row(
                  children: [
                    Icon(
                      finished
                          ? Icons.check_circle_rounded
                          : Icons.timer_outlined,
                      color: finished ? fg : p.accent,
                    ),
                    const SizedBox(width: 10),
                    // Čas jen tak široký, jak potřebuje: zbytek patří
                    // tlačítkům, která se mačkají mezi každou sérií. Při
                    // velkém písmu nejvýš polovina řádku, pak se zalomí.
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: bar.maxWidth / 2),
                      child: Text(
                        text,
                        semanticsLabel: finished ? text : 'Pauza $text',
                        style: finished
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                              )
                            : TextStyle(
                                fontFamily: condensedFont,
                                fontSize: 30,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: fg,
                                fontFeatures: tabular,
                              ),
                      ),
                    ),
                    const SizedBox(width: Space.xs),
                    // Zmenší se až při velkém písmu, ne na běžném telefonu.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!finished) ...[
                              chip(
                                '−15',
                                () => widget.state.adjustRest(
                                  const Duration(seconds: -15),
                                ),
                              ),
                              chip(
                                '+15',
                                () => widget.state.adjustRest(
                                  const Duration(seconds: 15),
                                ),
                              ),
                            ],
                            chip(
                              finished ? 'Zavřít' : 'Přeskočit',
                              widget.state.skipRest,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Výplň uběhlé části pauzy.
class _RestFill extends CustomPainter {
  final double fraction;
  final Color color;
  const _RestFill(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Offset.zero & Size(size.width * fraction.clamp(0, 1), size.height),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_RestFill old) =>
      old.fraction != fraction || old.color != color;
}
