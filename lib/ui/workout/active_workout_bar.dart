import 'dart:async';

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../design/tokens.dart';
import 'launcher.dart';

/// Lišta běžícího tréninku nad spodní navigací (jako v Hevy): čas, aktuální
/// cvik a návrat do tréninku z kterékoli záložky.
class ActiveWorkoutBar extends StatelessWidget {
  final AppState state;
  const ActiveWorkoutBar(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.active,
    builder: (context, _) {
      final active = state.active;
      if (active == null) return const SizedBox.shrink();
      // Aktuální cvik: první, který ještě nemá všechny série hotové.
      final current = active.exercises
          .where((e) => e.sets.isEmpty || e.sets.any((s) => !s.done))
          .firstOrNull;
      final done = active.exercises.fold(
        0,
        (n, e) => n + e.sets.where((s) => s.done).length,
      );
      final detail = current == null
          ? (active.exercises.isEmpty ? 'Přidej první cvik' : 'Vše hotovo')
          : state.exercise(current.exerciseId).name;
      // Lišta nesmí při velkém písmu sebrat půl obrazovky.
      return MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: _Bar(
          title: active.name,
          detail: detail,
          done: done,
          start: active.startedAt,
          restEndsAt: state.restEndsAt,
          onTap: () => openWorkout(context, state),
        ),
      );
    },
  );
}

class _Bar extends StatefulWidget {
  final String title;
  final String detail;
  final int done;
  final DateTime start;

  /// Konec běžící pauzy: lišta pak odpočítává pauzu místo času tréninku,
  /// takže je vidět i z jiné záložky.
  final DateTime? restEndsAt;
  final VoidCallback onTap;
  const _Bar({
    required this.title,
    required this.detail,
    required this.done,
    required this.start,
    required this.restEndsAt,
    required this.onTap,
  });

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Zbývající pauza, `null` když neběží.
  Duration? _restLeft() {
    final end = widget.restEndsAt;
    if (end == null) return null;
    final left = end.difference(DateTime.now());
    return left > Duration.zero ? left : null;
  }

  String _clock() {
    final rest = _restLeft();
    if (rest != null) {
      final s = (rest.inMilliseconds / 1000).ceil();
      return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }
    final d = DateTime.now().difference(widget.start);
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return m >= 60
        ? '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}:$s'
        : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final clock = _clock();
    final resting = _restLeft() != null;
    final detail = resting ? 'Pauza · ${widget.detail}' : widget.detail;
    final minutes = DateTime.now().difference(widget.start).inMinutes;
    final time = resting ? 'pauza $clock' : '$minutes min';
    return Semantics(
      button: true,
      label:
          'Běžící trénink ${widget.title}, $time, '
          '${widget.detail}, ${widget.done} sérií hotovo. Pokračovat',
      excludeSemantics: true,
      child: Material(
        color: p.elevated,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.accent, width: 2)),
            ),
            padding: const EdgeInsets.fromLTRB(Space.l, 10, Space.m, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: p.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Space.s),
                Text(
                  clock,
                  style: text.titleMedium?.copyWith(
                    color: p.accent,
                    fontFeatures: tabular,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Icon(Icons.chevron_right_rounded, color: p.secondaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
