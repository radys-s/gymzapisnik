import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/ids.dart';
import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../settings/settings_button.dart';
import 'barcode_dialog.dart';
import 'food_form.dart';
import 'fridge_page.dart';

String _n(double v) => v.round().toString();

/// „12 g" nebo „–" (chybí).
String _g(double? v) => v == null ? '–' : '${_n(v)} g';

/// Popis snědeného množství: „150 g", „2 porce".
String amountLabel(FoodEntry e) {
  final a = formatKg(e.amount);
  if (e.basis == FoodBasis.perServing) {
    // 1 porce, 2–4 porce, 5 porcí; desetinné množství je „porce" (2,5 porce).
    final whole = e.amount == e.amount.roundToDouble();
    final n = e.amount.round();
    return !whole || (n >= 1 && n <= 4) ? '$a porce' : '$a porcí';
  }
  return '$a ${e.unit == FoodUnit.ml ? 'ml' : 'g'}';
}

String _dayTitle(DateTime day, DateTime now) {
  final diff = calendarDaysBetween(day, now);
  if (diff == 0) return 'Dnes';
  if (diff == 1) return 'Včera';
  return formatDate(day);
}

/// Část dne podle času zápisu (pro skupiny v deníku).
String mealOf(DateTime at) {
  final t = at.hour * 60 + at.minute;
  if (t < 10 * 60 + 30) return 'Snídaně';
  if (t < 14 * 60 + 30) return 'Oběd';
  if (t < 17 * 60 + 30) return 'Svačina';
  return 'Večeře';
}

const _meals = ['Snídaně', 'Oběd', 'Svačina', 'Večeře'];

/// Zvolí způsob přidání (čárový kód / ručně / nedávné) a otevře formulář.
Future<void> addFoodFlow(
  BuildContext context,
  AppState state,
  String day,
) async {
  final choice = await showModalBottomSheet<Object>(
    context: context,
    // Nad spodní lištou, ne uvnitř záložky (jinak by zůstal viset po přepnutí).
    useRootNavigator: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
        children: [
          GroupedSection(
            children: [
              GroupedRow(
                icon: Icons.qr_code_2,
                title: 'Najít podle čárového kódu',
                subtitle: 'Open Food Facts, vyžaduje internet',
                onTap: () => Navigator.pop(sheet, 'barcode'),
              ),
              GroupedRow(
                icon: Icons.edit_outlined,
                title: 'Zadat ručně',
                onTap: () => Navigator.pop(sheet, 'manual'),
              ),
            ],
          ),
          if (state.recentFoods.isNotEmpty)
            GroupedSection(
              header: 'Nedávná',
              children: [
                for (final f in state.recentFoods)
                  GroupedRow(
                    icon: Icons.history,
                    title: f.name,
                    subtitle: amountLabel(f),
                    onTap: () => Navigator.pop(sheet, f),
                  ),
              ],
            ),
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

  /// Kořen záložky Strava (nadpis a nastavení), jinak vnořená stránka.
  final bool root;
  const NutritionPage(
    this.state, {
    super.key,
    this.initialDay,
    this.root = false,
  });

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

  /// Stejné jídlo ve stejném množství jedním klepnutím, s možností vrátit.
  Future<void> _quickAdd(FoodEntry f, String key) async {
    final messenger = ScaffoldMessenger.of(context);
    // Jiný den: stejná část dne jako původní jídlo.
    final at = loggedAtFor(key, DateTime.now(), timeOf: f.loggedAt.toLocal());
    final entry = FoodEntry(
      id: newId(),
      day: key,
      loggedAt: at,
      name: f.name,
      brand: f.brand,
      barcode: f.barcode,
      basis: f.basis,
      unit: f.unit,
      amount: f.amount,
      values: f.values,
    );
    final error = await state.saveFood(entry);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Přidáno: ${f.name}, ${amountLabel(f)}'),
          action: error != null
              ? null
              : SnackBarAction(
                  label: 'Vrátit',
                  onPressed: () => state.removeFood(entry.id),
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
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      // Skupiny podle části dne, v každé od nejstaršího.
      final byMeal = <String, List<FoodEntry>>{};
      for (final e in entries.reversed) {
        (byMeal[mealOf(e.loggedAt.toLocal())] ??= []).add(e);
      }
      final anyMissing =
          entries.isNotEmpty &&
          (totals.kcalMissing ||
              totals.proteinMissing ||
              totals.carbsMissing ||
              totals.fatMissing);
      String lower(bool missing) => missing && entries.isNotEmpty ? '≥ ' : '';
      return LargeTitlePage(
        title: widget.root ? 'Strava' : 'Výživa',
        actions: [if (widget.root) SettingsButton(state)],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => addFoodFlow(context, state, key),
          icon: const Icon(Icons.add),
          label: const Text('Přidat jídlo'),
        ),
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 96),
        children: [
          Panel(
            padding: const EdgeInsets.all(Space.xs),
            child: Row(
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
          ),
          const SizedBox(height: Space.m),
          _Summary(
            totals: totals,
            empty: entries.isEmpty,
            proteinTarget: state.profile.proteinTarget,
            kcalTarget: state.profile.kcalTarget,
          ),
          if (anyMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
              child: Text(
                '≥ = u některého jídla hodnota chybí, skutečný '
                'součet může být vyšší.',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
          if (state.recentFoods.isNotEmpty) ...[
            const SectionHeader('Rychle přidat'),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final f in state.recentFoods.take(6))
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 18),
                    label: Text(f.name),
                    tooltip: '${f.name}, ${amountLabel(f)}',
                    onPressed: () => _quickAdd(f, key),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.xxl),
          GroupedSection(
            children: [
              GroupedRow(
                icon: Icons.kitchen_outlined,
                title: 'Co mám v ledničce',
                subtitle: 'Vyfoť ledničku a nech si navrhnout jídlo',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FridgePage(state)),
                ),
              ),
            ],
          ),
          if (entries.isEmpty)
            const EmptyState(
              icon: Icons.restaurant_outlined,
              title: 'Tento den nic nezapsáno.',
              message: 'Jídlo přidáš tlačítkem dole nebo čárovým kódem.',
            )
          else
            for (final meal in _meals)
              if (byMeal[meal] case final list?)
                GroupedSection(
                  header:
                      '$meal · ${lower(totalsOf(list).kcalMissing)}'
                      '${_n(totalsOf(list).kcal)} kcal',
                  children: [
                    for (final e in list)
                      GroupedRow(
                        title: e.name,
                        subtitle: _subtitle(e),
                        onTap: () =>
                            openFoodForm(context, state, day: key, entry: e),
                        chevron: false,
                        trailing: IconButton(
                          tooltip: 'Smazat záznam',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(e),
                        ),
                      ),
                  ],
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(
              'Orientační hodnoty, žádné zdravotní doporučení. Údaje z '
              'čárových kódů pocházejí z databáze Open Food Facts (ODbL) '
              'a mohou být nepřesné.',
              style: text.bodySmall?.copyWith(color: p.secondaryLabel),
            ),
          ),
        ],
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

/// Souhrn dne: kruhy k vlastním cílům (jsou-li), pod nimi makra.
class _Summary extends StatelessWidget {
  final DayTotals totals;
  final bool empty;
  final double? proteinTarget;
  final double? kcalTarget;
  const _Summary({
    required this.totals,
    required this.empty,
    required this.proteinTarget,
    required this.kcalTarget,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    String lower(bool missing) => missing && !empty ? '≥ ' : '';
    Widget ring(String label, double value, double target, String unit) {
      final left = target - value;
      return Expanded(
        child: Semantics(
          label:
              '$label ${_n(value)} z ${_n(target)} $unit'
              '${left > 0 ? ', zbývá ${_n(left)}' : ', cíl splněn'}',
          child: ExcludeSemantics(
            child: Column(
              children: [
                ProgressRing(
                  value: value / target,
                  size: 104,
                  stroke: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(Space.m),
                    child: FittedBox(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _n(value),
                            style: text.titleLarge?.copyWith(
                              fontFeatures: tabular,
                            ),
                          ),
                          Text(
                            'z ${_n(target)} $unit',
                            style: text.labelSmall?.copyWith(
                              color: p.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Space.s),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, style: text.labelLarge, maxLines: 1),
                ),
                Text(
                  left > 0 ? 'zbývá ${_n(left)} $unit' : 'cíl splněn',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: left > 0 ? p.secondaryLabel : p.positive,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final rings = [
      if (proteinTarget case final t?)
        ring('Bílkoviny', totals.protein, t, 'g'),
      if (kcalTarget case final t?) ring('Energie', totals.kcal, t, 'kcal'),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rings.isNotEmpty) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: rings),
            const SizedBox(height: Space.l),
          ],
          Row(
            children: [
              for (final (value, label) in [
                ('${lower(totals.kcalMissing)}${_n(totals.kcal)}', 'kcal'),
                (
                  '${lower(totals.proteinMissing)}${_g(totals.protein)}',
                  'bílkoviny',
                ),
                (
                  '${lower(totals.carbsMissing)}${_g(totals.carbs)}',
                  'sacharidy',
                ),
                ('${lower(totals.fatMissing)}${_g(totals.fat)}', 'tuky'),
              ])
                Expanded(child: StatTile(value, label)),
            ],
          ),
          if (rings.isEmpty) ...[
            const SizedBox(height: Space.s),
            Text(
              'Cíl bílkovin si můžeš nastavit v Nastavení.',
              style: text.bodySmall?.copyWith(color: p.secondaryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
