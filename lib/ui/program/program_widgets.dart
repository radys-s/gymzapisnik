import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Zkratky dnů v týdnu (index 0 = pondělí).
const weekdayShort = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];
const weekdayLong = [
  'pondělí',
  'úterý',
  'středa',
  'čtvrtek',
  'pátek',
  'sobota',
  'neděle',
];

/// „3× 8–12" (série × rozsah opakování).
String planLabel(PlannedExercise p) => p.repMin == p.repMax
    ? '${p.sets}× ${p.repMin}'
    : '${p.sets}× ${p.repMin}–${p.repMax}';

/// „1× týdně", „3× týdně".
String perWeekLabel(int n) => '$n× týdně';

/// Číslo s tlačítky − a + (44 pt), pro série, opakování i frekvenci.
class StepperControl extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  /// Jak hodnotu přečíst čtečkou („3 série").
  final String Function(int value)? spoken;

  const StepperControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.spoken,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    Widget button(IconData icon, String tip, int next, bool can) => SizedBox(
      width: minTap,
      height: minTap,
      child: IconButton(
        tooltip: '$tip: $label',
        onPressed: enabled && can ? () => onChanged!(next) : null,
        style: IconButton.styleFrom(
          backgroundColor: p.fill,
          foregroundColor: p.label,
          disabledForegroundColor: p.tertiaryLabel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: text.bodyLarge)),
        button(Icons.remove_rounded, 'Méně', value - 1, value > min),
        SizedBox(
          width: 48,
          child: Semantics(
            container: true,
            liveRegion: true,
            label: '$label: ${spoken?.call(value) ?? value}',
            excludeSemantics: true,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(
                fontFeatures: tabular,
                color: enabled ? p.label : p.tertiaryLabel,
              ),
            ),
          ),
        ),
        button(Icons.add_rounded, 'Víc', value + 1, value < max),
      ],
    );
  }
}

/// Frekvence: kolikrát týdně a ve které dny. Ukládá rovnou do profilu.
class FrequencyPanel extends StatelessWidget {
  final AppState state;
  const FrequencyPanel(this.state, {super.key});

  Future<void> _save(BuildContext context, Future<void> Function() save) async {
    try {
      await save();
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Frekvenci se nepodařilo uložit. Zkus to znovu.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final days = state.profile.trainingDays ?? const <int>[];
    final goal = state.weekGoal;
    final fromProgram = state.profile.weekGoal == null && state.split != null;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepperControl(
            label: 'Tréninků týdně',
            value: goal,
            min: 1,
            max: 7,
            spoken: perWeekLabel,
            // Se zvolenými dny je počet dán jimi.
            onChanged: days.isNotEmpty
                ? null
                : (n) => _save(context, () => state.setFrequency(perWeek: n)),
          ),
          const SizedBox(height: Space.l),
          Text('Dny tréninku', style: text.labelMedium),
          const SizedBox(height: Space.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 1; d <= 7; d++)
                _DayToggle(
                  label: weekdayShort[d - 1],
                  spoken: weekdayLong[d - 1],
                  selected: days.contains(d),
                  onTap: () => _save(context, () => state.toggleTrainingDay(d)),
                ),
            ],
          ),
          const SizedBox(height: Space.m),
          Text(
            days.isNotEmpty
                ? 'Připomínky a plán jen v tyto dny. Trénink navíc se počítá taky.'
                : fromProgram
                ? 'Podle programu. Vyber dny, nebo nech plán rozložit do týdne.'
                : 'Vyber dny, nebo nech plán rozložit do týdne.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  final String label;
  final String spoken;
  final bool selected;
  final VoidCallback onTap;
  const _DayToggle({
    required this.label,
    required this.spoken,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      button: true,
      toggled: selected,
      label: spoken,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: minTap,
          height: minTap,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? p.linear : null,
            color: selected ? null : p.fill,
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: selected ? p.onGradient : p.secondaryLabel),
          ),
        ),
      ),
    );
  }
}

/// Seznam dnů programu s cviky (náhled).
class ProgramDayPanel extends StatelessWidget {
  final AppState state;
  final int index;
  final SplitDay day;
  const ProgramDayPanel({
    super.key,
    required this.state,
    required this.index,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Den ${index + 1}',
              style: text.labelMedium?.copyWith(
                color: p.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            Semantics(
              container: true,
              header: true,
              child: Text(day.name, style: text.titleMedium),
            ),
            const SizedBox(height: Space.s),
            for (final e in day.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.exercise(e.exerciseId).name,
                        style: text.bodyMedium,
                      ),
                    ),
                    Text(
                      planLabel(e),
                      style: text.bodyMedium?.copyWith(
                        color: p.secondaryLabel,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
