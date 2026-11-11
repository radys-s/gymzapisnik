import 'package:flutter/material.dart';

import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../nutrition/nutrition_page.dart';

/// Jídlo dne na Domů: kalorie a bílkoviny proti cíli, nedávná jídla na
/// jedno klepnutí a čárový kód. Celý deník je ve Stravě.
class HomeFoodBlock extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const HomeFoodBlock({super.key, required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final key = dayKey(now);
    final totals = totalsOf(state.foodsOn(key));
    final own = state.profile;
    final suggested = own.proteinTarget == null && own.kcalTarget == null
        ? state.suggestedTargets
        : null;
    final kcalTarget = own.kcalTarget ?? suggested?.kcal;
    final proteinTarget = own.proteinTarget ?? suggested?.protein;
    final quick = state.quickFoods.take(4).toList();
    Widget ring(String label, double value, double? target, String unit) {
      final shown =
          '${value.round()}${target == null ? '' : ' / ${target.round()}'} $unit';
      return Expanded(
        child: Semantics(
          label: '$label $shown',
          excludeSemantics: true,
          child: Row(
            children: [
              ProgressRing(
                value: target == null || target <= 0 ? 0 : value / target,
                size: 44,
                stroke: 6,
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.labelMedium?.copyWith(
                        color: p.secondaryLabel,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        shown,
                        maxLines: 1,
                        style: text.titleSmall?.copyWith(fontFeatures: tabular),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Jídlo dnes', style: text.titleMedium)),
              IconButton(
                tooltip: 'Čárový kód',
                icon: const Icon(Icons.qr_code_2),
                onPressed: () => barcodeFlow(context, state, key),
              ),
              IconButton(
                tooltip: 'Deník jídla',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NutritionPage(state)),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              ring('Kalorie', totals.kcal, kcalTarget, 'kcal'),
              const SizedBox(width: Space.m),
              ring('Bílkoviny', totals.protein, proteinTarget, 'g'),
            ],
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final f in quick)
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    ),
                    tooltip: 'Přidat znovu: ${f.name}, ${amountLabel(f)}',
                    onPressed: () => quickAddFood(context, state, f, key),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
