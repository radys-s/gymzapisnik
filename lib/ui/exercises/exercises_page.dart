import 'package:flutter/material.dart';

import '../../core/text.dart';
import '../../domain/catalog.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import 'exercise_detail_page.dart';

/// Seznam cviků podle partií; nahoře cviky, které už mají historii.
class ExercisesPage extends StatefulWidget {
  final AppState state;
  const ExercisesPage(this.state, {super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String query = '';

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
      final text = Theme.of(context).textTheme;
      Widget tile(Exercise e) {
        final count = trained[e.id] ?? 0;
        return ListTile(
          title: Text(e.name),
          subtitle: Text(
            [
              e.muscle,
              if (e.type == ExerciseType.bodyweight) 'vlastní váha',
              if (e.custom) 'vlastní cvik',
              if (count > 0) '$count× v historii',
            ].join(' · '),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExerciseDetailPage(state, e.id)),
          ),
        );
      }

      final withHistory = all.where((e) => trained.containsKey(e.id)).toList()
        ..sort((a, b) => trained[b.id]!.compareTo(trained[a.id]!));
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Cviky', style: text.headlineMedium),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Hledat cvik',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          if (withHistory.isNotEmpty && folded.isEmpty) ...[
            _Header('Cvičené'),
            for (final e in withHistory) tile(e),
          ],
          for (final group in muscleGroups) ...[
            if (all.any((e) => e.muscle == group)) ...[
              _Header(group),
              for (final e
                  in all.where((e) => e.muscle == group).toList()
                    ..sort((a, b) => a.name.compareTo(b.name)))
                tile(e),
            ],
          ],
        ],
      );
    },
  );
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
