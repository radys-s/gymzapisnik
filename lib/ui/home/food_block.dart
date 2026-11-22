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
    final suggested = state.suggestedTargets;
    final kcalTarget = own.kcalTarget ?? suggested?.kcal;
    final proteinTarget = own.proteinTarget ?? suggested?.protein;
    final quick = state.quickFoods.take(4).toList();
    Widget stat(String label, double value, double? target, String unit) {
      final progress = target == null || target <= 0
          ? 0.0
          : (value / target).clamp(0.0, 1.0);
      final left = target == null ? null : (target - value).round();
      return Expanded(
        child: Semantics(
          label:
              '$label ${value.round()}'
              '${target == null ? '' : ' z ${target.round()}'} $unit',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: text.labelSmall?.copyWith(
                  color: p.secondaryLabel,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${value.round()}'),
                      TextSpan(
                        text: target == null
                            ? ' $unit'
                            : ' / ${target.round()} $unit',
                        style: TextStyle(fontSize: 18, color: p.tertiaryLabel),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontFamily: condensedFont,
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: p.label,
                    fontFeatures: tabular,
                  ),
                ),
              ),
              const SizedBox(height: Space.s),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: p.fill,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1 ? p.positive : p.accent,
                  ),
                ),
              ),
              const SizedBox(height: Space.xs),
              Text(
                left == null
                    ? 'bez cíle'
                    : left > 0
                    ? 'zbývá $left $unit'
                    : 'cíl splněn',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      );
    }

    return Panel(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 20, color: p.accent),
              const SizedBox(width: Space.s),
              Expanded(child: Text('Jídlo dnes', style: text.titleMedium)),
              IconButton(
                tooltip: 'Čárový kód',
                color: p.secondaryLabel,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () => barcodeFlow(context, state, key),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NutritionPage(state)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Přidat'),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Padding(
            padding: const EdgeInsets.only(right: Space.s),
            child: Row(
              children: [
                stat('Kalorie', totals.kcal, kcalTarget, 'kcal'),
                const SizedBox(width: Space.xl),
                stat('Bílkoviny', totals.protein, proteinTarget, 'g'),
              ],
            ),
          ),
          if (quick.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            Text(
              'Rychlé přidání',
              style: text.labelLarge?.copyWith(color: p.secondaryLabel),
            ),
            const SizedBox(height: Space.s),
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
