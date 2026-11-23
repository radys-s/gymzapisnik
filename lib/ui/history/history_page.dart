import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../core/text.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';

String _monthName(int month) => switch (month) {
  1 => tr('Leden', 'January'),
  2 => tr('Únor', 'February'),
  3 => tr('Březen', 'March'),
  4 => tr('Duben', 'April'),
  5 => tr('Květen', 'May'),
  6 => tr('Červen', 'June'),
  7 => tr('Červenec', 'July'),
  8 => tr('Srpen', 'August'),
  9 => tr('Září', 'September'),
  10 => tr('Říjen', 'October'),
  11 => tr('Listopad', 'November'),
  12 => tr('Prosinec', 'December'),
  _ => '',
};

String monthLabel(DateTime d) {
  final local = d.toLocal();
  return '${_monthName(local.month)} ${local.year}';
}

/// [relativeDay] is shared and Czech-only, so keep the source text and add
/// the English day name here.
String _englishRelativeDay(DateTime d, DateTime now) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final diff = calendarDaysBetween(d, now);
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return weekdays[d.toLocal().weekday - 1];
  return formatDate(d);
}

/// Hledá v názvu tréninku, poznámkách a názvech cviků, bez diakritiky.
/// Víc slov musí sedět všechna („dřep nohy“).
bool matchesWorkout(
  Workout w,
  String query,
  String Function(String exerciseId) exerciseName,
) {
  final words = fold(query).split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = fold(
    [
      w.name,
      w.note,
      for (final e in w.exercises) ...[exerciseName(e.exerciseId), e.note],
    ].join(' '),
  );
  return words.every(haystack.contains);
}

/// Dokončené tréninky po měsících, od nejnovějšího.
class HistoryPage extends StatefulWidget {
  final AppState state;
  const HistoryPage(this.state, {super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String query = '';

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state.on.resting,
    builder: (context, _) {
      final state = widget.state;
      final groups = <String, List<Workout>>{};
      for (final w in state.workouts) {
        if (!matchesWorkout(w, query, (id) => state.exercise(id).name)) {
          continue;
        }
        groups.putIfAbsent(monthLabel(w.date), () => []).add(w);
      }
      return LargeTitlePage(
        title: tr('Historie', 'History'),
        children: [
          if (state.workouts.isEmpty)
            EmptyState(
              icon: Icons.history,
              title: tr('Zatím žádný trénink', 'No workouts yet'),
              message: tr(
                'Dokončené tréninky se tu objeví po měsících.',
                'Completed workouts will appear here by month.',
              ),
            )
          else ...[
            TextField(
              decoration: InputDecoration(
                hintText: tr(
                  'Hledat trénink nebo cvik',
                  'Search workouts or exercises',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: Space.m),
            if (groups.isEmpty)
              EmptyState(
                icon: Icons.search_off_rounded,
                title: tr('Nic nenalezeno', 'Nothing found'),
                message: tr(
                  'Zkus jiný název cviku nebo tréninku.',
                  'Try another exercise or workout name.',
                ),
              ),
          ],
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
    final at = now();
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
                              ? tr('Rekord', 'Record')
                              : prs <= 4
                              ? tr('$prs rekordy', '$prs records')
                              : tr('$prs rekordů', '$prs records'),
                          icon: Icons.emoji_events,
                          color: context.palette.gold,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tr(relativeDay(workout.date, at), _englishRelativeDay(workout.date, at))} · ${setsLabel(sets)}'
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
