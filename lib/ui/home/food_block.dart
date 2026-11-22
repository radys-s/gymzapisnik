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
    Widget stat(
      String label,
      double value,
      double? target,
      String unit,
      Color color,
      IconData icon,
    ) {
      final progress = target == null || target <= 0
          ? 0.0
          : (value / target).clamp(0.0, 1.0);
      final shown =
          '${value.round()}${target == null ? '' : ' / ${target.round()}'} $unit';
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(Space.m),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: text.labelMedium?.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                shown,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: p.fill,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Panel(
      tone: Tone.food,
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppPalette.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant_rounded, color: AppPalette.orange),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jídlo dnes', style: text.titleMedium),
                    Text(
                      totals.kcal <= 0
                          ? 'Zapiš první jídlo a drž palivo pod kontrolou'
                          : 'Kalorie a bílkoviny na dnešek',
                      style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Čárový kód',
                color: p.secondaryLabel,
                icon: const Icon(Icons.qr_code_2),
                onPressed: () => barcodeFlow(context, state, key),
              ),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => NutritionPage(state)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Přidat'),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Row(
            children: [
              stat('Kalorie', totals.kcal, kcalTarget, 'kcal', AppPalette.orange, Icons.local_fire_department_rounded),
              const SizedBox(width: Space.s),
              stat('Bílkoviny', totals.protein, proteinTarget, 'g', AppPalette.blue, Icons.fitness_center_rounded),
            ],
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
