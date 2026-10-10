import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../coach/missions.dart';
import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../../premium/entitlements.dart';
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
    final lines = !state.has(ProFeature.recap)
        ? const <String>[]
        : recapLines(
            week,
            previousWeekSummary(state.workouts, now, state.typeOf),
            weekRecordCount(state.workouts, now, state.typeOf),
          );
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
                  '${week.workouts}/${state.weekGoal}',
                  workoutsLabel(week.workouts).split(' ').last,
                ),
                stat('${week.sets}', setsLabel(week.sets).split(' ').last),
                stat('${formatKg(week.volumeKg.roundToDouble())} kg', 'objem'),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final line in lines)
                Text(
                  line,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    final metric = type == ExerciseType.weighted
        ? 'odhad 1RM'
        : 'max opakování';
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

/// Dnešní mise: co dnes dělat, postup v týdnu a streak.
class MissionCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const MissionCard(this.state, this.now, {super.key});

  static String title(Mission m) => switch (m.kind) {
    MissionKind.weekDone => 'Týdenní cíl splněn',
    MissionKind.doneToday => 'Dnes máš hotovo',
    MissionKind.catchUp => 'Dnes je potřeba trénovat',
    MissionKind.rest => 'Dnes odpočinek',
    MissionKind.trainToday => 'Dnes je dobrý den na trénink',
    MissionKind.plannedRest => 'Dnes volno podle plánu',
  };

  static String subtitle(Mission m) => switch (m.kind) {
    MissionKind.weekDone => 'Další trénink už je bonus.',
    MissionKind.doneToday => 'Dobrá práce. Další trénink až příště.',
    MissionKind.catchUp =>
      '${remainingWorkoutsLabel(m.remaining)} a ${daysLabel(m.daysLeft)} '
          'do konce týdne.',
    MissionKind.rest => 'Včera byl trénink. Klidně si dej další i dnes.',
    MissionKind.trainToday => 'Tvůj týdenní cíl je ${m.goal}×.',
    MissionKind.plannedRest =>
      'Hotovo ${m.done} z ${m.goal}. Trénink se počítá i mimo plán.',
  };

  static IconData icon(MissionKind kind) => switch (kind) {
    MissionKind.weekDone => Icons.emoji_events_outlined,
    MissionKind.doneToday => Icons.check_circle_outline,
    MissionKind.catchUp => Icons.priority_high,
    MissionKind.rest => Icons.bedtime_outlined,
    MissionKind.trainToday => Icons.fitness_center,
    MissionKind.plannedRest => Icons.bedtime_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final m = state.mission(now);
    final streak = state.streak(now);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final urgent = m.kind == MissionKind.catchUp;
    final dots = m.goal.clamp(1, 7);
    return Card(
      color: urgent ? scheme.tertiaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon(m.kind), color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(title(m), style: text.titleMedium)),
                if (streak.weeks > 0)
                  Tooltip(
                    message: streak.jokerReady
                        ? 'Žolík je připravený: zachrání jeden zmeškaný týden.'
                        : 'Žolík se po použití obnoví za pár týdnů.',
                    child: Chip(
                      avatar: Icon(
                        Icons.local_fire_department,
                        size: 18,
                        color: scheme.primary,
                      ),
                      label: Text(weeksLabel(streak.weeks)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle(m), style: TextStyle(color: scheme.onSurfaceVariant)),
            if (streak.jokerJustUsed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Žolík ti minulý týden zachránil streak.',
                  style: TextStyle(color: scheme.primary),
                ),
              ),
            const SizedBox(height: 12),
            Semantics(
              container: true,
              label: 'Tento týden ${m.done} z ${m.goal} tréninků',
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var i = 0; i < dots; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        i < m.done ? Icons.circle : Icons.circle_outlined,
                        size: 14,
                        color: scheme.primary,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '${m.done}/${m.goal} tento týden',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
