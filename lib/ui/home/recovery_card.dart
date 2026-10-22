import 'package:flutter/material.dart';

import '../../coach/recovery.dart';
import '../../coach/splits.dart';
import '../../coach/tips.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'body_map.dart';

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
    final tired = [
      for (final f in dayFocuses)
        if (recovery[f.id] case final r? when !r.isReady) r,
    ];
    final avoid = [for (final r in tired) r.focusId];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: BodyMap(
              recovery: recovery,
              names: names,
              status: (r) => r.isReady
                  ? 'odpočaté'
                  : 'regeneruje, ${recoveryLeftLabel(r, now)}',
              onTap: (id) => _detail(
                context,
                id,
                recovery[id],
                weekly[id] ?? 0,
                names,
                avoid,
              ),
            ),
          ),
          const SizedBox(height: Space.m),
          ExcludeSemantics(
            child: Wrap(
              spacing: Space.l,
              runSpacing: Space.xs,
              children: [
                for (final (color, label) in [
                  (p.positive, 'odpočaté'),
                  (recoveringColor, 'regeneruje'),
                ])
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(color),
                      const SizedBox(width: Space.xs),
                      Text(label, style: text.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.s),
          Text(
            tired.isEmpty
                ? 'Všechny partie jsou odpočaté. Klepni na partii pro detail.'
                : 'Regeneruje: ${tired.map((r) => '${names[r.focusId]} ${recoveryLeftLabel(r, now)}').join(', ')}. '
                      'Odhad podle posledních 3 dnů.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          if (suggested.isNotEmpty) ...[
            const SizedBox(height: Space.l),
            SecondaryButton(
              'Sestavit z odpočatých',
              icon: Icons.auto_awesome_rounded,
              onPressed: () => onBuild(suggested, avoid),
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

  void _detail(
    BuildContext context,
    String id,
    FocusRecovery? r,
    int sets,
    Map<String, String> names,
    List<String> avoid,
  ) {
    final name = names[id] ?? id;
    final ready = r == null || r.isReady;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        final p = sheet.palette;
        final text = Theme.of(sheet).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              0,
              Space.page,
              Space.l,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(name, style: text.titleLarge),
                const SizedBox(height: Space.xs),
                Text(
                  ready
                      ? 'Odpočaté, můžeš ji dnes trénovat.'
                      : 'Ještě regeneruje, připravená ${recoveryLeftLabel(r, now)}.',
                  style: text.bodyLarge?.copyWith(
                    color: ready ? p.positive : recoveringColor,
                  ),
                ),
                const SizedBox(height: Space.s),
                Text(
                  // Série se počítají jen jako hlavní partie; únava může
                  // přijít i z cviků, kde partie jen pomáhá.
                  sets == 0
                      ? (ready
                            ? 'Za posledních 7 dní na ni nemáš žádnou sérii.'
                            : 'Unavená z cviků, ve kterých pomáhá.')
                      : 'Za posledních 7 dní: $sets ${_sets(sets)}. '
                            'Pro růst se hodí zhruba 10–20 týdně.',
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
                const SizedBox(height: Space.l),
                if (ready)
                  PrimaryButton(
                    'Sestavit trénink: $name',
                    onPressed: () {
                      Navigator.pop(sheet);
                      onBuild([id], avoid);
                    },
                  )
                else
                  Text(
                    'Dej jí čas. Těžký trénink na unavenou partii '
                    'přidá víc únavy než růstu.',
                    style: text.bodyMedium,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _sets(int n) => n < 5 ? 'pracovní série' : 'pracovních sérií';
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
