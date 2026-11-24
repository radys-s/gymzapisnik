import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/parse.dart';
import '../../domain/rpe.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Nejvíc kg, kam se dá dojít tlačítkem +.
const maxStepKg = 999.0;

/// List pro úpravu série: velká čísla, − / + a klávesnice.
/// Každá platná změna jde hned do [onChanged] (vrací, zda se uložila),
/// „Hotovo“ jen zavře. S [onRpe] nabídne i volitelnou náročnost (RPE).
/// S [onConfirm] (nepotvrzená série) je hlavní tlačítko „Potvrdit sérii“:
/// vrací chybu, se kterou list zůstane otevřený, jinak se zavře.
/// [error] ukáže důvod hned po otevření (např. chybějící opakování).
Future<void> showSetSheet(
  BuildContext context, {
  required String title,
  required String weight,
  required String reps,
  required double step,
  required bool bodyweight,
  bool focusReps = false,
  required Future<bool> Function(String weight, String reps) onChanged,
  double? rpe,
  Future<void> Function(double? rpe)? onRpe,
  Future<String?> Function()? onConfirm,
  String? error,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => SetSheet(
    title: title,
    weight: weight,
    reps: reps,
    step: step,
    bodyweight: bodyweight,
    focusReps: focusReps,
    onChanged: onChanged,
    rpe: rpe,
    onRpe: onRpe,
    onConfirm: onConfirm,
    error: error,
  ),
);

class SetSheet extends StatefulWidget {
  final String title;
  final String weight;
  final String reps;
  final double step;
  final bool bodyweight;
  final bool focusReps;
  final Future<bool> Function(String weight, String reps) onChanged;
  final double? rpe;
  final Future<void> Function(double? rpe)? onRpe;
  final Future<String?> Function()? onConfirm;
  final String? error;

  const SetSheet({
    super.key,
    required this.title,
    required this.weight,
    required this.reps,
    required this.step,
    required this.bodyweight,
    required this.focusReps,
    required this.onChanged,
    this.rpe,
    this.onRpe,
    this.onConfirm,
    this.error,
  });

  @override
  State<SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<SetSheet> {
  late final weight = TextEditingController(text: widget.weight);
  late final reps = TextEditingController(text: widget.reps);
  final weightFocus = FocusNode();
  final repsFocus = FocusNode();
  late String? error = widget.error;
  late double? rpe = widget.rpe;
  bool _confirming = false;

  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    weightFocus.dispose();
    repsFocus.dispose();
    super.dispose();
  }

  /// Proč text nejde uložit; `null` = čísla jsou v pořádku.
  String? _invalid() {
    final w = weight.text.trim();
    final r = reps.text.trim();
    final weightValue = w.isEmpty ? 0.0 : parseNum(w);
    final repsValue = r.isEmpty ? 0 : int.tryParse(r);
    return weightValue == null || weightValue < 0
        ? tr(
            'Váha musí být číslo od 0. Oprav ji, jinak se neuloží.',
            'Weight must be a number of 0 or more. Fix it or it won\'t be saved.',
          )
        : repsValue == null || repsValue < 0 || repsValue > 999
        ? tr(
            'Opakování musí být číslo do 999.',
            'Reps must be a number up to 999.',
          )
        : null;
  }

  /// Neplatné číslo se neuloží (jinak by se zapsala 0), jen se ukáže chyba.
  Future<void> _changed() async {
    final problem = _invalid();
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    final saved = await widget.onChanged(weight.text, reps.text);
    if (!mounted) return;
    setState(
      () => error = saved
          ? null
          : tr(
              'Změnu se nepodařilo uložit. Zkus to znovu; aplikaci zatím nezavírej.',
              'Could not save the change. Try again; don\'t close the app yet.',
            ),
    );
  }

  /// Druhé klepnutí na stejnou hodnotu ji zruší.
  Future<void> _pickRpe(double value) async {
    final next = rpe == value ? null : value;
    setState(() => rpe = next);
    try {
      await widget.onRpe?.call(next);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = tr(
            'Náročnost se nepodařilo uložit. Zkus to znovu.',
            'Could not save effort. Try again.',
          ),
        );
      }
    }
  }

  /// Potvrdí sérii; s chybou (chybí opakování…) list zůstane otevřený.
  Future<void> _confirm() async {
    final confirm = widget.onConfirm;
    if (confirm == null || _confirming) return;
    // Neplatný text v poli: série by se potvrdila se starými hodnotami.
    if (_invalid() case final problem?) {
      setState(() => error = problem);
      return;
    }
    setState(() => _confirming = true);
    String? problem;
    try {
      problem = await confirm();
    } catch (_) {
      problem = tr(
        'Sérii se nepodařilo uložit. Zkus to znovu.',
        'Could not save the set. Try again.',
      );
    }
    if (!mounted) return;
    if (problem == null) {
      Navigator.maybePop(context);
    } else {
      setState(() {
        error = problem;
        _confirming = false;
      });
    }
  }

  void _select(TextEditingController c) =>
      c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);

  /// Tlačítko − / +: nečitelný text nepřepíše, ručně vyšší hodnotu nesrazí.
  void _stepKg(double by) {
    final cur = weight.text.trim().isEmpty ? 0.0 : parseNum(weight.text);
    if (cur == null || cur < 0) {
      setState(
        () => error = tr(
          'Oprav váhu, tlačítko jí nerozumí.',
          'Fix the weight, the button can\'t read it.',
        ),
      );
      return;
    }
    final next = (cur + by).clamp(0.0, math.max(cur, maxStepKg));
    final v = double.parse(next.toStringAsFixed(2));
    weight.text = v == 0 ? '' : formatKg(v);
    _changed();
  }

  void _stepReps(int by) {
    final cur = reps.text.trim().isEmpty ? 0 : int.tryParse(reps.text.trim());
    if (cur == null || cur < 0 || cur > 999) {
      setState(
        () => error = tr(
          'Oprav opakování, tlačítko jim nerozumí.',
          'Fix the reps, the button can\'t read them.',
        ),
      );
      return;
    }
    final next = (cur + by).clamp(0, 999);
    reps.text = next == 0 ? '' : '$next';
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final kg = formatKg(widget.step);
    // Posuvné: s klávesnicí na malém telefonu se list nevejde.
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Space.page,
        0,
        Space.page,
        Space.l + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: text.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Space.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Value(
                  label: widget.bodyweight
                      ? tr('Přidaná váha (kg)', 'Added weight (kg)')
                      : tr('Váha (kg)', 'Weight (kg)'),
                  controller: weight,
                  focus: weightFocus,
                  autofocus: !widget.focusReps,
                  decimal: true,
                  minus: tr('Ubrat $kg kg', 'Remove $kg kg'),
                  plus: tr('Přidat $kg kg', 'Add $kg kg'),
                  onMinus: () => _stepKg(-widget.step),
                  onPlus: () => _stepKg(widget.step),
                  onTap: () => _select(weight),
                  onChanged: _changed,
                  onSubmitted: repsFocus.requestFocus,
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: _Value(
                  label: tr('Opakování', 'Reps'),
                  controller: reps,
                  focus: repsFocus,
                  autofocus: widget.focusReps,
                  minus: tr('Ubrat opakování', 'Remove rep'),
                  plus: tr('Přidat opakování', 'Add rep'),
                  onMinus: () => _stepReps(-1),
                  onPlus: () => _stepReps(1),
                  onTap: () => _select(reps),
                  onChanged: _changed,
                  // „Hotovo“ na klávesnici potvrdí, když je co potvrdit:
                  // tlačítko pod klávesnicí na telefonu není vidět.
                  onSubmitted: widget.onConfirm == null
                      ? () => Navigator.maybePop(context)
                      : _confirm,
                ),
              ),
            ],
          ),
          if (error case final e?)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Text(
                  e,
                  semanticsLabel: e,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: p.negative),
                ),
              ),
            ),
          if (widget.onRpe != null) ...[
            const SizedBox(height: Space.l),
            _RpePicker(value: rpe, onPick: _pickRpe),
          ],
          const SizedBox(height: Space.l),
          if (widget.onConfirm == null)
            PrimaryButton(
              tr('Hotovo', 'Done'),
              onPressed: () => Navigator.maybePop(context),
            )
          else ...[
            // Úprava a potvrzení jedním klepnutím, bez hledání ✓ v řádku.
            PrimaryButton(
              tr('Potvrdit sérii', 'Confirm set'),
              icon: Icons.check_rounded,
              busy: _confirming,
              onPressed: _confirm,
            ),
            const SizedBox(height: Space.xs),
            TextButton(
              onPressed: _confirming ? null : () => Navigator.maybePop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(minTap),
              ),
              child: Text(tr('Jen uložit', 'Just save')),
            ),
          ],
        ],
      ),
    );
  }
}

class _Value extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focus;
  final bool autofocus;
  final bool decimal;
  final String minus;
  final String plus;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onTap;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  const _Value({
    required this.label,
    required this.controller,
    required this.focus,
    required this.autofocus,
    this.decimal = false,
    required this.minus,
    required this.plus,
    required this.onMinus,
    required this.onPlus,
    required this.onTap,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_Value> createState() => _ValueState();
}

class _ValueState extends State<_Value> {
  @override
  void initState() {
    super.initState();
    // Předvyplněné číslo rovnou označené: psaní ho přepíše.
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = widget.controller;
        c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    Widget button(IconData icon, String tooltip, VoidCallback onTap) =>
        Expanded(
          child: SizedBox(
            height: 48,
            // Vlastní uzel s akcí: bez ní by čtečka tlačítko nezmáčkla.
            child: Semantics(
              container: true,
              button: true,
              label: tooltip,
              onTap: onTap,
              excludeSemantics: true,
              child: IconButton(
                onPressed: onTap,
                style: IconButton.styleFrom(
                  backgroundColor: p.fill,
                  foregroundColor: p.label,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      context.palette.controlRadius,
                    ),
                  ),
                ),
                icon: Icon(icon),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: text.labelSmall,
        ),
        const SizedBox(height: Space.xs),
        Semantics(
          container: true,
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focus,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.decimal,
            ),
            textInputAction: widget.decimal
                ? TextInputAction.next
                : TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
            ],
            style: TextStyle(
              fontFamily: condensedFont,
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: p.label,
              fontFeatures: tabular,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: Space.s),
            ),
            onTap: widget.onTap,
            onChanged: (_) => widget.onChanged(),
            onSubmitted: (_) => widget.onSubmitted(),
          ),
        ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            button(Icons.remove_rounded, widget.minus, widget.onMinus),
            const SizedBox(width: Space.s),
            button(Icons.add_rounded, widget.plus, widget.onPlus),
          ],
        ),
      ],
    );
  }
}

/// Volitelná náročnost série: RPE 6–10 a co znamená.
class _RpePicker extends StatelessWidget {
  final double? value;
  final ValueChanged<double> onPick;

  const _RpePicker({required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Náročnost (RPE), nepovinné', 'Effort (RPE), optional'),
          textAlign: TextAlign.center,
          style: text.labelMedium?.copyWith(color: p.secondaryLabel),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final v in rpeChoices)
              ChoiceChip(
                label: Text(formatRpe(v)),
                selected: current == v,
                showCheckmark: false,
                tooltip: 'RPE ${formatRpe(v)}: ${rpeHint(v)}',
                onSelected: (_) => onPick(v),
              ),
          ],
        ),
        const SizedBox(height: Space.xs),
        Text(
          current == null
              ? tr(
                  'Kolik opakování ti zbylo? Kouč podle toho volí váhu.',
                  'How many reps left in the tank? The coach uses this for weight picks.',
                )
              : rpeHint(current),
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: p.secondaryLabel),
        ),
      ],
    );
  }
}
