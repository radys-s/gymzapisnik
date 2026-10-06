import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import 'barcode_dialog.dart';
import 'food_form.dart';

String _n(double v) => v.round().toString();

/// „12 g" nebo „–" (chybí).
String _g(double? v) => v == null ? '–' : '${_n(v)} g';

/// Popis snědeného množství: „150 g", „2 porce".
String amountLabel(FoodEntry e) {
  final a = formatKg(e.amount);
  if (e.basis == FoodBasis.perServing) {
    return e.amount == 1 ? '1 porce' : '$a porcí';
  }
  return '$a ${e.unit == FoodUnit.ml ? 'ml' : 'g'}';
}

String _dayTitle(DateTime day, DateTime now) {
  final diff = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(day.year, day.month, day.day)).inDays;
  if (diff == 0) return 'Dnes';
  if (diff == 1) return 'Včera';
  return formatDate(day);
}

/// Karta na úvodní obrazovce: dnešní energie, otevře deník.
class NutritionCard extends StatelessWidget {
  final AppState state;
  const NutritionCard(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final today = state.foodsOn(dayKey(DateTime.now()));
      final totals = totalsOf(today);
      return Card(
        child: ListTile(
          leading: const Icon(Icons.restaurant_outlined),
          title: Text(
            today.isEmpty
                ? 'Výživa'
                : '${totals.kcalMissing ? '≥ ' : ''}${_n(totals.kcal)} kcal dnes',
          ),
          subtitle: Text(
            today.isEmpty
                ? 'Zapiš si jídlo ručně nebo podle čárového kódu'
                : 'B ${_n(totals.protein)} g · S ${_n(totals.carbs)} g · '
                      'T ${_n(totals.fat)} g',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          trailing: IconButton(
            tooltip: 'Přidat jídlo',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () =>
                addFoodFlow(context, state, dayKey(DateTime.now())),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NutritionPage(state)),
          ),
        ),
      );
    },
  );
}

/// Zvolí způsob přidání (čárový kód / ručně / nedávné) a otevře formulář.
Future<void> addFoodFlow(
  BuildContext context,
  AppState state,
  String day,
) async {
  final choice = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: const Text('Najít podle čárového kódu'),
            subtitle: const Text('Open Food Facts, vyžaduje internet'),
            onTap: () => Navigator.pop(sheet, 'barcode'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Zadat ručně'),
            onTap: () => Navigator.pop(sheet, 'manual'),
          ),
          if (state.recentFoods.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Nedávná'),
            ),
            for (final f in state.recentFoods)
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(f.name),
                subtitle: Text(amountLabel(f)),
                onTap: () => Navigator.pop(sheet, f),
              ),
          ],
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'manual':
      await openFoodForm(context, state, day: day);
    case 'barcode':
      final outcome = await showBarcodeDialog(context, state.lookup);
      if (!context.mounted || outcome == null) return;
      await openFoodForm(
        context,
        state,
        day: day,
        product: outcome.product,
        barcode: outcome.barcode,
      );
    case FoodEntry recent:
      await openFoodForm(context, state, day: day, copyOf: recent);
  }
}

class NutritionPage extends StatefulWidget {
  final AppState state;

  /// Počáteční den (v testech); jinak dnes.
  final DateTime? initialDay;
  const NutritionPage(this.state, {super.key, this.initialDay});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late DateTime day = () {
    final d = widget.initialDay ?? DateTime.now();
    return DateTime(d.year, d.month, d.day);
  }();

  AppState get state => widget.state;

  bool get _isToday => dayKey(day) == dayKey(DateTime.now());

  void _shift(int days) =>
      setState(() => day = DateTime(day.year, day.month, day.day + days));

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: day.isAfter(now) ? now : day,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => day = picked);
  }

  Future<void> _delete(FoodEntry e) async {
    final messenger = ScaffoldMessenger.of(context);
    await state.removeFood(e.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Smazáno: ${e.name}'),
          action: SnackBarAction(
            label: 'Vrátit',
            onPressed: () => state.saveFood(e),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final key = dayKey(day);
      final entries = state.foodsOn(key);
      final totals = totalsOf(entries);
      final scheme = Theme.of(context).colorScheme;
      final text = Theme.of(context).textTheme;
      final anyMissing =
          entries.isNotEmpty &&
          (totals.kcalMissing ||
              totals.proteinMissing ||
              totals.carbsMissing ||
              totals.fatMissing);
      String lower(bool missing) => missing && entries.isNotEmpty ? '≥ ' : '';
      return Scaffold(
        appBar: AppBar(title: const Text('Výživa')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => addFoodFlow(context, state, key),
          icon: const Icon(Icons.add),
          label: const Text('Přidat jídlo'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Předchozí den',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _pick,
                    child: Text(
                      _dayTitle(day, DateTime.now()),
                      style: text.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Další den',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday ? null : () => _shift(1),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${lower(totals.kcalMissing)}${_n(totals.kcal)} kcal',
                      style: text.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bílkoviny ${lower(totals.proteinMissing)}'
                      '${_g(totals.protein)} · '
                      'Sacharidy ${lower(totals.carbsMissing)}'
                      '${_g(totals.carbs)} · '
                      'Tuky ${lower(totals.fatMissing)}${_g(totals.fat)}',
                    ),
                    if (anyMissing)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '≥ = u některého jídla hodnota chybí, skutečný '
                          'součet může být vyšší.',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Tento den nic nezapsáno.')),
              ),
            for (final e in entries)
              ListTile(
                title: Text(e.name),
                subtitle: Text(_subtitle(e)),
                onTap: () => openFoodForm(context, state, day: key, entry: e),
                trailing: IconButton(
                  tooltip: 'Smazat záznam',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(e),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Orientační hodnoty, žádné zdravotní doporučení. Údaje z '
              'čárových kódů pocházejí z databáze Open Food Facts (ODbL) '
              'a mohou být nepřesné.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    },
  );

  String _subtitle(FoodEntry e) {
    final v = e.eaten;
    final kcal = v.kcal == null ? '– kcal' : '${_n(v.kcal!)} kcal';
    return '${amountLabel(e)} · $kcal · B ${_g(v.protein)} · '
        'S ${_g(v.carbs)} · T ${_g(v.fat)}';
  }
}
