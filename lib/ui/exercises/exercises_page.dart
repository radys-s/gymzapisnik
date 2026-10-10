import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/text.dart';
import '../../domain/catalog.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../widgets/labels.dart';
import 'exercise_detail_page.dart';

/// Cviky podle partií; nahoře nedávné rekordy a cviky s historií.
class ExercisesPage extends StatefulWidget {
  final AppState state;
  const ExercisesPage(this.state, {super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String query = '';

  void _open(String id) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ExerciseDetailPage(widget.state, id)),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final state = widget.state;
      final folded = fold(query.trim());
      final trained = <String, int>{};
      for (final w in state.workouts) {
        for (final e in w.exercises) {
          if (e.countedSets.isNotEmpty) {
            trained.update(e.exerciseId, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      }
      final all = state.allExercises
          .where((e) => folded.isEmpty || fold(e.name).contains(folded))
          .toList();
      GroupedRow row(Exercise e) {
        final count = trained[e.id] ?? 0;
        return GroupedRow(
          title: e.name,
          subtitle: [
            e.muscle,
            if (e.type == ExerciseType.bodyweight) 'vlastní váha',
            if (e.custom) 'vlastní cvik',
          ].join(' · '),
          value: count > 0 ? '$count×' : null,
          onTap: () => _open(e.id),
        );
      }

      final records = folded.isEmpty
          ? recentRecords(state.workouts, state.typeOf)
          : const <PersonalRecord>[];
      final withHistory = all.where((e) => trained.containsKey(e.id)).toList()
        ..sort((a, b) => trained[b.id]!.compareTo(trained[a.id]!));
      return LargeTitlePage(
        title: 'Cviky',
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Hledat cvik',
              ),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          if (records.isNotEmpty)
            GroupedSection(
              header: 'Nedávné rekordy',
              dividerIndent: 58,
              children: [
                for (final r in records)
                  GroupedRow(
                    icon: Icons.emoji_events,
                    iconColor: const Color(0xFFFF9F0A),
                    title: state.exercise(r.exerciseId).name,
                    subtitle:
                        '${r.kind.label} ${recordLabel(r.kind, r.value)} · '
                        '${formatDate(r.date)}',
                    onTap: () => _open(r.exerciseId),
                  ),
              ],
            ),
          if (withHistory.isNotEmpty && folded.isEmpty)
            GroupedSection(
              header: 'Cvičené',
              children: [for (final e in withHistory) row(e)],
            ),
          if (all.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'Nic nenalezeno',
              message: 'Zkus jiný název. Vlastní cvik přidáš při tréninku.',
            ),
          for (final group in muscleGroups)
            if (all.any((e) => e.muscle == group))
              GroupedSection(
                header: group,
                children: [
                  for (final e
                      in all.where((e) => e.muscle == group).toList()
                        ..sort((a, b) => a.name.compareTo(b.name)))
                    row(e),
                ],
              ),
        ],
      );
    },
  );
}
