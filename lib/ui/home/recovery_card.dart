import 'package:flutter/material.dart';

import '../../coach/recovery.dart';
import '../../coach/splits.dart';
import '../../coach/tips.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Kolik zbývá do připravenosti („za 20 h“).
String recoveryLeftLabel(FocusRecovery r, DateTime now) {
  final at = r.readyAt;
  if (at == null) return 'připraveno';
  final hours = (at.difference(now).inMinutes / 60).ceil();
  return hours <= 1 ? 'za hodinu' : 'za $hours h';
}

/// Regenerace partií a rychlé sestavení tréninku z odpočatých.
class RecoveryPanel extends StatelessWidget {
  final AppState state;
  final DateTime now;
  final void Function(List<String> focuses, List<String> avoid) onBuild;
  const RecoveryPanel({
    super.key,
    required this.state,
    required this.now,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final recovery = recoveryByFocus(
      state.workouts,
      now,
      muscleOf: (id) => state.exercise(id).muscle,
    );
    final weekly = weeklyHardSets(
      state.workouts,
      now,
      (id) => state.exercise(id).muscle,
    );
    final suggested = suggestFocuses(recovery, weekly);
    final names = {for (final f in dayFocuses) f.id: f.name};
    final tired = recovery.values.where((r) => !r.isReady).length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tired == 0
                ? 'Všechny partie jsou odpočaté.'
                : 'Fajfka = odpočaté, přesýpací hodiny = ještě regeneruje. '
                      'Odhad podle posledních 3 dnů.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final f in dayFocuses)
                if (recovery[f.id] case final r?)
                  Semantics(
                    label:
                        '${f.name}: ${r.isReady ? 'odpočaté' : 'regeneruje, ${recoveryLeftLabel(r, now)}'}',
                    child: ExcludeSemantics(
                      child: Pill(
                        r.isReady
                            ? f.name
                            : '${f.name} · ${recoveryLeftLabel(r, now)}',
                        icon: r.isReady
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_bottom_rounded,
                        color: r.isReady ? p.positive : const Color(0xFFFF9F0A),
                      ),
                    ),
                  ),
            ],
          ),
          if (suggested.isNotEmpty) ...[
            const SizedBox(height: Space.l),
            SecondaryButton(
              'Sestavit z odpočatých',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => onBuild(suggested, [
                for (final r in recovery.values)
                  if (!r.isReady) r.focusId,
              ]),
            ),
            const SizedBox(height: Space.xs),
            Text(
              'Návrh: ${suggested.map((id) => names[id]).join(', ')}',
              style: text.bodySmall?.copyWith(color: p.secondaryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
