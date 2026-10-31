import 'package:flutter/material.dart';

import '../../coach/nutrition_target.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import '../bodyweight/bodyweight_page.dart';
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
  // Jídlo po půlnoci patří k noci, ne k ranní snídani.
  if (t < 4 * 60) return 'V noci';
  if (t < 10 * 60 + 30) return 'Snídaně';
  if (t < 14 * 60 + 30) return 'Oběd';
  if (t < 17 * 60 + 30) return 'Svačina';
  return 'Večeře';
}

const _meals = ['Snídaně', 'Oběd', 'Svačina', 'Večeře', 'V noci'];

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
          if (state.quickFoods.isNotEmpty)
            ListenableBuilder(
              listenable: state,
              builder: (sheet, _) => GroupedSection(
                header: 'Oblíbená a nedávná',
                footer: 'Hvězdičkou jídlo připneš do Rychle přidat.',
                children: [
                  for (final f in state.quickFoods)
                    GroupedRow(
                      icon: state.isFavoriteFood(f)
                          ? Icons.star_rounded
                          : Icons.history,
                      title: f.name,
                      subtitle: amountLabel(f),
                      onTap: () => Navigator.pop(sheet, f),
                      chevron: false,
                      trailing: _FavoriteButton(state, f),
                    ),
                ],
              ),
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

  Future<void> _toggleFavorite(FoodEntry f) async {
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final pinned = await state.toggleFavoriteFood(f);
      message = pinned
          ? 'Připnuto mezi oblíbená: ${f.name}'
          : 'Odepnuto z oblíbených: ${f.name}';
    } catch (_) {
      message = 'Oblíbená se nepodařilo uložit. Zkus to znovu.';
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          _Summary(state, totals: totals, empty: entries.isEmpty),
          if (anyMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
              child: Text(
                '≥ = u některého jídla hodnota chybí, skutečný '
                'součet může být vyšší.',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
          if (state.quickFoods.isNotEmpty) ...[
            const SectionHeader('Rychle přidat'),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final f in state.quickFoods.take(8))
                  GestureDetector(
                    onLongPress: () => _toggleFavorite(f),
                    child: ActionChip(
                      avatar: Icon(
                        state.isFavoriteFood(f)
                            ? Icons.star_rounded
                            : Icons.add_rounded,
                        size: 18,
                      ),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(f.name, overflow: TextOverflow.ellipsis),
                      ),
                      tooltip: '${f.name}, ${amountLabel(f)}',
                      onPressed: () => _quickAdd(f, key),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.xs,
                Space.s,
                Space.xs,
                0,
              ),
              child: Text(
                'Podržením jídlo připneš mezi oblíbená (hvězdička).',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
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

/// Souhrn dne: kruhy k cílům, pod nimi makra. Bez vlastního cíle kruhy
/// ukazují doporučení z tělesné váhy, které jde jedním klepnutím přijmout.
class _Summary extends StatelessWidget {
  final AppState state;
  final DayTotals totals;
  final bool empty;
  const _Summary(this.state, {required this.totals, required this.empty});

  Future<void> _useSuggested(BuildContext context, SuggestedTargets s) async {
    try {
      await state.setNutritionTargets(protein: s.protein, kcal: s.kcal);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Cíl se nepodařilo uložit. Zkus to znovu.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final own = state.profile;
    final suggested = own.proteinTarget == null && own.kcalTarget == null
        ? state.suggestedTargets
        : null;
    final proteinTarget = own.proteinTarget ?? suggested?.protein;
    final kcalTarget = own.kcalTarget ?? suggested?.kcal;
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
          if (rings.isNotEmpty && p.tensor) ...[
            _RingStack(
              kcal: kcalTarget == null ? null : (totals.kcal, kcalTarget),
              protein: proteinTarget == null
                  ? null
                  : (totals.protein, proteinTarget),
            ),
            const SizedBox(height: Space.l),
          ] else if (rings.isNotEmpty) ...[
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
          if (suggested != null) ...[
            const SizedBox(height: Space.s),
            _NoteWithAction(
              children: [
                Flexible(
                  child: Text(
                    'Doporučeno z tvé váhy '
                    '${formatKg(state.bodyweights.first.kg)} kg.',
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ),
                TextButton(
                  onPressed: () => _useSuggested(context, suggested),
                  child: const Text('Nastavit jako cíl'),
                ),
              ],
            ),
          ] else if (rings.isEmpty) ...[
            const SizedBox(height: Space.s),
            _NoteWithAction(
              children: [
                Flexible(
                  child: Text(
                    'Zapiš tělesnou váhu a doporučím ti cíl bílkovin.',
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BodyweightPage(state)),
                  ),
                  child: const Text('Zapsat váhu'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Tensor: soustředné kruhy jako u hodinek, energie venku, bílkoviny
/// uvnitř. Vedle legenda s čísly, ať je vidět, kolik zbývá.
class _RingStack extends StatelessWidget {
  final (double, double)? kcal;
  final (double, double)? protein;
  const _RingStack({this.kcal, this.protein});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = [
      if (kcal case (final v, final t)) ('Energie', v, t, 'kcal', p.gradient),
      if (protein case (final v, final t))
        (
          'Bílkoviny',
          v,
          t,
          'g',
          const [AppPalette.tensorCyan, Color(0xFF7BE4FF)],
        ),
    ];
    const outer = 132.0, stroke = 14.0;
    return Row(
      children: [
        SizedBox.square(
          dimension: outer,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < rows.length; i++)
                ProgressRing(
                  value: rows[i].$2 / rows[i].$3,
                  size: outer - i * (stroke + 6) * 2,
                  stroke: stroke,
                  colors: rows[i].$5,
                ),
            ],
          ),
        ),
        const SizedBox(width: Space.l),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, v, t, unit, colors) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _RingLegend(
                    label: label,
                    value: v,
                    target: t,
                    unit: unit,
                    color: colors.first,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingLegend extends StatelessWidget {
  final String label;
  final double value;
  final double target;
  final String unit;
  final Color color;
  const _RingLegend({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = target - value;
    return Semantics(
      label:
          '$label ${_n(value)} z ${_n(target)} $unit'
          '${left > 0 ? ', zbývá ${_n(left)}' : ', cíl splněn'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: condensedFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.6,
                  color: p.secondaryLabel,
                ),
              ),
            ],
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _n(value),
                  style: TextStyle(
                    fontFamily: condensedFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: p.label,
                    fontFeatures: tabular,
                  ),
                ),
                TextSpan(
                  text: ' / ${_n(target)} $unit',
                  style: TextStyle(
                    fontFamily: condensedFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: p.tertiaryLabel,
                    fontFeatures: tabular,
                  ),
                ),
              ],
            ),
          ),
          Text(
            left > 0 ? 'zbývá ${_n(left)} $unit' : 'cíl splněn',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: left > 0 ? p.secondaryLabel : p.positive),
          ),
        ],
      ),
    );
  }
}

/// Poznámka s tlačítkem vedle; při velkém písmu tlačítko spadne pod text.
class _NoteWithAction extends StatelessWidget {
  final List<Widget> children;
  const _NoteWithAction({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context).scale(1);
      if (scale <= 1.3 && c.maxWidth >= 320) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final w in children) w is Flexible ? w.child : w],
      );
    },
  );
}

/// Hvězdička: připne jídlo do Rychle přidat, nebo ho odepne.
class _FavoriteButton extends StatelessWidget {
  final AppState state;
  final FoodEntry food;
  const _FavoriteButton(this.state, this.food);

  @override
  Widget build(BuildContext context) {
    final on = state.isFavoriteFood(food);
    return IconButton(
      tooltip: on ? 'Odepnout z oblíbených' : 'Připnout mezi oblíbená',
      isSelected: on,
      icon: Icon(
        on ? Icons.star_rounded : Icons.star_outline_rounded,
        color: on ? context.palette.accent : context.palette.secondaryLabel,
      ),
      onPressed: () async {
        try {
          await state.toggleFavoriteFood(food);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Oblíbená se nepodařilo uložit. Zkus to znovu.'),
              ),
            );
          }
        }
      },
    );
  }
}
