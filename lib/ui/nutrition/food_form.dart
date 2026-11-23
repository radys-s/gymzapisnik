import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/ids.dart';
import '../../core/parse.dart';
import '../../data/off_client.dart';
import '../../domain/nutrition.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Otevře formulář jídla. Vrací `true`, když se záznam uložil.
///
/// - [entry]: úprava existujícího záznamu,
/// - [product]: produkt z Open Food Facts k potvrzení a úpravě,
/// - [copyOf]: nový záznam podle dřívějšího,
/// - nic z toho: ruční zápis ([barcode] se dá předvyplnit po nenalezení).
///
/// [at] je čas nového záznamu (jídlo dne vybrané tlačítkem „+“).
Future<bool> openFoodForm(
  BuildContext context,
  AppState state, {
  required String day,
  FoodEntry? entry,
  OffProduct? product,
  FoodEntry? copyOf,
  String? barcode,
  DateTime? at,
}) async {
  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => FoodFormPage(
        state,
        day: day,
        entry: entry,
        product: product,
        copyOf: copyOf,
        barcode: barcode,
        at: at,
      ),
    ),
  );
  return saved == true;
}

String _fmt(double? v) =>
    v == null ? '' : formatKg(double.parse(v.toStringAsFixed(1)));

class FoodFormPage extends StatefulWidget {
  final AppState state;
  final String day;
  final FoodEntry? entry;
  final OffProduct? product;
  final FoodEntry? copyOf;
  final String? barcode;
  final DateTime? at;
  const FoodFormPage(
    this.state, {
    super.key,
    required this.day,
    this.entry,
    this.product,
    this.copyOf,
    this.barcode,
    this.at,
  });

  @override
  State<FoodFormPage> createState() => _FoodFormPageState();
}

class _FoodFormPageState extends State<FoodFormPage> {
  final name = TextEditingController();
  final amount = TextEditingController();
  final kcal = TextEditingController();
  final protein = TextEditingController();
  final carbs = TextEditingController();
  final fat = TextEditingController();

  late FoodBasis basis;
  late FoodUnit unit;
  late String day;
  String? brand;
  String? barcode;
  String? error;
  bool saving = false;

  OffProduct? get product => widget.product;

  @override
  void initState() {
    super.initState();
    day = widget.day;
    final e = widget.entry ?? widget.copyOf;
    if (e != null) {
      name.text = e.name;
      brand = e.brand;
      barcode = e.barcode;
      basis = e.basis;
      unit = e.unit;
      amount.text = _fmt(e.amount);
      _setValues(e.values);
      if (widget.entry != null) day = e.day;
    } else if (product != null) {
      final p = product!;
      name.text = p.name;
      brand = p.brand;
      barcode = p.barcode;
      unit = FoodUnit.g;
      if (p.per100 != null || p.perServing == null) {
        basis = FoodBasis.per100;
        amount.text = _fmt(p.servingAmount ?? 100);
        _setValues(p.per100 ?? const Nutrition());
      } else {
        basis = FoodBasis.perServing;
        amount.text = '1';
        _setValues(p.perServing!);
      }
    } else {
      basis = FoodBasis.per100;
      unit = FoodUnit.g;
      amount.text = '100';
      barcode = widget.barcode;
    }
    for (final c in [name, amount, kcal, protein, carbs, fat]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [name, amount, kcal, protein, carbs, fat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setValues(Nutrition v) {
    kcal.text = _fmt(v.kcal);
    protein.text = _fmt(v.protein);
    carbs.text = _fmt(v.carbs);
    fat.text = _fmt(v.fat);
  }

  /// Prázdné pole = `null` (chybí), jinak číslo včetně nuly.
  /// `bad` se nastaví, když je v poli nesmysl.
  (double?, bool) _field(TextEditingController c) {
    if (c.text.trim().isEmpty) return (null, false);
    final v = parseNum(c.text);
    return v == null || v < 0 ? (null, true) : (v, false);
  }

  (Nutrition, bool) _values() {
    final (k, kb) = _field(kcal);
    final (p, pb) = _field(protein);
    final (c, cb) = _field(carbs);
    final (f, fb) = _field(fat);
    return (
      Nutrition(kcal: k, protein: p, carbs: c, fat: f),
      kb || pb || cb || fb,
    );
  }

  void _setBasis(FoodBasis next) {
    if (next == basis) return;
    setState(() {
      basis = next;
      final p = product;
      if (p != null) {
        final v = next == FoodBasis.per100 ? p.per100 : p.perServing;
        _setValues(v ?? const Nutrition());
        amount.text = next == FoodBasis.per100
            ? _fmt(p.servingAmount ?? 100)
            : '1';
      } else {
        amount.text = next == FoodBasis.per100 ? '100' : '1';
      }
    });
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final current = parseDayKey(day) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => day = dayKey(picked));
  }

  Future<void> _save() async {
    final (values, bad) = _values();
    final amountValue = parseNum(amount.text);
    if (bad) {
      setState(
        () => error = tr(
          'Hodnoty musí být čísla od nuly výš.',
          'Values must be numbers from zero up.',
        ),
      );
      return;
    }
    final existing = widget.entry;
    final next = FoodEntry(
      id: existing?.id ?? newId(),
      day: day,
      loggedAt:
          existing?.loggedAt ??
          // Den se ve formuláři dá změnit: čas jídla platí jen pro původní.
          (widget.at != null && dayKey(widget.at!) == day
              ? widget.at!
              : loggedAtFor(
                  day,
                  DateTime.now(),
                  timeOf: widget.at ?? widget.copyOf?.loggedAt.toLocal(),
                )),
      name: name.text.trim(),
      brand: brand,
      barcode: barcode,
      basis: basis,
      unit: unit,
      amount: amountValue ?? 0,
      values: values,
    );
    setState(() {
      saving = true;
      error = null;
    });
    final problem = await widget.state.saveFood(next);
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        saving = false;
        error = problem;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  Widget _numberField(TextEditingController c, String label) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
  );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final pal = context.palette;
    final p = product;
    final (values, bad) = _values();
    final amountValue = parseNum(amount.text);
    final preview = bad || amountValue == null || amountValue <= 0
        ? null
        : FoodEntry(
            id: 'x',
            day: day,
            loggedAt: DateTime.now(),
            name: '',
            basis: basis,
            unit: unit,
            amount: amountValue,
            values: values,
          ).eaten;
    final per100 = basis == FoodBasis.per100;
    final unitText = unit == FoodUnit.ml ? 'ml' : 'g';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry == null
              ? tr('Přidat jídlo', 'Add food')
              : tr('Upravit jídlo', 'Edit food'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          if (p != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tr(
                  'Údaje z Open Food Facts${p.brand == null ? '' : ' (${p.brand})'}'
                      '. Zkontroluj je s obalem, mohou být nepřesné.',
                  'Data from Open Food Facts${p.brand == null ? '' : ' (${p.brand})'}'
                      '. Check them against the label, they may be inaccurate.',
                ),
                style: text.bodySmall?.copyWith(color: pal.accent),
              ),
            ),
          if (p == null && widget.barcode != null && widget.entry == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tr(
                  'Kód ${widget.barcode} nemáme v databázi. Vyplň údaje z obalu.',
                  'We do not have code ${widget.barcode} in the database. Fill in the details from the label.',
                ),
                style: text.bodySmall,
              ),
            ),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: tr('Název jídla', 'Food name'),
            ),
          ),
          const SizedBox(height: Space.m),
          GroupedSection(
            children: [
              GroupedRow(
                icon: Icons.event_outlined,
                title: tr('Den', 'Day'),
                value: formatDate(parseDayKey(day) ?? DateTime.now()),
                onTap: _pickDay,
              ),
            ],
          ),
          SectionHeader(tr('Množství', 'Amount')),
          SegmentedButton<FoodBasis>(
            segments: [
              ButtonSegment(
                value: FoodBasis.per100,
                label: Text(
                  tr(
                    'Na 100 ${per100 ? unitText : 'g'}',
                    'Per 100 ${per100 ? unitText : 'g'}',
                  ),
                ),
              ),
              ButtonSegment(
                value: FoodBasis.perServing,
                label: Text(tr('Na porci', 'Per serving')),
              ),
            ],
            selected: {basis},
            onSelectionChanged: (s) => _setBasis(s.first),
          ),
          const SizedBox(height: 4),
          Text(
            per100
                ? tr(
                    'Hodnoty níž jsou na 100 $unitText, množství v $unitText.',
                    'Values below are per 100 $unitText, amount in $unitText.',
                  )
                : tr(
                    'Hodnoty níž jsou na jednu porci, množství je počet porcí.',
                    'Values below are per serving, amount is the number of servings.',
                  ),
            style: text.bodySmall?.copyWith(color: pal.secondaryLabel),
          ),
          if (per100) ...[
            const SizedBox(height: Space.s),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<FoodUnit>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: FoodUnit.g, label: Text('g')),
                  ButtonSegment(value: FoodUnit.ml, label: Text('ml')),
                ],
                selected: {unit},
                onSelectionChanged: (s) => setState(() => unit = s.first),
              ),
            ),
          ],
          const SizedBox(height: Space.m),
          _numberField(
            amount,
            per100
                ? tr('Množství ($unitText)', 'Amount ($unitText)')
                : tr('Počet porcí', 'Number of servings'),
          ),
          if (per100 && p?.servingAmount != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                label: Text(
                  tr(
                    '1 porce = ${p!.servingLabel ?? '${_fmt(p.servingAmount)} g'}',
                    '1 serving = ${p.servingLabel ?? '${_fmt(p.servingAmount)} g'}',
                  ),
                ),
                onPressed: () => amount.text = _fmt(p.servingAmount),
              ),
            ),
          SectionHeader(
            tr(
              'Hodnoty ${per100 ? 'na 100 $unitText' : 'na porci'}',
              'Values ${per100 ? 'per 100 $unitText' : 'per serving'}',
            ),
          ),
          _numberField(
            kcal,
            tr(
              'Energie (kcal)${per100 ? ' na 100 $unitText' : ' na porci'}',
              'Energy (kcal)${per100 ? ' per 100 $unitText' : ' per serving'}',
            ),
          ),
          const SizedBox(height: Space.m),
          _numberField(protein, tr('Bílkoviny (g)', 'Protein (g)')),
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: _numberField(carbs, tr('Sacharidy (g)', 'Carbs (g)')),
              ),
              const SizedBox(width: Space.m),
              Expanded(child: _numberField(fat, tr('Tuky (g)', 'Fat (g)'))),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr(
              'Prázdné pole = hodnotu neznáme. Nula = je opravdu nulová.',
              'Empty field = unknown value. Zero = really zero.',
            ),
            style: text.bodySmall?.copyWith(color: pal.secondaryLabel),
          ),
          const SizedBox(height: Space.l),
          if (preview != null)
            Panel(
              child: Text(
                tr(
                  'Snědeno: ${preview.kcal == null ? '– kcal' : '${preview.kcal!.round()} kcal'}'
                      ' · B ${preview.protein == null ? '–' : preview.protein!.round()} g'
                      ' · S ${preview.carbs == null ? '–' : preview.carbs!.round()} g'
                      ' · T ${preview.fat == null ? '–' : preview.fat!.round()} g',
                  'Eaten: ${preview.kcal == null ? '– kcal' : '${preview.kcal!.round()} kcal'}'
                      ' · P ${preview.protein == null ? '–' : preview.protein!.round()} g'
                      ' · C ${preview.carbs == null ? '–' : preview.carbs!.round()} g'
                      ' · F ${preview.fat == null ? '–' : preview.fat!.round()} g',
                ),
                style: text.bodyLarge,
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(error!, style: TextStyle(color: pal.negative)),
            ),
          const SizedBox(height: Space.l),
          PrimaryButton(
            widget.entry == null
                ? tr('Uložit', 'Save')
                : tr('Uložit změny', 'Save changes'),
            busy: saving,
            onPressed: saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
