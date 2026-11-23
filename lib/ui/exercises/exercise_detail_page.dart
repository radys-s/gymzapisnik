import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../coach/evidence.dart';
import '../../core/i18n.dart';
import '../../core/format.dart';
import '../../core/text.dart';
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
      final csName = exercise.nameCs.trim();
      final showCs = csName.isNotEmpty && fold(csName) != fold(exercise.name);
      return LargeTitlePage(
        title: exercise.name,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.xs, 0, Space.xs, Space.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showCs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(csName, style: text.titleMedium),
                  ),
                Text(
                  [
                    muscleLabel(exercise.muscle),
                    exercise.equipment.label,
                    type == ExerciseType.bodyweight
                        ? tr('vlastní váha', 'bodyweight')
                        : tr('s váhou', 'weighted'),
                  ].join(' · '),
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          ..._about(context, exercise),
          if (sessions.isEmpty)
            EmptyState(
              icon: Icons.show_chart_rounded,
              title: tr('Zatím bez záznamu', 'No records yet'),
              message: tr(
                'Tenhle cvik zatím nemáš v historii.',
                'This exercise is not in your history yet.',
              ),
            ),
          if (kinds.isNotEmpty)
            HeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Osobní rekordy', 'Personal records'),
                    style: text.titleMedium,
                  ),
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
          if (_nextPrTarget(type, records, last) case final target?) ...[
            SectionHeader(tr('Další PR cíl', 'Next PR target')),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(target.title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    target.detail,
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    target.when,
                    style: text.bodySmall?.copyWith(color: p.tertiaryLabel),
                  ),
                ],
              ),
            ),
          ],
          if (records[RecordKind.bestE1rm] case final best?
              when hasStrengthStandard(exerciseId)) ...[
            SectionHeader(tr('Úroveň síly', 'Strength level')),
            _StrengthCard(state, exerciseId, best.value),
          ],
          if (records[RecordKind.bestE1rm] case final best?) ...[
            SectionHeader(tr('Kalkulačka 1RM', '1RM calculator')),
            _RepTable(best.value),
          ],
          if (points.length >= 2) ...[
            SectionHeader(
              type == ExerciseType.weighted
                  ? tr('Odhad 1RM v čase', 'Estimated 1RM over time')
                  : tr('Max opakování v čase', 'Max reps over time'),
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
            SectionHeader(tr('Poslední proti předchozímu', 'Last vs previous')),
            Panel(
              child: Text(
                [
                  trendLabel(comparison.overall),
                  if (comparison.bestToday != null)
                    tr(
                      'nejlepší série ${setLabel(type, comparison.bestToday!)}'
                          '${comparison.bestLast == null ? '' : ' (předtím ${setLabel(type, comparison.bestLast!)})'}',
                      'best set ${setLabel(type, comparison.bestToday!)}'
                          '${comparison.bestLast == null ? '' : ' (before ${setLabel(type, comparison.bestLast!)})'}',
                    ),
                ].join(' · '),
                style: text.bodyMedium?.copyWith(fontFeatures: tabular),
              ),
            ),
          ],
          if (sessions.isNotEmpty) ...[
            SectionHeader(tr('Historie', 'History')),
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
        SizedBox(height: 340, child: ExerciseAnimation(exercise)),
        const SizedBox(height: Space.l),
      ],
      if (evidenceFor(exercise.id) case final ev?)
        GroupedSection(
          header: tr('Proč tento cvik', 'Why this exercise'),
          footer: tr('Zdroj: ${ev.source}', 'Source: ${ev.source}'),
          children: [
            GroupedRow(
              icon: Icons.science_outlined,
              iconColor: p.accent,
              title: ev.text,
            ),
          ],
        ),
      if (anatomy != null)
        GroupedSection(
          header: tr('Svaly', 'Muscles'),
          children: [
            GroupedRow(
              icon: Icons.bolt_rounded,
              iconColor: p.accent,
              title: heads(anatomy.primary),
              subtitle: tr('Hlavně posiluje', 'Main target'),
            ),
            if (anatomy.secondary.isNotEmpty)
              GroupedRow(
                icon: Icons.add_rounded,
                iconColor: p.secondaryLabel,
                title: heads(anatomy.secondary),
                subtitle: tr('Pomáhají', 'Assist'),
              ),
          ],
        ),
      if (technique != null) ...[
        GroupedSection(
          header: tr('Technika', 'Technique'),
          children: [
            for (var i = 0; i < technique.steps.length; i++)
              GroupedRow(
                leading: _StepNumber(i + 1),
                title: technique.steps[i],
              ),
          ],
        ),
        GroupedSection(
          header: tr('Časté chyby', 'Common mistakes'),
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
          header: tr('Alternativy', 'Alternatives'),
          footer: tr(
            'Když je stroj obsazený nebo cvik nesedí.',
            'When the machine is taken or the exercise does not suit you.',
          ),
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

class _NextPr {
  final String title;
  final String detail;
  final String when;
  const _NextPr(this.title, this.detail, this.when);
}

_NextPr? _nextPrTarget(
  ExerciseType type,
  Map<RecordKind, PersonalRecord> records,
  ExerciseSession? last,
) {
  if (last == null) return null;
  final bestSet = last.entry.countedSets.isEmpty
      ? null
      : last.entry.countedSets.reduce((a, b) {
          final av = type == ExerciseType.weighted
              ? e1rm(a.weight, a.reps)
              : a.reps.toDouble();
          final bv = type == ExerciseType.weighted
              ? e1rm(b.weight, b.reps)
              : b.reps.toDouble();
          return bv > av ? b : a;
        });
  if (bestSet == null) return null;

  if (type == ExerciseType.bodyweight) {
    final current = records[RecordKind.maxReps]?.value.round() ?? bestSet.reps;
    final target = current + 1;
    return _NextPr(
      tr('$target opakování', '$target reps'),
      tr(
        'Tvůj aktuální rekord je $current opakování. Přidej 1 čisté opakování se stejnou technikou.',
        'Your current record is $current reps. Add 1 clean rep with the same technique.',
      ),
      tr(
        'Zkus to na dalším čerstvém tréninku, ideálně po 1-2 dnech odpočinku.',
        'Try it in your next fresh workout, ideally after 1-2 rest days.',
      ),
    );
  }

  final w = bestSet.weight;
  final r = bestSet.reps;
  if (w <= 0 || r <= 0) return null;
  final nextWeight = (w + (w >= 40 ? 2.5 : 1.25));
  final rounded = (nextWeight * 4).round() / 4;
  return _NextPr(
    '${formatKg(rounded)} kg × $r',
    tr(
      'Nebo nech ${formatKg(w)} kg a přidej +1 opakování. Malé kroky drží progres konzistentní.',
      'Or keep ${formatKg(w)} kg and add +1 rep. Small steps keep progress consistent.',
    ),
    tr(
      'Zkus další PR pokus, až bude série cítit lehce a spánek/regenerace budou v pohodě (obvykle za 1-2 tréninky).',
      'Try the next PR attempt when the set feels light and sleep/recovery are on point (usually in 1-2 workouts).',
    ),
  );
}

/// Kolik naložit na 3–12 opakování podle nejlepšího odhadu 1RM.
class _RepTable extends StatelessWidget {
  final double oneRm;
  const _RepTable(this.oneRm);

  static const reps = [3, 5, 6, 8, 10, 12];

  @override
  Widget build(BuildContext context) => GroupedSection(
    footer: tr(
      'Odhad z tvé nejlepší série: ${formatKg(oneRm.roundToDouble())} kg '
          'na jedno opakování. Ber to jako orientaci, ne jako cíl na každý trénink.',
      'Estimate from your best set: ${formatKg(oneRm.roundToDouble())} kg '
          'for one rep. Treat it as a guide, not a target for every workout.',
    ),
    children: [
      for (final r in reps)
        if (weightForReps(oneRm, r) > 0)
          GroupedRow(
            title: tr('$r opakování', '$r reps'),
            value: '${formatKg(weightForReps(oneRm, r))} kg',
            chevron: false,
          ),
    ],
  );
}

/// Číslo kroku techniky v kroužku.
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
      label: tr(
        'Graf progresu, ${points.length} tréninků, '
            'od ${formatKg(points.first.value.roundToDouble())} '
            'do ${formatKg(points.last.value.roundToDouble())}',
        'Progress chart, ${points.length} workouts, '
            'from ${formatKg(points.first.value.roundToDouble())} '
            'to ${formatKg(points.last.value.roundToDouble())}',
      ),
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
              tr(
                'Zapiš si tělesnou váhu a uvidíš svou úroveň síly '
                    'vůči vlastní váze.',
                'Log your body weight to see your strength level '
                    'relative to your own weight.',
              ),
              style: text.bodyMedium,
            )
          else if (level == null)
            Text(
              tr(
                'Vyber tabulku, se kterou se porovnáš.',
                'Pick a table to compare against.',
              ),
              style: text.bodyMedium,
            )
          else ...[
            Text(level.label, style: text.titleLarge),
            const SizedBox(height: 2),
            Text(
              tr(
                '1RM ${formatKg(oneRm.roundToDouble())} kg = '
                    '${level.ratio.toStringAsFixed(2).replaceAll('.', ',')}× '
                    'tělesné váhy',
                '1RM ${formatKg(oneRm.roundToDouble())} kg = '
                    '${level.ratio.toStringAsFixed(2)}× '
                    'body weight',
              ),
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
                semanticsLabel: tr(
                  'Postup k další úrovni',
                  'Progress to the next level',
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            Text(
              level.toNext == null
                  ? tr('Nejvyšší úroveň. Klobouk dolů.', 'Top level. Hats off.')
                  : tr(
                      'Do úrovně ${level.nextLabel} chybí '
                          '${formatKg(level.toNext!.ceilToDouble())} kg na 1RM.',
                      '${formatKg(level.toNext!.ceilToDouble())} kg on 1RM to reach ${level.nextLabel}.',
                    ),
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
