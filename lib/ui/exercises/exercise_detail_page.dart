import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/anatomy.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../domain/strength.dart';
import '../../domain/technique.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../widgets/chart_axis.dart';
import '../widgets/exercise_media.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';

/// Detail cviku: fotky, svaly, technika a alternativy, pak rekordy,
/// graf progresu, poslední vs předchozí a historie.
class ExerciseDetailPage extends StatelessWidget {
  final AppState state;
  final String exerciseId;
  const ExerciseDetailPage(this.state, this.exerciseId, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      final exercise = state.exercise(exerciseId);
      final type = exercise.type;
      final sessions = state.historyOf(exerciseId);
      final records = state.recordsOf(exerciseId);
      final points = state.progressOf(exerciseId);
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final last = sessions.lastOrNull;
      final previous = sessions.length > 1
          ? sessions[sessions.length - 2]
          : null;
      final comparison = last == null
          ? null
          : compareExercise(type, last.entry, previous?.entry);
      final kinds = [
        for (final kind in recordKinds(type))
          if (records[kind] != null) kind,
      ];
      return LargeTitlePage(
        title: exercise.name,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.l),
            child: Text(
              [
                exercise.muscle,
                type == ExerciseType.bodyweight ? 'vlastní váha' : 's váhou',
              ].join(' · '),
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
          ),
          ..._about(context, exercise),
          if (sessions.isEmpty)
            const EmptyState(
              icon: Icons.show_chart_rounded,
              title: 'Zatím bez záznamu',
              message: 'Tenhle cvik zatím nemáš v historii.',
            ),
          if (kinds.isNotEmpty)
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Osobní rekordy', style: text.titleMedium),
                  const SizedBox(height: Space.m),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final kind in kinds)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatTile(
                                recordLabel(kind, records[kind]!.value),
                                kind.label,
                              ),
                              Text(
                                formatDate(records[kind]!.date),
                                style: text.bodySmall?.copyWith(
                                  color: p.tertiaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          if (records[RecordKind.bestE1rm] case final best?
              when hasStrengthStandard(exerciseId)) ...[
            const SectionHeader('Úroveň síly'),
            _StrengthCard(state, exerciseId, best.value),
          ],
          if (records[RecordKind.bestE1rm] case final best?) ...[
            const SectionHeader('Kalkulačka 1RM'),
            _RepTable(best.value),
          ],
          if (points.length >= 2) ...[
            SectionHeader(
              type == ExerciseType.weighted
                  ? 'Odhad 1RM v čase'
                  : 'Max opakování v čase',
            ),
            Panel(
              padding: const EdgeInsets.fromLTRB(
                Space.s,
                Space.l,
                Space.l,
                Space.s,
              ),
              child: SizedBox(height: 200, child: _ProgressChart(points)),
            ),
          ],
          if (comparison != null && previous != null) ...[
            const SectionHeader('Poslední proti předchozímu'),
            Panel(
              child: Text(
                '${trendLabel(comparison.overall)} · '
                'nejlepší série ${setLabel(type, comparison.bestToday!)}'
                '${comparison.bestLast == null ? '' : ' (předtím ${setLabel(type, comparison.bestLast!)})'}',
                style: text.bodyMedium?.copyWith(fontFeatures: tabular),
              ),
            ),
          ],
          if (sessions.isNotEmpty) ...[
            const SectionHeader('Historie'),
            GroupedSection(
              children: [
                for (final s in sessions.reversed)
                  GroupedRow(
                    title: formatDate(s.date),
                    subtitle: s.entry.countedSets
                        .map((x) => setLabel(type, x))
                        .join(', '),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SummaryPage(state, s.workout),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );

  /// Jak cvik vypadá, co posiluje, jak ho dělat a čím ho nahradit.
  List<Widget> _about(BuildContext context, Exercise exercise) {
    final p = context.palette;
    final anatomy = anatomyOf(exercise.id);
    final technique = techniqueOf(exercise.id);
    final alternatives = [
      for (final s in alternativesFor(exercise.id, state.allExercises))
        ...s.exercises,
    ].take(5).toList();
    String heads(List<String> ids) =>
        ids.map((id) => headById(id)?.name).nonNulls.join(', ');
    return [
      if (exercise.pattern.isNotEmpty) ...[
        ExerciseAnimation(exercise),
        const SizedBox(height: Space.l),
      ],
      if (anatomy != null)
        GroupedSection(
          header: 'Svaly',
          children: [
            GroupedRow(
              icon: Icons.bolt_rounded,
              iconColor: p.accent,
              title: heads(anatomy.primary),
              subtitle: 'Hlavně posiluje',
            ),
            if (anatomy.secondary.isNotEmpty)
              GroupedRow(
                icon: Icons.add_rounded,
                iconColor: p.secondaryLabel,
                title: heads(anatomy.secondary),
                subtitle: 'Pomáhají',
              ),
          ],
        ),
      if (technique != null) ...[
        GroupedSection(
          header: 'Technika',
          children: [
            for (var i = 0; i < technique.steps.length; i++)
              GroupedRow(
                leading: _StepNumber(i + 1),
                title: technique.steps[i],
              ),
          ],
        ),
        GroupedSection(
          header: 'Časté chyby',
          children: [
            for (final m in technique.mistakes)
              GroupedRow(
                icon: Icons.close_rounded,
                iconColor: p.negative,
                title: m,
              ),
          ],
        ),
      ],
      if (alternatives.isNotEmpty)
        GroupedSection(
          header: 'Alternativy',
          footer: 'Když je stroj obsazený nebo cvik nesedí.',
          children: [
            for (final a in alternatives)
              GroupedRow(
                leading: ExerciseThumb(a.id, size: 36),
                title: a.name,
                subtitle: headsLabel(a.id),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailPage(state, a.id),
                  ),
                ),
              ),
          ],
        ),
    ];
  }
}

/// Číslo kroku techniky v kroužku.
/// Kolik naložit na 3–12 opakování podle nejlepšího odhadu 1RM.
class _RepTable extends StatelessWidget {
  final double oneRm;
  const _RepTable(this.oneRm);

  static const reps = [3, 5, 6, 8, 10, 12];

  @override
  Widget build(BuildContext context) => GroupedSection(
    footer:
        'Odhad z tvé nejlepší série: ${formatKg(oneRm.roundToDouble())} kg '
        'na jedno opakování. Ber to jako orientaci, ne jako cíl na každý trénink.',
    children: [
      for (final r in reps)
        if (weightForReps(oneRm, r) > 0)
          GroupedRow(
            title: '$r opakování',
            value: '${formatKg(weightForReps(oneRm, r))} kg',
            chevron: false,
          ),
    ],
  );
}

class _StepNumber extends StatelessWidget {
  final int n;
  const _StepNumber(this.n);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$n',
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: p.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final List<ProgressPoint> points;
  const _ProgressChart(this.points);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = TextStyle(fontSize: 11, color: p.secondaryLabel);
    final values = points.map((p) => p.value);
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY) * 0.15 + 1;
    return Semantics(
      container: true,
      label:
          'Graf progresu, ${points.length} tréninků, '
          'od ${formatKg(points.first.value.roundToDouble())} '
          'do ${formatKg(points.last.value.roundToDouble())}',
      child: LineChart(
        LineChartData(
          minY: (minY - pad).clamp(0, double.infinity),
          maxY: maxY + pad,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: p.separator, strokeWidth: 0.5),
          ),
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
                  if (i != value || !showDateLabel(i, points.length)) {
                    return const SizedBox.shrink();
                  }
                  final d = points[i].date.toLocal();
                  return axisLabel(meta, '${d.day}. ${d.month}.', label);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => valueAxisLabel(
                  value,
                  meta,
                  formatKg(value.roundToDouble()),
                  label,
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
              gradient: LinearGradient(colors: p.gradient),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 3.5,
                  color: p.accent,
                  strokeWidth: 2,
                  strokeColor: p.grouped,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: p.accent.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Úroveň síly: nejlepší odhad 1RM proti tělesné váze.
class _StrengthCard extends StatelessWidget {
  final AppState state;
  final String exerciseId;
  final double oneRm;
  const _StrengthCard(this.state, this.exerciseId, this.oneRm);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final standard = state.profile.strengthStandard;
    final bodyweight = state.bodyweights.firstOrNull?.kg;
    final level = standard == null || bodyweight == null
        ? null
        : strengthLevel(exerciseId, oneRm, bodyweight, standard);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (bodyweight == null)
            Text(
              'Zapiš si tělesnou váhu a uvidíš svou úroveň síly '
              'vůči vlastní váze.',
              style: text.bodyMedium,
            )
          else if (level == null)
            Text(
              'Vyber tabulku, se kterou se porovnáš.',
              style: text.bodyMedium,
            )
          else ...[
            Text(level.label, style: text.titleLarge),
            const SizedBox(height: 2),
            Text(
              '1RM ${formatKg(oneRm.roundToDouble())} kg = '
              '${level.ratio.toStringAsFixed(2).replaceAll('.', ',')}× '
              'tělesné váhy',
              style: text.bodySmall?.copyWith(
                color: p.secondaryLabel,
                fontFeatures: tabular,
              ),
            ),
            const SizedBox(height: Space.m),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 8,
                semanticsLabel: 'Postup k další úrovni',
              ),
            ),
            const SizedBox(height: Space.s),
            Text(
              level.toNext == null
                  ? 'Nejvyšší úroveň. Klobouk dolů.'
                  : 'Do úrovně ${level.nextLabel} chybí '
                        '${formatKg(level.toNext!.ceilToDouble())} kg na 1RM.',
              style: text.bodySmall,
            ),
          ],
          if (bodyweight != null) ...[
            const SizedBox(height: Space.m),
            SegmentedButton<StrengthStandard>(
              segments: [
                for (final s in StrengthStandard.values)
                  ButtonSegment(value: s, label: Text(s.label)),
              ],
              selected: {?standard},
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              onSelectionChanged: (v) {
                if (v.isNotEmpty) state.setStrengthStandard(v.first);
              },
            ),
          ],
        ],
      ),
    );
  }
}
