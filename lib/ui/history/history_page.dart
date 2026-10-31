import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';

const _months = [
  'Leden',
  'Únor',
  'Březen',
  'Duben',
  'Květen',
  'Červen',
  'Červenec',
  'Srpen',
  'Září',
  'Říjen',
  'Listopad',
  'Prosinec',
];

String monthLabel(DateTime d) {
  final local = d.toLocal();
  return '${_months[local.month - 1]} ${local.year}';
}

/// Dokončené tréninky po měsících, od nejnovějšího.
class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final groups = <String, List<Workout>>{};
      for (final w in state.workouts) {
        groups.putIfAbsent(monthLabel(w.date), () => []).add(w);
      }
      return LargeTitlePage(
        title: 'Historie',
        children: [
          if (state.workouts.isEmpty)
            const EmptyState(
              icon: Icons.history,
              title: 'Zatím žádný trénink',
              message: 'Dokončené tréninky se tu objeví po měsících.',
            ),
          for (final MapEntry(key: month, value: list) in groups.entries)
            GroupedSection(
              header: month,
              children: [
                for (final w in list) WorkoutRow(state: state, workout: w),
              ],
            ),
        ],
      );
    },
  );
}

/// Řádek tréninku: název, kdy, série a objem, štítek rekordu.
class WorkoutRow extends StatelessWidget {
  final AppState state;
  final Workout workout;
  final DateTime Function() now;
  const WorkoutRow({
    super.key,
    required this.state,
    required this.workout,
    this.now = DateTime.now,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    var sets = 0;
    var kg = 0.0;
    for (final e in workout.exercises) {
      sets += e.countedSets.length;
      if (state.typeOf(e.exerciseId) == ExerciseType.weighted) {
        kg += volume(ExerciseType.weighted, e.sets);
      }
    }
    // Počet cviků s novým rekordem (jedna série může přinést víc druhů PR).
    final prs = newRecords(
      workout,
      state.workouts,
      state.typeOf,
    ).map((r) => r.exerciseId).toSet().length;
    final names = workout.exercises
        .map((e) => state.exercise(e.exerciseId).name)
        .toSet()
        .join(', ');
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SummaryPage(state, workout)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.s, Space.m),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          workout.name,
                          style: text.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (prs > 0) ...[
                        const SizedBox(width: Space.s),
                        Pill(
                          prs == 1
                              ? 'Rekord'
                              : prs <= 4
                              ? '$prs rekordy'
                              : '$prs rekordů',
                          icon: Icons.emoji_events,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${relativeDay(workout.date, now())} · ${setsLabel(sets)}'
                    '${kg > 0 ? ' · ${formatVolume(kg)} kg' : ''}',
                    style: text.bodySmall?.copyWith(fontFeatures: tabular),
                  ),
                  Text(
                    names,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 22, color: p.tertiaryLabel),
          ],
        ),
      ),
    );
  }
}
