part of '../workout_page.dart';

// Čas tréninku a lišta pauzy.

/// Uplynulý čas tréninku; překresluje jen sebe.
class _Elapsed extends StatefulWidget {
  final DateTime start;
  const _Elapsed(this.start);

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
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontFeatures: tabular),
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

  /// Jak dlouho po konci zůstane lišta „Pauza hotová“.
  static const _linger = Duration(seconds: 10);

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
    // Plovoucí tableta: bílá na černém podkladu.
    const bg = Colors.white;
    const fg = Colors.black;
    final chipFg = finished ? p.onGradient : fg;
    final text = finished
        ? 'Pauza hotová'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    Widget chip(String label, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: chipFg,
          backgroundColor: chipFg.withValues(alpha: 0.12),
          minimumSize: const Size(minTap, minTap),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
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
          color: bg,
          borderRadius: BorderRadius.circular(Radii.hero),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            // Hotová pauza se rozsvítí přechodem motivu.
            decoration: BoxDecoration(gradient: finished ? p.linear : null),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: finished ? p.onGradient : fg,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Text(
                      text,
                      semanticsLabel: finished ? text : 'Pauza $text',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: finished ? p.onGradient : fg,
                            fontFeatures: tabular,
                          ),
                    ),
                  ),
                  // Úzký displej nebo velké písmo: tlačítka se zmenší.
                  Flexible(
                    flex: 3,
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
    );
  }
}
