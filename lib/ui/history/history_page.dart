import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
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
      final text = Theme.of(context).textTheme;
      final children = <Widget>[
        Text('Historie', style: text.headlineMedium),
        const SizedBox(height: 8),
      ];
      if (state.workouts.isEmpty) {
        children.add(
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Zatím žádný dokončený trénink.'),
          ),
        );
      }
      String? month;
      for (final w in state.workouts) {
        final m = monthLabel(w.date);
        if (m != month) {
          month = m;
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
              child: Text(m, style: text.titleSmall),
            ),
          );
        }
        children.add(_WorkoutTile(state: state, workout: w));
      }
      return ListView(padding: const EdgeInsets.all(16), children: children);
    },
  );
}

class _WorkoutTile extends StatelessWidget {
  final AppState state;
  final Workout workout;
  const _WorkoutTile({required this.state, required this.workout});

  @override
  Widget build(BuildContext context) {
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(workout.name),
        subtitle: Text(
          '${formatDate(workout.date)} · ${setsLabel(sets)}'
          '${kg > 0 ? ' · ${formatKg(kg.roundToDouble())} kg' : ''}\n$names',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: prs > 0
            ? Chip(label: Text('$prs PR'), visualDensity: VisualDensity.compact)
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SummaryPage(state, workout)),
        ),
      ),
    );
  }
}
