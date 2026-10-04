import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../exercises/exercise_detail_page.dart';
import '../widgets/labels.dart';

/// „Tento týden": tréninky, série a objem od pondělí.
class WeekCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const WeekCard(this.state, this.now, {super.key});

  @override
  Widget build(BuildContext context) {
    final week = weekSummary(state.workouts, now, state.typeOf);
    final text = Theme.of(context).textTheme;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: text.titleLarge),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    final perWeek = state.split?.perWeek;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tento týden', style: text.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                stat(
                  perWeek == null
                      ? '${week.workouts}'
                      : '${week.workouts}/$perWeek',
                  workoutsLabel(week.workouts).split(' ').last,
                ),
                stat('${week.sets}', setsLabel(week.sets).split(' ').last),
                stat('${formatKg(week.volumeKg.roundToDouble())} kg', 'objem'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nedávné osobní rekordy (max 3), klepnutí otevře detail cviku.
class RecentRecordsCard extends StatelessWidget {
  final AppState state;
  const RecentRecordsCard(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final records = recentRecords(state.workouts, state.typeOf);
    if (records.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Nedávné rekordy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final r in records)
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: Text(state.exercise(r.exerciseId).name),
              subtitle: Text(
                '${r.kind.label} ${recordLabel(r.kind, r.value)} · '
                '${formatDate(r.date)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailPage(state, r.exerciseId),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rychlý progres nejčastěji cvičeného cviku: malá křivka posledních
/// tréninků a změna od prvního zobrazeného bodu.
class QuickProgressCard extends StatelessWidget {
  final AppState state;
  const QuickProgressCard(this.state, {super.key});

  static const maxPoints = 12;

  @override
  Widget build(BuildContext context) {
    final id = mostTrainedExercise(state.workouts);
    if (id == null) return const SizedBox.shrink();
    final type = state.typeOf(id);
    final all = progressSeries(state.workouts, id, type);
    if (all.length < 2) return const SizedBox.shrink();
    final points = all.length > maxPoints
        ? all.sublist(all.length - maxPoints)
        : all;
    final delta = points.last.value - points.first.value;
    final scheme = Theme.of(context).colorScheme;
    final unit = type == ExerciseType.weighted ? 'kg' : 'opak.';
    final deltaText = type == ExerciseType.weighted
        ? formatKg(double.parse(delta.abs().toStringAsFixed(1)))
        : '${delta.abs().round()}';
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '±');
    final metric = type == ExerciseType.weighted ? 'odhad 1RM' : 'max opakování';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExerciseDetailPage(state, id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progres: ${state.exercise(id).name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '$metric $sign$deltaText $unit za ${workoutsLabel(points.length)}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 56,
                child: ExcludeSemantics(
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < points.length; i++)
                              FlSpot(i.toDouble(), points[i].value),
                          ],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: scheme.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: scheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
