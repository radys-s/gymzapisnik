import 'package:flutter/material.dart';

import '../../ai/fridge_coach.dart';
import '../../core/ids.dart';
import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import '../design/tokens.dart';
import '../design/components.dart';
import 'fridge_page.dart';
import 'food_form.dart';

double? _r(double? v) => v == null ? null : double.parse(v.toStringAsFixed(0));
String _value(double? v) => v == null ? '–' : '${v.round()}';

/// Návrhy jídel z ledničky. Jen inspirace: nic se nezapíše bez potvrzení.
class MealIdeasPage extends StatelessWidget {
  final AppState state;
  final List<MealIdea> meals;
  const MealIdeasPage(this.state, this.meals, {super.key});

  Future<void> _log(BuildContext context, MealIdea meal) async {
    final now = DateTime.now();
    final day = dayKey(now);
    final saved = await openFoodForm(
      context,
      state,
      day: day,
      copyOf: FoodEntry(
        id: newId(),
        day: day,
        loggedAt: now,
        name: meal.title,
        basis: FoodBasis.perServing,
        amount: 1,
        values: Nutrition(
          kcal: _r(meal.estimate.kcal),
          protein: _r(meal.estimate.protein),
          carbs: _r(meal.estimate.carbs),
          fat: _r(meal.estimate.fat),
        ),
      ),
    );
    if (saved && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Zapsáno: ${meal.title}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Návrhy jídel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          for (final meal in meals)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.title, style: text.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.minutes} min · ${_value(meal.estimate.kcal)} kcal'
                      ' · B ${_value(meal.estimate.protein)} g'
                      ' · S ${_value(meal.estimate.carbs)} g'
                      ' · T ${_value(meal.estimate.fat)} g',
                    ),
                    Text(
                      meal.source == EstimateSource.table
                          ? 'Odhad podle tabulky potravin'
                          : 'Odhad AI, může být hodně nepřesný',
                      style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                    ),
                    const SizedBox(height: 8),
                    Text('Suroviny', style: text.labelLarge),
                    for (final i in meal.ingredients)
                      Text(
                        '• ${i.name}'
                        '${itemAmount(i).isEmpty ? '' : ' – ${itemAmount(i)}'}',
                      ),
                    const SizedBox(height: 8),
                    Text('Postup', style: text.labelLarge),
                    for (final (n, step) in meal.steps.indexed)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('${n + 1}. $step'),
                      ),
                    const SizedBox(height: Space.l),
                    SecondaryButton(
                      'Zapsat do deníku',
                      icon: Icons.add,
                      onPressed: () => _log(context, meal),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Návrhy vytvořila AI z tvého seznamu. Jsou to nápady, ne výživové '
            'ani zdravotní doporučení. Zkontroluj suroviny a hodnoty.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}
