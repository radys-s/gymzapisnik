import 'package:flutter/material.dart';

import '../../domain/anatomy.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import 'exercise_picker.dart';

/// Vybere náhradu za cvik: nejdřív cviky na stejnou hlavu svalu, pak
/// ostatní cviky partie podle hlavy. Vrací ID cviku, nebo null.
Future<String?> pickAlternative(
  BuildContext context,
  AppState state,
  String exerciseId,
) => Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (_) => AlternativesPage(state, exerciseId)),
);

class AlternativesPage extends StatelessWidget {
  final AppState state;
  final String exerciseId;
  const AlternativesPage(this.state, this.exerciseId, {super.key});

  Future<void> _all(BuildContext context) async {
    final ids = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => ExercisePickerPage(state, multiple: false),
      ),
    );
    if (ids == null || ids.isEmpty || !context.mounted) return;
    Navigator.pop(context, ids.first);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = state.exercise(exerciseId);
    final heads = headsLabel(exerciseId);
    final sections = alternativesFor(exerciseId, state.allExercises);
    return Scaffold(
      appBar: AppBar(title: const Text('Nahradit cvik')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.page,
          Space.s,
          Space.page,
          Space.xxl,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.name, style: text.titleLarge),
                const SizedBox(height: 2),
                Text(
                  heads.isEmpty ? current.muscle : heads,
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          for (final section in sections)
            GroupedSection(
              header: section.title,
              children: [
                for (final e in section.exercises)
                  GroupedRow(
                    title: e.name,
                    subtitle: _subtitle(e.id),
                    chevron: false,
                    onTap: () => Navigator.pop(context, e.id),
                  ),
              ],
            ),
          GroupedSection(
            children: [
              GroupedRow(
                leading: Icon(Icons.search_rounded, color: p.accent),
                title: 'Všechny cviky',
                onTap: () => _all(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Hlavní hlavy a u vícekloubových cviků i to, že jsou těžší.
  static String? _subtitle(String id) {
    final a = anatomyOf(id);
    if (a == null) return null;
    final heads = headsLabel(id);
    return a.compound ? '$heads · vícekloubový' : heads;
  }
}
