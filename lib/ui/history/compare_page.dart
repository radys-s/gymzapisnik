import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';

/// Vybere druhý trénink a otevře porovnání s [workout].
Future<void> compareWithAnother(
  BuildContext context,
  AppState state,
  Workout workout,
) async {
  final mine = {for (final e in workout.exercises) e.exerciseId};
  final others =
      state.workouts.where((w) => w.finished && w.id != workout.id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  final other = await showModalBottomSheet<Workout>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              Space.page,
              0,
              Space.page,
              Space.l,
            ),
            children: [
              Text(tr('Porovnat s…', 'Compare with…'), style: text.titleLarge),
              const SizedBox(height: Space.xs),
              Text(
                tr(
                  'Vyber trénink. Uvidíš ho vedle tohoto série po sérii.',
                  'Pick a workout. You will see it next to this one, set by set.',
                ),
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
              const SizedBox(height: Space.m),
              GroupedSection(
                children: [
                  for (final w in others)
                    GroupedRow(
                      title: w.name,
                      subtitle: _sharedLabel(
                        formatDate(w.date),
                        w.exercises
                            .map((e) => e.exerciseId)
                            .toSet()
                            .intersection(mine)
                            .length,
                      ),
                      onTap: () => Navigator.pop(context, w),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (other == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => CompareWorkoutsPage(state, workout, other),
    ),
  );
}

String _sharedLabel(String date, int shared) => switch (shared) {
  0 => tr('$date · žádný společný cvik', '$date · no shared exercises'),
  1 => tr('$date · 1 společný cvik', '$date · 1 shared exercise'),
  < 5 => tr(
    '$date · $shared společné cviky',
    '$date · $shared shared exercises',
  ),
  _ => tr(
    '$date · $shared společných cviků',
    '$date · $shared shared exercises',
  ),
};

/// Dva tréninky vedle sebe: novější vlevo, starší vpravo.
class CompareWorkoutsPage extends StatelessWidget {
  final AppState state;
  final Workout newer;
  final Workout older;

  CompareWorkoutsPage(this.state, Workout a, Workout b, {super.key})
    : newer = a.date.isBefore(b.date) ? b : a,
      older = a.date.isBefore(b.date) ? a : b;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: p.secondaryLabel);
    final numbers = text.bodyMedium?.copyWith(fontFeatures: tabular);
    // Dva tréninky z jednoho dne rozliší až čas.
    final sameDay = formatDate(newer.date) == formatDate(older.date);
    String when(Workout w) =>
        sameDay ? formatDateTime(w.date) : formatDate(w.date);
    final left = when(newer);
    final right = when(older);

    Widget columns(String label, String a, String b, {TextStyle? style}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(width: 64, child: Text(label, style: muted)),
              Expanded(child: Text(a, style: style ?? numbers)),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(
                  b,
                  style: (style ?? numbers)?.copyWith(color: p.secondaryLabel),
                ),
              ),
            ],
          ),
        );

    String length(Workout w) => switch (w.finishedAt) {
      final end? => durationLabel(end.difference(w.startedAt)),
      null => '–',
    };
    String kg(Workout w) {
      var sum = 0.0;
      for (final e in w.exercises) {
        if (state.typeOf(e.exerciseId) == ExerciseType.weighted) {
          sum += volume(ExerciseType.weighted, e.sets);
        }
      }
      return '${formatVolume(sum)} kg';
    }

    int sets(Workout w) =>
        w.exercises.fold(0, (n, e) => n + e.countedSets.length);

    return LargeTitlePage(
      title: tr('Porovnání', 'Comparison'),
      children: [
        Panel(
          child: Column(
            children: [
              columns(
                '',
                newer.name,
                older.name,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              columns('', left, right, style: muted),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s),
                child: Divider(height: 0.5, thickness: 0.5, color: p.separator),
              ),
              columns(tr('Délka', 'Duration'), length(newer), length(older)),
              columns(tr('Objem', 'Volume'), kg(newer), kg(older)),
              columns(tr('Série', 'Sets'), '${sets(newer)}', '${sets(older)}'),
            ],
          ),
        ),
        for (final (a, b) in pairExercises(newer, older))
          _ExercisePair(
            state: state,
            newer: a,
            older: b,
            newerDate: left,
            olderDate: right,
          ),
      ],
    );
  }
}

class _ExercisePair extends StatelessWidget {
  final AppState state;
  final WorkoutExercise? newer;
  final WorkoutExercise? older;
  final String newerDate;
  final String olderDate;
  const _ExercisePair({
    required this.state,
    required this.newer,
    required this.older,
    required this.newerDate,
    required this.olderDate,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: p.secondaryLabel);
    final numbers = text.bodyMedium?.copyWith(fontFeatures: tabular);
    final id = (newer ?? older)!.exerciseId;
    final type = state.typeOf(id);
    final List<SetComparison> rows;
    final String verdict;
    final Trend overall;
    if (newer case final n?) {
      final c = compareExercise(type, n, older);
      rows = c.sets;
      overall = c.overall;
      verdict = switch (c.overall) {
        Trend.better => tr(
          'Zlepšení proti $olderDate',
          'Improved vs $olderDate',
        ),
        Trend.same => tr('Stejně jako $olderDate', 'Same as $olderDate'),
        Trend.worse => tr('Slabší než $olderDate', 'Weaker than $olderDate'),
        Trend.added => tr('Jen $newerDate', 'Only $newerDate'),
        Trend.missing => tr('Bez pracovní série', 'No working set'),
      };
    } else {
      rows = [
        for (final s in older!.countedSets)
          SetComparison(null, s, Trend.missing),
      ];
      overall = Trend.missing;
      verdict = tr('Jen $olderDate', 'Only $olderDate');
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(state.exercise(id).name, style: text.titleMedium),
              ),
              if (newer != null && older != null) TrendIcon(overall),
            ],
          ),
          Text(verdict, style: muted),
          const SizedBox(height: Space.m),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('${i + 1}', style: muted)),
                  Expanded(
                    child: Text(
                      rows[i].today == null
                          ? '–'
                          : setLabel(type, rows[i].today!),
                      style: numbers,
                    ),
                  ),
                  SizedBox(
                    width: 26,
                    child: newer != null && older != null
                        ? TrendIcon(rows[i].trend)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      rows[i].last == null
                          ? '–'
                          : setLabel(type, rows[i].last!),
                      style: numbers?.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
