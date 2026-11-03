import 'package:flutter/material.dart';

import '../../coach/push.dart';
import '../../domain/catalog.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../design/motion.dart';

String _kg(double v) => v.round().toString();

String _sessions(int n) => n >= 2 && n <= 4 ? '$n tréninky' : '$n tréninků';

/// Otázka pro trenéra, když váha stojí: s čísly, ať odpoví konkrétně.
String plateauQuestion(String name, Plateau p) =>
    'Jsem zaseknutý u cviku $name: ${_sessions(p.sessions)} bez posunu, '
    'poslední váha ${_kg(p.topWeight)} kg (odhad 1RM '
    '${_kg(p.best)} kg). Co mám příští týden dělat, abych se posunul?';

/// Hodnocení tréninku čtyřmi tlačítky. Kouč podle něj přidává váhu
/// rychleji, nebo ji podrží.
class RatingPanel extends StatelessWidget {
  final AppState state;
  final Workout workout;
  const RatingPanel({super.key, required this.state, required this.workout});

  Future<void> _rate(BuildContext context, WorkoutRating? r) async {
    try {
      await state.rateWorkout(workout, r);
    } catch (_) {
      if (context.mounted) {
        showToast(context, 'Hodnocení se nepodařilo uložit.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = ratingOf(workout);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Jak to šlo?', style: text.titleMedium),
          const SizedBox(height: 2),
          Text(
            current?.hint ??
                'Kouč podle toho příště přidá váhu, nebo ji podrží.',
            style: text.bodySmall?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final r in WorkoutRating.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: current == r,
                  showCheckmark: false,
                  onSelected: (on) => _rate(context, on ? r : null),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Karta „Zaseknutý na váze?“: co zkusit a rychlá otázka na trenéra.
class PlateauPanel extends StatelessWidget {
  final AppState state;
  final Plateau plateau;
  final VoidCallback onAsk;
  const PlateauPanel({
    super.key,
    required this.state,
    required this.plateau,
    required this.onAsk,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final name = state.exercise(plateau.exerciseId).name;
    final history = exerciseHistory(state.workouts, plateau.exerciseId);
    final tips = plateauTips(
      plateau,
      protein: state.proteinWeek(),
      lastRating: history.isEmpty ? null : ratingOf(history.last.workout),
    ).take(3);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(Icons.trending_flat_rounded, color: p.gradient.last),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zaseknutý na váze?', style: text.titleMedium),
                    Text(
                      '$name: ${plateau.sessions}× bez posunu',
                      style: text.bodySmall?.copyWith(
                        color: p.secondaryLabel,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text(t, style: text.bodyMedium)),
                ],
              ),
            ),
          const SizedBox(height: Space.s),
          SecondaryButton(
            'Zeptej se trenéra',
            icon: Icons.forum_outlined,
            onPressed: onAsk,
          ),
        ],
      ),
    );
  }
}

/// Týdenní cíl na Domů: stav s přechodem barev a věta, která tlačí.
/// Bez cíle nabídne jeho nastavení.
class WeekFocusCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const WeekFocusCard({super.key, required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final focus = state.weekFocus(now);
    final progress = state.weekFocusProgress(now);
    if (focus == null || progress == null) {
      return Panel(
        onTap: () => showWeekFocusSheet(context, state, now: now),
        child: Row(
          children: [
            IconTile(Icons.flag_outlined, color: p.accent),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nastav si cíl týdne', style: text.titleMedium),
                  Text(
                    'Síla, pravidelnost, objem nebo bílkoviny. '
                    'Kouč tě bude tlačit.',
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.tertiaryLabel),
          ],
        ),
      );
    }
    final title = focus.kind == FocusKind.strength
        ? 'Síla: ${state.exercise(focus.exerciseId!).name}'
        : focus.kind.label;
    String num(double v) => focus.kind == FocusKind.strength
        ? v.toStringAsFixed(1).replaceAll('.', ',')
        : '${v.round()}';
    return Panel(
      onTap: () => showWeekFocusSheet(context, state, now: now),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cíl týdne', style: text.labelMedium),
                    Text(title, style: text.titleMedium),
                  ],
                ),
              ),
              Text(
                '${num(progress.value)} / ${num(progress.target)}',
                style: text.titleMedium?.copyWith(
                  fontFeatures: tabular,
                  color: progress.done ? p.positive : p.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          Semantics(
            label:
                '${progress.unit}: ${num(progress.value)} '
                'z ${num(progress.target)}',
            child: _GradientBar(progress.fraction),
          ),
          const SizedBox(height: Space.s),
          Text(progress.push, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _GradientBar extends StatelessWidget {
  final double value;
  const _GradientBar(this.value);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: Container(
        height: 8,
        color: p.fill,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: Motion.of(context, Motion.slow),
          curve: Motion.curve,
          builder: (_, v, _) => FractionallySizedBox(
            widthFactor: v.clamp(0, 1),
            child: DecoratedBox(decoration: BoxDecoration(gradient: p.linear)),
          ),
        ),
      ),
    );
  }
}

/// Výběr cíle týdne. Síla potřebuje cvik: nabídnou se ty nejčastější.
Future<void> showWeekFocusSheet(
  BuildContext context,
  AppState state, {
  required DateTime now,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final text = Theme.of(sheet).textTheme;
    final p = sheet.palette;
    final current = state.weekFocus(now);
    final counts = <String, int>{};
    for (final w in state.workouts.where((w) => w.finished).take(30)) {
      for (final e in w.exercises) {
        if (state.typeOf(e.exerciseId) == ExerciseType.weighted &&
            e.countedSets.isNotEmpty &&
            findExercise(e.exerciseId, state.customExercises) != null) {
          counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
        }
      }
    }
    final lifts = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    Future<void> pick(FocusKind? kind, [String? id]) async {
      try {
        await state.setWeekFocus(kind, exerciseId: id, now: now);
        if (sheet.mounted) Navigator.pop(sheet);
      } catch (_) {
        if (sheet.mounted) showToast(sheet, 'Cíl se nepodařilo uložit.');
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cíl na tento týden', style: text.titleLarge),
            const SizedBox(height: Space.xs),
            Text(
              'Jeden cíl do neděle. Kouč ho bude hlídat a tlačit tě k němu.',
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
            const SizedBox(height: Space.m),
            GroupedSection(
              header: 'Síla v cviku',
              footer: lifts.isEmpty
                  ? 'Až odcvičíš první trénink s váhou, půjde vybrat cvik.'
                  : 'Cíl je o 2,5 % vyšší odhad maxima než dosud.',
              children: [
                for (final id in lifts.take(6))
                  GroupedRow(
                    title: state.exercise(id).name,
                    trailing:
                        current?.kind == FocusKind.strength &&
                            current?.exerciseId == id
                        ? Icon(Icons.check_rounded, color: p.accent)
                        : null,
                    onTap: () => pick(FocusKind.strength, id),
                  ),
              ],
            ),
            GroupedSection(
              header: 'Jiný cíl',
              children: [
                for (final k in FocusKind.values.skip(1))
                  GroupedRow(
                    title: k.label,
                    subtitle: k.hint,
                    trailing: current?.kind == k
                        ? Icon(Icons.check_rounded, color: p.accent)
                        : null,
                    onTap: () => pick(k),
                  ),
              ],
            ),
            if (current != null)
              TextButton(
                onPressed: () => pick(null),
                child: const Text('Zrušit cíl týdne'),
              ),
          ],
        ),
      ),
    );
  },
);
