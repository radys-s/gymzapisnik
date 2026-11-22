import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
                    child: Text(
                      'Česky: $csName',
                      style: text.titleSmall?.copyWith(
                        color: p.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  [
                    exercise.muscle,
                    exercise.equipment.label,
                    type == ExerciseType.bodyweight
                        ? 'vlastní váha'
                        : 's váhou',
                  ].join(' · '),
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ],
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
          if (_nextPrTarget(type, records, last) case final target?) ...[
            const SectionHeader('Další PR cíl'),
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
                [
                  trendLabel(comparison.overall),
                  if (comparison.bestToday != null)
                    'nejlepší série ${setLabel(type, comparison.bestToday!)}'
                        '${comparison.bestLast == null ? '' : ' (předtím ${setLabel(type, comparison.bestLast!)})'}',
                ].join(' · '),
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
    final text = Theme.of(context).textTheme;
    final anatomy = anatomyOf(exercise.id);
    final technique = techniqueOf(exercise.id);
    final alternatives = [
      for (final s in alternativesFor(exercise.id, state.allExercises))
        ...s.exercises,
    ].take(5).toList();
    String heads(List<String> ids) =>
        ids.map((id) => headById(id)?.name).nonNulls.join(', ');
    final cues = _scienceCues(exercise);
    return [
      if (exercise.pattern.isNotEmpty) ...[
        Panel(
          padding: const EdgeInsets.all(Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_outline_rounded, color: p.accent),
                  const SizedBox(width: 8),
                  Flexible(child: Text('Demo pohybu', style: text.titleMedium)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sleduj tempo a rozsah. Ovládej excentrickou fázi, udrž napětí v cílovém svalu.',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
              const SizedBox(height: Space.m),
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.card),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.fill,
                    border: Border.all(
                      color: p.separator.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(Radii.card),
                  ),
                  child: SizedBox(
                    height: 220,
                    child: Center(child: ExerciseAnimation(exercise)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.l),
      ],
      if (cues.isNotEmpty)
        GroupedSection(
          header: 'Tipy k technice',
          footer: 'Obecné principy techniky — přizpůsob je své mobilitě a vybavení.',
          children: [
            for (final cue in cues)
              GroupedRow(
                icon: Icons.science_outlined,
                iconColor: p.accent,
                title: cue,
              ),
          ],
        ),
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

List<String> _scienceCues(Exercise e) {
  final cues = <String>[];
  final p = e.pattern;
  if (p.contains('squat') || p == 'leg_press') {
    cues.addAll([
      'Drž celé chodidlo na zemi a kontroluj kolena ve směru prstů.',
      'Dýchej do břicha a zpevni trup před repem (brace).',
      'Zvol rozsah, který zvládneš bez ztráty neutrální páteře.',
    ]);
  } else if (p.contains('hinge') || p == 'deadlift') {
    cues.addAll([
      'Začni pohyb kyčlemi dozadu, činka/držadla blízko těla.',
      'Udrž neutrální páteř a pevný trup po celou sérii.',
      'Poháněj zvednutí hýžděmi, ne přetáčením zad.',
    ]);
  } else if (p.contains('push')) {
    cues.addAll([
      'Stáhni lopatky a udrž stabilní ramena před tlakem.',
      'Kontroluj excentriku a tlač přes plný, bezbolestný rozsah.',
      'Zápěstí drž neutrálně, lokty ve směru, který sedí kloubu.',
    ]);
  } else if (p.contains('pull') || p == 'row') {
    cues.addAll([
      'Začni stahnutím lopatek, pak táhni lokty.',
      'Nehoupej trupem; kontroluj návrat do plného protažení.',
      'Vyber váhu, která umožní plný rozsah bez švihů.',
    ]);
  } else if (p == 'fly' || p.contains('raise')) {
    cues.addAll([
      'Použij váhu, která dovolí kontrolu bez švihu.',
      'Drž mírné ohnutí loktů a napětí v cílovém svalu.',
      'Zastav v pozici, kde ještě držíš techniku a ramena v pohodě.',
    ]);
  } else if (p.contains('curl')) {
    cues.addAll([
      'Fixuj lokty u těla a eliminuj švih.',
      'Kontroluj dolní fázi 2-3 s pro větší mechanické napětí.',
      'Plně extenduj bez ztráty napětí v bicepsu.',
    ]);
  } else if (p.contains('triceps')) {
    cues.addAll([
      'Lokty drž stabilně; pohyb jde hlavně z loketního kloubu.',
      'Plně extenduj, ale nepropružuj loket.',
      'Kontroluj návrat, nenech váhu spadnout.',
    ]);
  } else if (p == 'core') {
    cues.addAll([
      'Dýchej a drž žebra stažená, neprohýbej bedra.',
      'Pohybuj se kontrolovaně, kvalita > počet opakování.',
      'Zastav sérii, když technika začíná padat.',
    ]);
  } else {
    cues.addAll([
      'Zahřej se specificky a zvol váhu pro čistou techniku.',
      'Kontroluj excentrickou fázi a plný bezbolestný rozsah.',
      'Zapisuj série pravidelně - progres vidíš jen z dat.',
    ]);
  }
  return cues;
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
      '$target opakování',
      'Tvůj aktuální rekord je $current opakování. Přidej 1 čisté opakování se stejnou technikou.',
      'Zkus to na dalším čerstvém tréninku, ideálně po 1-2 dnech odpočinku.',
    );
  }

  final w = bestSet.weight;
  final r = bestSet.reps;
  if (w <= 0 || r <= 0) return null;
  final nextWeight = (w + (w >= 40 ? 2.5 : 1.25));
  final rounded = (nextWeight * 4).round() / 4;
  return _NextPr(
    '${formatKg(rounded)} kg × $r',
    'Nebo nech ${formatKg(w)} kg a přidej +1 opakování. Malé kroky drží progres konzistentní.',
    'Zkus další PR pokus, až bude série cítit lehce a spánek/regenerace budou v pohodě (obvykle za 1-2 tréninky).',
  );
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
