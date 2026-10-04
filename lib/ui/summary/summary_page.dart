import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../history/edit_workout_page.dart';
import '../widgets/labels.dart';
import '../workout/workout_page.dart';

/// Souhrn dokončeného tréninku: dnes proti minulému provedení a nové rekordy.
class SummaryPage extends StatelessWidget {
  final AppState state;
  final Workout workout;

  /// Po dokončení se ukáže „Hotovo"; z historie běžný návrat zpět.
  final bool justFinished;

  const SummaryPage(
    this.state,
    this.workout, {
    this.justFinished = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      // Po úpravě je v historii nová instance; smazaný trénink zmizí.
      final current = state.workouts
          .where((w) => w.id == workout.id)
          .firstOrNull;
      if (current == null) return const Scaffold();
      return _page(context, current);
    },
  );

  Future<void> _action(BuildContext context, Workout workout, String a) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (a) {
      case 'edit':
        await navigator.push(
          MaterialPageRoute(builder: (_) => EditWorkoutPage(state, workout)),
        );
      case 'repeat':
        if (state.active != null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Nejdřív dokonči rozepsaný trénink.')),
          );
          return;
        }
        await state.repeatWorkout(workout);
        final finished = await navigator.push<Workout>(
          MaterialPageRoute(builder: (_) => WorkoutPage(state)),
        );
        if (finished != null) {
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => SummaryPage(state, finished, justFinished: true),
            ),
          );
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Smazat trénink?'),
            content: Text('${workout.name}, ${formatDate(workout.date)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Zpět'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Smazat'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await state.deleteWorkout(workout);
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Trénink smazán.')),
        );
    }
  }

  Widget _page(BuildContext context, Workout workout) {
    final records = newRecords(workout, state.workouts, state.typeOf);
    final sets = workout.exercises.fold<int>(
      0,
      (sum, e) => sum + e.countedSets.length,
    );
    var kg = 0.0;
    for (final e in workout.exercises) {
      if (state.typeOf(e.exerciseId) == ExerciseType.weighted) {
        kg += volume(ExerciseType.weighted, e.sets);
      }
    }
    final duration = workout.finishedAt?.difference(workout.startedAt);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !justFinished,
        title: Text(justFinished ? 'Trénink hotový' : workout.name),
        actions: [
          if (!justFinished)
            PopupMenuButton<String>(
              onSelected: (a) => _action(context, workout, a),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'repeat', child: Text('Zopakovat')),
                PopupMenuItem(value: 'edit', child: Text('Upravit')),
                PopupMenuItem(value: 'delete', child: Text('Smazat')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (justFinished) Text(workout.name, style: text.titleLarge),
          Text(
            formatDateTime(workout.date),
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (duration != null)
                _Stat(label: 'Délka', value: durationLabel(duration)),
              _Stat(label: 'Série', value: '$sets'),
              _Stat(
                label: 'Objem',
                value: '${formatKg(kg.roundToDouble())} kg',
              ),
            ],
          ),
          if (workout.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(workout.note),
          ],
          if (records.isNotEmpty) ...[
            const SizedBox(height: 16),
            _RecordsCard(state: state, records: records),
          ],
          const SizedBox(height: 8),
          for (final entry in workout.exercises)
            _ComparisonCard(state: state, workout: workout, entry: entry),
          if (justFinished) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hotovo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _RecordsCard extends StatelessWidget {
  final AppState state;
  final List<PersonalRecord> records;
  const _RecordsCard({required this.state, required this.records});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              records.length == 1
                  ? 'Nový osobní rekord'
                  : 'Nové osobní rekordy (${records.length})',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${state.exercise(r.exerciseId).name} – ${r.kind.label}: '
                  '${recordLabel(r.kind, r.value)}',
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String trendLabel(Trend t) => switch (t) {
  Trend.better => 'Lepší než minule',
  Trend.same => 'Stejně jako minule',
  Trend.worse => 'Slabší než minule',
  Trend.added => 'Poprvé',
  Trend.missing => 'Bez pracovní série',
};

class _TrendIcon extends StatelessWidget {
  final Trend trend;
  const _TrendIcon(this.trend);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (trend) {
      Trend.better => Icon(Icons.arrow_upward, size: 18, color: scheme.primary),
      Trend.worse => Icon(Icons.arrow_downward, size: 18, color: scheme.error),
      Trend.same => Icon(
        Icons.drag_handle,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      _ => const SizedBox(width: 18),
    };
  }
}

class _ComparisonCard extends StatelessWidget {
  final AppState state;
  final Workout workout;
  final WorkoutExercise entry;
  const _ComparisonCard({
    required this.state,
    required this.workout,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final exercise = state.exercise(entry.exerciseId);
    final type = exercise.type;
    final last = lastPerformance(
      state.workouts,
      entry.exerciseId,
      excludeWorkoutId: workout.id,
      before: workout.date,
    );
    final c = compareExercise(type, entry, last?.entry);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final warmups = entry.sets.where((s) => s.done && s.warmup).length;
    String delta(double v) {
      final sign = v > 0 ? '+' : (v < 0 ? '−' : '±');
      return '$sign${volumeLabel(type, v.abs())}';
    }

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _TrendIcon(c.overall),
              ],
            ),
            Text(
              last == null
                  ? trendLabel(c.overall)
                  : '${trendLabel(c.overall)} (${formatDate(last.date)})',
              style: TextStyle(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < c.sets.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('${i + 1}')),
                    Expanded(
                      child: Text(
                        c.sets[i].today == null
                            ? '–'
                            : setLabel(type, c.sets[i].today!),
                      ),
                    ),
                    _TrendIcon(c.sets[i].trend),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.sets[i].last == null
                            ? ''
                            : 'minule ${setLabel(type, c.sets[i].last!)}',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ],
                ),
              ),
            if (warmups > 0)
              Text(
                'Rozcvička: ${setsLabel(warmups)}',
                style: TextStyle(color: muted, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Text(
              last == null
                  ? 'Objem ${volumeLabel(type, c.volumeToday)}'
                  : 'Objem ${volumeLabel(type, c.volumeToday)} '
                        '(${delta(c.volumeDelta)})',
            ),
            if (type == ExerciseType.weighted && c.bestToday != null)
              Text(
                'Odhad 1RM ${formatKg(e1rm(c.bestToday!.weight, c.bestToday!.reps).roundToDouble())} kg'
                '${c.bestLast == null ? '' : ' (minule ${formatKg(e1rm(c.bestLast!.weight, c.bestLast!.reps).roundToDouble())} kg)'}',
              ),
            if (entry.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(entry.note, style: TextStyle(color: muted, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
