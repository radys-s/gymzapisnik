import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../domain/anatomy.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../program/program_widgets.dart';
import 'alternatives_page.dart';

/// Sestavení tréninku: partie + počet cviků, náhled s možností vyměnit
/// cvik za alternativu. Vrací hotový den přes `Navigator.pop`.
class WorkoutBuilderPage extends StatefulWidget {
  final AppState state;
  const WorkoutBuilderPage(this.state, {super.key});

  @override
  State<WorkoutBuilderPage> createState() => _WorkoutBuilderPageState();
}

class _WorkoutBuilderPageState extends State<WorkoutBuilderPage> {
  final focuses = <String>{};
  int count = 5;

  /// Ruční výměny cviků (index v náhledu → ID cviku). Po změně partií
  /// nebo počtu se zahodí, protože se náhled sestaví znovu.
  final swaps = <int, String>{};

  SplitDay get day {
    final built = buildDay(focuses, count);
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
        const SnackBar(content: Text('Tenhle cvik už v tréninku je.')),
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
      appBar: AppBar(title: const Text('Sestavit trénink')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          Text(
            'Vyber partie a počet cviků. Těžké vícekloubové cviky jdou '
            'první, další míří na různé hlavy svalu.',
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.l),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final f in dayFocuses)
                FilterChip(
                  label: Text(f.name),
                  selected: focuses.contains(f.id),
                  onSelected: (on) => _change(
                    () => on ? focuses.add(f.id) : focuses.remove(f.id),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          Panel(
            child: StepperControl(
              label: 'Počet cviků',
              value: count,
              min: 1,
              max: maxBuiltExercises,
              onChanged: (n) => _change(() => count = n),
              spoken: (n) => '$n cviků',
            ),
          ),
          if (current.exercises.isNotEmpty) ...[
            SectionHeader(current.name),
            GroupedSection(
              footer: short
                  ? 'Pro zvolené partie víc různých cviků nemám.'
                  : 'Klepnutím cvik vyměníš za jiný na stejnou hlavu svalu.',
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
                      semanticLabel: 'Vyměnit',
                    ),
                    chevron: false,
                    onTap: () => _swap(i, current.exercises[i].exerciseId),
                  ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: Space.xxl),
              child: EmptyState(
                icon: Icons.accessibility_new_rounded,
                title: 'Vyber aspoň jednu partii',
                message: 'Třeba Hrudník a Triceps, nebo jen Nohy.',
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
                  'Začít trénink',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => popOnce(context, current),
                ),
              ),
            ),
    );
  }
}
