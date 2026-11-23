import 'package:flutter/material.dart';

import '../../coach/nutrition_target.dart';
import '../../core/format.dart';
import '../../core/i18n.dart';
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
    if (isEnglish) return e.amount == 1 ? '$a serving' : '$a servings';
    return !whole || (n >= 1 && n <= 4) ? '$a porce' : '$a porcí';
  }
  return '$a ${e.unit == FoodUnit.ml ? 'ml' : 'g'}';
}

String _dayTitle(DateTime day, DateTime now) {
  final diff = calendarDaysBetween(day, now);
  if (diff == 0) return tr('Dnes', 'Today');
  if (diff == 1) return tr('Včera', 'Yesterday');
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

/// Typický čas jídla, když se přidává do jiné části dne než právě teď.
const _mealTimes = {
  'Snídaně': (8, 0),
  'Oběd': (12, 30),
  'Svačina': (16, 0),
  'Večeře': (19, 0),
  'V noci': (1, 0),
};

/// Display name for a meal key returned by [mealOf].
String mealLabel(String key) => switch (key) {
  'Snídaně' => tr('Snídaně', 'Breakfast'),
  'Oběd' => tr('Oběd', 'Lunch'),
  'Svačina' => tr('Svačina', 'Snack'),
  'Večeře' => tr('Večeře', 'Dinner'),
  'V noci' => tr('V noci', 'Late night'),
  _ => key,
};

String mealAddLabel(String key) => switch (key) {
  'Snídaně' => tr('Přidat ke snídani', 'Add to breakfast'),
  'Oběd' => tr('Přidat k obědu', 'Add to lunch'),
  'Svačina' => tr('Přidat ke svačině', 'Add to snack'),
  'Večeře' => tr('Přidat k večeři', 'Add to dinner'),
  'V noci' => tr('Přidat k jídlu v noci', 'Add to late-night food'),
  _ => key,
};

/// Čas nového záznamu v části dne [meal]: dnes v ní právě jsme → teď,
/// jinak typický čas té části dne.
DateTime mealTime(String day, String meal, DateTime now) {
  if (dayKey(now) == day && mealOf(now) == meal) return now;
  final d = parseDayKey(day) ?? now;
  final (h, m) = _mealTimes[meal] ?? (now.hour, now.minute);
  return DateTime(d.year, d.month, d.day, h, m);
}

/// Najde jídlo podle čárového kódu a otevře formulář.
Future<void> barcodeFlow(
  BuildContext context,
  AppState state,
  String day, {
  DateTime? at,
}) async {
  final outcome = await showBarcodeDialog(context, state.lookup);
  if (!context.mounted || outcome == null) return;
  await openFoodForm(
    context,
    state,
    day: day,
    product: outcome.product,
    barcode: outcome.barcode,
    at: at,
  );
}

/// Zvolí způsob přidání (čárový kód / ručně / nedávné) a otevře formulář.
/// [at] je čas nového jídla, když se přidává do konkrétní části dne.
Future<void> addFoodFlow(
  BuildContext context,
  AppState state,
  String day, {
  DateTime? at,
}) async {
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
                title: tr('Najít podle čárového kódu', 'Search by barcode'),
                subtitle: tr(
                  'Open Food Facts, vyžaduje internet',
                  'Open Food Facts, requires internet',
                ),
                onTap: () => Navigator.pop(sheet, 'barcode'),
              ),
              GroupedRow(
                icon: Icons.edit_outlined,
                title: tr('Zadat ručně', 'Enter manually'),
                onTap: () => Navigator.pop(sheet, 'manual'),
              ),
            ],
          ),
          if (state.quickFoods.isNotEmpty)
            ListenableBuilder(
              listenable: state.on.resting,
              builder: (sheet, _) => GroupedSection(
                header: tr('Oblíbená a nedávná', 'Favorites and recent'),
                footer: tr(
                  'Hvězdičkou jídlo připneš do Rychle přidat.',
                  'Tap the star to pin food to Quick add.',
                ),
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
      await openFoodForm(context, state, day: day, at: at);
    case 'barcode':
      await barcodeFlow(context, state, day, at: at);
    case FoodEntry recent:
      await openFoodForm(context, state, day: day, copyOf: recent, at: at);
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
  late DateTime day = _dateOf(widget.initialDay ?? DateTime.now());

  /// Zobrazený den je dnešek: po půlnoci se posune na nový den, aby se
  /// jídlo nezapsalo ke včerejšku.
  late bool _followsToday = _isToday;

  AppState get state => widget.state;

  static DateTime _dateOf(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _isToday => dayKey(day) == dayKey(DateTime.now());

  void _show(DateTime next) => setState(() {
    day = _dateOf(next);
    _followsToday = _isToday;
  });

  void _shift(int days) => _show(DateTime(day.year, day.month, day.day + days));

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: day.isAfter(now) ? now : day,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) _show(picked);
  }

  Future<void> _delete(FoodEntry e) async {
    final messenger = ScaffoldMessenger.of(context);
    await state.removeFood(e.id);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(tr('Smazáno: ${e.name}', 'Deleted: ${e.name}')),
          action: SnackBarAction(
            label: tr('Vrátit', 'Undo'),
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
          ? tr(
              'Připnuto mezi oblíbená: ${f.name}',
              'Pinned to favorites: ${f.name}',
            )
          : tr(
              'Odepnuto z oblíbených: ${f.name}',
              'Removed from favorites: ${f.name}',
            );
    } catch (_) {
      message = tr(
        'Oblíbená se nepodařilo uložit. Zkus to znovu.',
        'Could not save favorites. Try again.',
      );
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _quickAdd(FoodEntry f, String key) =>
      quickAddFood(context, state, f, key);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      if (_followsToday && !_isToday) day = _dateOf(DateTime.now());
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
        title: tr('Strava', 'Nutrition'),
        tone: Tone.food,
        actions: [if (widget.root) SettingsButton(state)],
        padding: const EdgeInsets.fromLTRB(Space.page, Space.s, Space.page, 96),
        children: [
          Panel(
            padding: const EdgeInsets.all(Space.xs),
            child: Row(
              children: [
                IconButton(
                  tooltip: tr('Předchozí den', 'Previous day'),
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
                  tooltip: tr('Další den', 'Next day'),
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday ? null : () => _shift(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          _Summary(state, totals: totals, empty: entries.isEmpty),
          const SizedBox(height: Space.m),
          // Zápis jídla nahoře, nápady (AI lednička) až pod jídly dne.
          _EntryTile(
            icon: Icons.qr_code_2,
            title: tr('Čárový kód', 'Barcode'),
            subtitle: tr('Najdi jídlo v databázi', 'Find food in the database'),
            onTap: () => barcodeFlow(context, state, key),
          ),
          if (anyMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
              child: Text(
                tr(
                  '≥ = u některého jídla hodnota chybí, skutečný '
                      'součet může být vyšší.',
                  '≥ = a value is missing for some food, the real total '
                      'may be higher.',
                ),
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
          if (state.quickFoods.isNotEmpty) ...[
            SectionHeader(tr('Rychle přidat', 'Quick add')),
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
                tr(
                  'Podržením jídlo připneš mezi oblíbená (hvězdička).',
                  'Long-press a food to pin it to favorites (star).',
                ),
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
          ],
          const SizedBox(height: Space.xxl),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
              child: Text(
                tr('Tento den nic nezapsáno.', 'Nothing logged for this day.'),
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
            ),
          // Čtyři jídla dne vždy, noc jen když v ní něco je.
          for (final meal in _meals)
            if (meal != 'V noci' || byMeal.containsKey(meal))
              GroupedSection(
                header: switch (byMeal[meal]) {
                  final list? => tr(
                    '$meal · ${lower(totalsOf(list).kcalMissing)}'
                        '${_n(totalsOf(list).kcal)} kcal',
                    '${mealLabel(meal)} · ${lower(totalsOf(list).kcalMissing)}'
                        '${_n(totalsOf(list).kcal)} kcal',
                  ),
                  null => mealLabel(meal),
                },
                children: [
                  for (final e in byMeal[meal] ?? const <FoodEntry>[])
                    GroupedRow(
                      title: e.name,
                      subtitle: _subtitle(e),
                      onTap: () =>
                          openFoodForm(context, state, day: key, entry: e),
                      chevron: false,
                      trailing: IconButton(
                        tooltip: tr('Smazat záznam', 'Delete entry'),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(e),
                      ),
                    ),
                  GroupedRow(
                    icon: Icons.add_rounded,
                    title: mealAddLabel(meal),
                    chevron: false,
                    onTap: () => addFoodFlow(
                      context,
                      state,
                      key,
                      at: mealTime(key, meal, DateTime.now()),
                    ),
                  ),
                ],
              ),
          GroupedSection(
            header: tr('Nápady', 'Ideas'),
            children: [
              GroupedRow(
                icon: Icons.kitchen_outlined,
                title: tr('Lednička', 'Fridge'),
                subtitle: tr(
                  'Vyfoť ji a nech si navrhnout jídlo',
                  'Snap a photo and get meal ideas',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FridgePage(state)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(
              tr(
                'Orientační hodnoty, žádné zdravotní doporučení. Údaje z '
                    'čárových kódů pocházejí z databáze Open Food Facts (ODbL) '
                    'a mohou být nepřesné.',
                'Approximate values, not health advice. Barcode data comes '
                    'from the Open Food Facts database (ODbL) and may be inaccurate.',
              ),
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
    return tr(
      '${amountLabel(e)} · $kcal · B ${_g(v.protein)} · '
          'S ${_g(v.carbs)} · T ${_g(v.fat)}',
      '${amountLabel(e)} · $kcal · P ${_g(v.protein)} · '
          'C ${_g(v.carbs)} · F ${_g(v.fat)}',
    );
  }
}

/// Vstup nahoře: čárový kód.
class _EntryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Panel(
        onTap: onTap,
        // Same row shape as the meal rows below: icon, text, chevron.
        child: Row(
          children: [
            IconTile(icon, color: p.secondaryLabel),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  Text(
                    subtitle,
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.tertiaryLabel),
          ],
        ),
      ),
    );
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
        showToast(
          context,
          tr(
            'Cíl se nepodařilo uložit. Zkus to znovu.',
            'Could not save target. Try again.',
          ),
        );
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
    final hasTargets = proteinTarget != null || kcalTarget != null;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTargets) ...[
            _RingStack(
              kcal: kcalTarget == null ? null : (totals.kcal, kcalTarget),
              protein: proteinTarget == null
                  ? null
                  : (totals.protein, proteinTarget),
            ),
            const SizedBox(height: Space.l),
          ],
          Row(
            children: [
              for (final (value, label) in [
                if (kcalTarget == null)
                  ('${lower(totals.kcalMissing)}${_n(totals.kcal)}', 'kcal'),
                if (proteinTarget == null)
                  (
                    '${lower(totals.proteinMissing)}${_g(totals.protein)}',
                    tr('bílkoviny', 'protein'),
                  ),
                (
                  '${lower(totals.carbsMissing)}${_g(totals.carbs)}',
                  tr('sacharidy', 'carbs'),
                ),
                (
                  '${lower(totals.fatMissing)}${_g(totals.fat)}',
                  tr('tuky', 'fat'),
                ),
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
                    tr(
                      'Doporučeno z tvé váhy '
                          '${formatKg(state.bodyweights.first.kg)} kg.',
                      'Suggested from your body weight '
                          '${formatKg(state.bodyweights.first.kg)} kg.',
                    ),
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ),
                TextButton(
                  onPressed: () => _useSuggested(context, suggested),
                  child: Text(tr('Nastavit jako cíl', 'Set as target')),
                ),
              ],
            ),
          ] else if (!hasTargets) ...[
            const SizedBox(height: Space.s),
            _NoteWithAction(
              children: [
                Flexible(
                  child: Text(
                    tr(
                      'Zapiš tělesnou váhu a doporučím ti cíl bílkovin.',
                      'Log your body weight and I will suggest a protein target.',
                    ),
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BodyweightPage(state)),
                  ),
                  child: Text(tr('Zapsat váhu', 'Log weight')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Target rings with a compact legend for energy and protein remaining.
class _RingStack extends StatelessWidget {
  final (double, double)? kcal;
  final (double, double)? protein;
  const _RingStack({this.kcal, this.protein});

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (kcal case (final v, final t))
        (tr('Energie', 'Energy'), v, t, 'kcal', AppPalette.food),
      if (protein case (final v, final t))
        (
          tr('Bílkoviny', 'Protein'),
          v,
          t,
          'g',
          const [AppPalette.cyan, AppPalette.cyan],
        ),
    ];
    const outer = 132.0, stroke = 14.0;
    // Při velkém písmu nebo úzkém displeji legenda pod kruhy.
    final narrow =
        MediaQuery.textScalerOf(context).scale(10) > 13 ||
        MediaQuery.sizeOf(context).width < 360;
    final legend = Column(
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
    );
    return Flex(
      direction: narrow ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: narrow
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
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
        const SizedBox(width: Space.l, height: Space.m),
        if (narrow) legend else Expanded(child: legend),
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
      label: tr(
        '$label ${_n(value)} z ${_n(target)} $unit'
            '${left > 0 ? ', zbývá ${_n(left)}' : ', cíl splněn'}',
        '$label ${_n(value)} of ${_n(target)} $unit'
            '${left > 0 ? ', ${_n(left)} left' : ', goal reached'}',
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
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
            left > 0
                ? tr('zbývá ${_n(left)} $unit', '${_n(left)} $unit left')
                : tr('cíl splněn', 'goal reached'),
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
      tooltip: on
          ? tr('Odepnout z oblíbených', 'Remove from favorites')
          : tr('Připnout mezi oblíbená', 'Pin to favorites'),
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
              SnackBar(
                content: Text(
                  tr(
                    'Oblíbená se nepodařilo uložit. Zkus to znovu.',
                    'Could not save favorites. Try again.',
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }
}

/// Stejné jídlo ve stejném množství jedním klepnutím, s možností vrátit.
/// Sdílí Strava i blok jídla na Domů.
Future<void> quickAddFood(
  BuildContext context,
  AppState state,
  FoodEntry f,
  String key,
) async {
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
        content: Text(
          error ??
              tr(
                'Přidáno: ${f.name}, ${amountLabel(f)}',
                'Added: ${f.name}, ${amountLabel(f)}',
              ),
        ),
        action: error != null
            ? null
            : SnackBarAction(
                label: tr('Vrátit', 'Undo'),
                onPressed: () => state.removeFood(entry.id),
              ),
      ),
    );
}
