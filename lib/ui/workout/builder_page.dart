import 'package:flutter/material.dart';
import '../../core/i18n.dart';

import '../../coach/plan_quiz.dart';
import '../../coach/splits.dart';
import '../../domain/anatomy.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../program/program_widgets.dart';
import '../widgets/muscle_tile_grid.dart';
import 'alternatives_page.dart';

/// Sestavení tréninku: partie + počet cviků, náhled s možností vyměnit
/// cvik za alternativu. Vrací hotový den přes `Navigator.pop`.
class WorkoutBuilderPage extends StatefulWidget {
  final AppState state;

  /// Předvybrané partie (např. odpočaté svaly z domovské stránky).
  final Iterable<String> initialFocuses;

  /// Partie, které ještě regenerují: jejich cviky se nenabídnou, dokud
  /// je uživatel sám nevybere.
  final Iterable<String> avoidFocuses;
  const WorkoutBuilderPage(
    this.state, {
    super.key,
    this.initialFocuses = const [],
    this.avoidFocuses = const [],
  });

  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  late final focuses = <String>{...widget.initialFocuses};
  late final PlanAnswers answers =
      widget.state.planAnswers ?? const PlanAnswers();

  /// Doporučený počet cviků podle času a zkušenosti z dotazníku.
  late final int recommended = recommendedCount(answers.minutes, answers.level);
  late int count = recommended;

  /// Ruční výměny cviků (index v náhledu → ID cviku). Po změně partií
  /// nebo počtu se zahodí, protože se náhled sestaví znovu.
  final swaps = <int, String>{};

  SplitDay get day {
    final built = buildDay(focuses, count, avoidFocuses: widget.avoidFocuses);
    return built.copyWith(
      exercises: [
        for (var i = 0; i < built.exercises.length; i++)
          swaps.containsKey(i)
              ? built.exercises[i].copyWith(exerciseId: swaps[i])
              : built.exercises[i],
      ],
    );
  }

  void _change(VoidCallback fn) => setState(() {
    fn();
    swaps.clear();
  });

  Future<void> _swap(int index, String exerciseId) async {
    final id = await pickAlternative(context, widget.state, exerciseId);
    if (id == null || !mounted) return;
    final current = day.exercises;
    final duplicate = [
      for (var i = 0; i < current.length; i++)
        if (i != index && current[i].exerciseId == id) i,
    ].isNotEmpty;
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Tenhle cvik už v tréninku je.', 'That exercise is already in the workout.'))),
      );
      return;
    }
    setState(() => swaps[index] = id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = day;
    final short = current.exercises.length < count && focuses.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(tr('Sestavit trénink', 'Build workout'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          Text(
            tr(
              'Vyber partie a počet cviků. Těžké vícekloubové cviky jdou '
                  'první, další míří na různé hlavy svalu.',
              'Pick muscle groups and exercise count. Heavy compound lifts '
                  'come first, the rest target different muscle heads.',
            ),
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.l),
          MuscleTileGrid(
            selected: focuses,
            onToggle: (id) => _change(
              () => focuses.contains(id) ? focuses.remove(id) : focuses.add(id),
            ),
          ),
          const SizedBox(height: Space.l),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepperControl(
                  label: tr('Počet cviků', 'Exercise count'),
                  value: count,
                  min: 1,
                  max: maxBuiltExercises,
                  onChanged: (n) => _change(() => count = n),
                  spoken: (n) => isEnglish ? '$n exercises' : '$n cviků',
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(
                          'Doporučeno: $recommended '
                              '(na ${answers.minutes} min, '
                              '${answers.level.label.toLowerCase()})',
                          'Recommended: $recommended '
                              '(${answers.minutes} min, '
                              '${answers.level.label.toLowerCase()})',
                        ),
                        style: text.bodySmall?.copyWith(
                          color: p.secondaryLabel,
                        ),
                      ),
                    ),
                    if (count != recommended)
                      TextButton(
                        onPressed: () => _change(() => count = recommended),
                        child: Text(tr('Vrátit', 'Reset')),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (current.exercises.isNotEmpty) ...[
            SectionHeader(current.name),
            GroupedSection(
              footer: short
                  ? tr('Pro zvolené partie víc různých cviků nemám.', 'No more different exercises for the selected groups.')
                  : tr('Klepnutím cvik vyměníš za jiný na stejnou hlavu svalu.', 'Tap an exercise to swap it for another targeting the same head.'),
              children: [
                for (var i = 0; i < current.exercises.length; i++)
                  GroupedRow(
                    title: widget.state
                        .exercise(current.exercises[i].exerciseId)
                        .name,
                    subtitle: [
                      planLabel(current.exercises[i]),
                      headsLabel(current.exercises[i].exerciseId),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    trailing: Icon(
                      Icons.swap_horiz_rounded,
                      color: p.tertiaryLabel,
                      semanticLabel: tr('Vyměnit', 'Swap'),
                    ),
                    chevron: false,
                    onTap: () => _swap(i, current.exercises[i].exerciseId),
                  ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: Space.xxl),
              child: EmptyState(
                icon: Icons.accessibility_new_rounded,
                title: tr('Vyber aspoň jednu partii', 'Pick at least one muscle group'),
                message: tr('Třeba Hrudník a Triceps, nebo jen Nohy.', 'For example Chest and Triceps, or just Legs.'),
              ),
            ),
        ],
      ),
      bottomNavigationBar: current.exercises.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Space.page,
                  Space.s,
                  Space.page,
                  Space.s,
                ),
                child: PrimaryButton(
                  tr('Začít trénink', 'Start workout'),
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => popOnce(context, current),
                ),
              ),
            ),
    );
  }
}
