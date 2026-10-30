import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../coach/missions.dart';
import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/stats.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';
import '../widgets/labels.dart';

/// Řádky shrnutí týdne: objem proti minulému týdnu a rekordy.
List<String> recapLines(WeekSummary week, WeekSummary previous, int records) {
  final lines = <String>[];
  if (week.volumeKg > 0 && previous.volumeKg > 0) {
    final pct = ((week.volumeKg / previous.volumeKg - 1) * 100).round();
    lines.add(
      pct == 0
          ? 'Objem stejný jako minulý týden.'
          : 'Objem ${pct > 0 ? '+' : '−'}${pct.abs()} % oproti minulému týdnu.',
    );
  }
  if (records > 0) {
    lines.add(
      records == 1
          ? 'Nový rekord u 1 cviku.'
          : 'Nové rekordy u $records cviků.',
    );
  }
  return lines;
}

/// Nedávné osobní rekordy (max 3), klepnutí otevře detail cviku.
class RecentRecordsCard extends StatelessWidget {
  final AppState state;

  /// Už spočtené rekordy (jinak si je karta spočte sama).
  final List<PersonalRecord>? records;
  const RecentRecordsCard(this.state, {super.key, this.records});

  @override
  Widget build(BuildContext context) {
    final records = this.records ?? recentRecords(state.workouts, state.typeOf);
    if (records.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.l,
        vertical: Space.xs,
      ),
      child: Column(
        children: [
          for (final (i, r) in records.indexed) ...[
            if (i > 0) Divider(color: p.separator, height: 1),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailPage(state, r.exerciseId),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: p.accent),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.exercise(r.exerciseId).name,
                            style: text.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${r.kind.label} · ${formatDate(r.date)}',
                            style: text.bodySmall?.copyWith(
                              color: p.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      recordLabel(r.kind, r.value),
                      style: text.titleSmall?.copyWith(
                        color: p.positive,
                        fontFeatures: tabular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rychlý progres nejčastěji cvičeného cviku: křivka posledních
/// tréninků a změna od prvního zobrazeného bodu.
class QuickProgressCard extends StatelessWidget {
  final AppState state;

  /// Už spočtený cvik a jeho řada (jinak nejčastější cvik).
  final String? exerciseId;
  final List<ProgressPoint>? series;
  const QuickProgressCard(
    this.state, {
    super.key,
    this.exerciseId,
    this.series,
  });

  static const maxPoints = 12;

  @override
  Widget build(BuildContext context) {
    final id = exerciseId ?? mostTrainedExercise(state.workouts);
    if (id == null) return const SizedBox.shrink();
    final type = state.typeOf(id);
    final all = series ?? progressSeries(state.workouts, id, type);
    if (all.length < 2) return const SizedBox.shrink();
    final points = all.length > maxPoints
        ? all.sublist(all.length - maxPoints)
        : all;
    final delta = points.last.value - points.first.value;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final unit = type == ExerciseType.weighted ? 'kg' : 'opak.';
    final deltaText = type == ExerciseType.weighted
        ? formatKg(double.parse(delta.abs().toStringAsFixed(1)))
        : '${delta.abs().round()}';
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '±');
    final metric = type == ExerciseType.weighted
        ? 'Odhad 1RM'
        : 'Max opakování';
    final color = delta < 0 ? p.negative : p.accent;
    return Panel(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseDetailPage(state, id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(state.exercise(id).name, style: text.titleMedium),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$sign$deltaText $unit',
                style: text.headlineSmall?.copyWith(
                  color: color,
                  fontFeatures: tabular,
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: Text(
                  '$metric za ${workoutsLabel(points.length)}',
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          SizedBox(
            height: 72,
            child: ExcludeSemantics(
              child: LineChart(
                duration: Motion.of(context, Motion.slow),
                curve: Motion.curve,
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
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(
                        checkToShowDot: (spot, _) =>
                            spot.x == points.length - 1,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texty dnešní mise. Podtitulek mluví o datech (minulý trénink, zbytek
/// týdne), ne obecně.
abstract final class MissionCopy {
  static String title(Mission m) => switch (m.kind) {
    MissionKind.weekDone => 'Týdenní cíl splněn',
    MissionKind.doneToday => 'Dnes máš hotovo',
    MissionKind.catchUp => 'Dnes je potřeba trénovat',
    MissionKind.rest => 'Dnes odpočinek',
    MissionKind.trainToday => 'Tento týden ${m.done} z ${m.goal}',
    MissionKind.plannedRest => 'Dnes volno podle plánu',
  };

  /// [daysSince] = dní od posledního dokončeného tréninku (`null`: žádný).
  static String subtitle(Mission m, {int? daysSince}) => switch (m.kind) {
    MissionKind.weekDone => 'Další trénink už je bonus.',
    MissionKind.doneToday => 'Dobrá práce. Další trénink až příště.',
    MissionKind.catchUp =>
      '${remainingWorkoutsLabel(m.remaining)} a ${daysLabel(m.daysLeft)} '
          'do konce týdne.',
    MissionKind.rest => 'Včera byl trénink. Klidně si dej další i dnes.',
    MissionKind.trainToday => _since(daysSince),
    MissionKind.plannedRest =>
      'Hotovo ${m.done} z ${m.goal}. Trénink se počítá i mimo plán.',
  };

  static String _since(int? days) => switch (days) {
    null => 'První trénink tě čeká. Začni lehce a zapiš každou sérii.',
    <= 0 => 'Dnes už máš trénink za sebou.',
    1 => 'Minule včera. Hlídej, jak se tělo cítí.',
    < 7 => 'Minule před $days dny, máš odpočinuto.',
    _ => 'Od posledního tréninku je to přes týden. Začni o kus lehčeji.',
  };

  static IconData icon(MissionKind kind) => switch (kind) {
    MissionKind.weekDone => Icons.emoji_events_outlined,
    MissionKind.doneToday => Icons.check_circle_outline,
    MissionKind.catchUp => Icons.priority_high,
    MissionKind.rest => Icons.bedtime_outlined,
    MissionKind.trainToday => Icons.fitness_center,
    MissionKind.plannedRest => Icons.bedtime_outlined,
  };
}
