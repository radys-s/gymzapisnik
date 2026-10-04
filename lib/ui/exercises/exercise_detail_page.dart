import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';

/// Detail cviku: rekordy, graf progresu, poslední vs předchozí a historie.
class ExerciseDetailPage extends StatelessWidget {
  final AppState state;
  final String exerciseId;
  const ExerciseDetailPage(this.state, this.exerciseId, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final exercise = state.exercise(exerciseId);
      final type = exercise.type;
      final sessions = exerciseHistory(state.workouts, exerciseId);
      final records = allTimeRecords(state.workouts, exerciseId, type);
      final points = progressSeries(state.workouts, exerciseId, type);
      final text = Theme.of(context).textTheme;
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      final last = sessions.lastOrNull;
      final previous = sessions.length > 1
          ? sessions[sessions.length - 2]
          : null;
      final comparison = last == null
          ? null
          : compareExercise(type, last.entry, previous?.entry);
      return Scaffold(
        appBar: AppBar(title: Text(exercise.name)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              [
                exercise.muscle,
                type == ExerciseType.bodyweight ? 'vlastní váha' : 's váhou',
              ].join(' · '),
              style: TextStyle(color: muted),
            ),
            if (sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('Tenhle cvik zatím nemáš v historii.'),
              ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Osobní rekordy', style: text.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final kind in recordKinds(type))
                    if (records[kind] != null)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recordLabel(kind, records[kind]!.value),
                              style: text.titleLarge,
                            ),
                            Text(kind.label, style: TextStyle(color: muted)),
                            Text(
                              formatDate(records[kind]!.date),
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ],
            if (points.length >= 2) ...[
              const SizedBox(height: 24),
              Text(
                type == ExerciseType.weighted
                    ? 'Odhad 1RM v čase'
                    : 'Max opakování v čase',
                style: text.titleMedium,
              ),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: _ProgressChart(points)),
            ],
            if (comparison != null && previous != null) ...[
              const SizedBox(height: 24),
              Text('Poslední proti předchozímu', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                '${trendLabel(comparison.overall)} · '
                'nejlepší série ${setLabel(type, comparison.bestToday!)}'
                '${comparison.bestLast == null ? '' : ' (předtím ${setLabel(type, comparison.bestLast!)})'}',
              ),
            ],
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Historie', style: text.titleMedium),
              for (final s in sessions.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(formatDate(s.date)),
                  subtitle: Text(
                    s.entry.countedSets
                        .map((x) => setLabel(type, x))
                        .join(', '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SummaryPage(state, s.workout),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}

class _ProgressChart extends StatelessWidget {
  final List<ProgressPoint> points;
  const _ProgressChart(this.points);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final values = points.map((p) => p.value);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15 + 1;
    return Semantics(
      label:
          'Graf progresu, ${points.length} tréninků, '
          'od ${formatKg(points.first.value.roundToDouble())} '
          'do ${formatKg(points.last.value.roundToDouble())}',
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i != value || i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  // Jen první, poslední a pár mezi, ať se popisky nepřekrývají.
                  final step = (points.length / 4).ceil();
                  if (i != points.length - 1 && i % step != 0) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date.toLocal();
                  return Text(
                    '${d.day}. ${d.month}.',
                    style: const TextStyle(fontSize: 11),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  formatKg(value.roundToDouble()),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value),
              ],
              color: scheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
