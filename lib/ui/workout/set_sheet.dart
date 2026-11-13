import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/parse.dart';
import '../../domain/rpe.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Nejvíc kg, kam se dá dojít tlačítkem +.
const maxStepKg = 999.0;

/// List pro úpravu série: velká čísla, − / + a klávesnice.
/// Každá platná změna jde hned do [onChanged] (vrací, zda se uložila),
/// „Hotovo“ jen zavře. S [onRpe] nabídne i volitelnou náročnost (RPE).
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
  });

  @override
  State<SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<SetSheet> {
  late final weight = TextEditingController(text: widget.weight);
  late final reps = TextEditingController(text: widget.reps);
  final weightFocus = FocusNode();
  final repsFocus = FocusNode();
  String? error;
  late double? rpe = widget.rpe;

  @override
  void dispose() {
    weight.dispose();
    reps.dispose();
    weightFocus.dispose();
    repsFocus.dispose();
    super.dispose();
  }

  /// Neplatné číslo se neuloží (jinak by se zapsala 0), jen se ukáže chyba.
  Future<void> _changed() async {
    final w = weight.text.trim();
    final r = reps.text.trim();
    final repsValue = r.isEmpty ? 0 : int.tryParse(r);
    final problem = w.isNotEmpty && parseNum(w) == null
        ? 'Váha není číslo. Oprav ji, jinak se neuloží.'
        : repsValue == null || repsValue > 999
        ? 'Opakování musí být číslo do 999.'
        : null;
    if (problem != null) {
      setState(() => error = problem);
      return;
    }
    final saved = await widget.onChanged(weight.text, reps.text);
    if (!mounted) return;
    setState(
      () => error = saved ? null : 'Změnu se nepodařilo uložit. Zkus to znovu; aplikaci zatím nezavírej.',
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
          () => error = 'Náročnost se nepodařilo uložit. Zkus to znovu.',
        );
      }
    }
  }

  void _select(TextEditingController c) =>
      c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);

  /// Tlačítko − / +: nečitelný text nepřepíše, ručně vyšší hodnotu nesrazí.
  void _stepKg(double by) {
    final cur = weight.text.trim().isEmpty ? 0.0 : parseNum(weight.text);
    if (cur == null) {
      setState(() => error = 'Oprav váhu, tlačítko jí nerozumí.');
      return;
    }
    final next = (cur + by).clamp(0.0, math.max(cur, maxStepKg));
    final v = double.parse(next.toStringAsFixed(2));
    weight.text = v == 0 ? '' : formatKg(v);
    _changed();
  }

  void _stepReps(int by) {
    final cur = reps.text.trim().isEmpty ? 0 : int.tryParse(reps.text.trim());
    if (cur == null || cur > 999) {
      setState(() => error = 'Oprav opakování, tlačítko jim nerozumí.');
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
                  label: widget.bodyweight ? 'Přidaná váha (kg)' : 'Váha (kg)',
                  controller: weight,
                  focus: weightFocus,
                  autofocus: !widget.focusReps,
                  decimal: true,
                  minus: 'Ubrat $kg kg',
                  plus: 'Přidat $kg kg',
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
                  label: 'Opakování',
                  controller: reps,
                  focus: repsFocus,
                  autofocus: widget.focusReps,
                  minus: 'Ubrat opakování',
                  plus: 'Přidat opakování',
                  onMinus: () => _stepReps(-1),
                  onPlus: () => _stepReps(1),
                  onTap: () => _select(reps),
                  onChanged: _changed,
                  onSubmitted: () => Navigator.maybePop(context),
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
          PrimaryButton('Hotovo', onPressed: () => Navigator.maybePop(context)),
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
          widget.label,
          textAlign: TextAlign.center,
          style: text.labelMedium?.copyWith(color: p.secondaryLabel),
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
              FilteringTextInputFormatter.allow(
                widget.decimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
              ),
            ],
            style: text.headlineMedium?.copyWith(fontFeatures: tabular),
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: Space.m),
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
          'Náročnost (RPE), nepovinné',
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
              ? 'Kolik opakování ti zbylo? Kouč podle toho volí váhu.'
              : rpeHint(current),
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: p.secondaryLabel),
        ),
      ],
    );
  }
}
