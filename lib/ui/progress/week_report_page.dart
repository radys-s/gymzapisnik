import 'package:flutter/material.dart';

import '../../coach/routine_audit.dart' show weekCoverage, weeklyRange;
import '../../coach/splits.dart' show dayFocuses;
import '../../coach/weeks.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../domain/week_report.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';
import '../widgets/labels.dart';

const _dayLetters = ['Po', 'Út', 'St', 'Čt', 'Pá', 'So', 'Ne'];

/// Týdenní report: objem po dnech, srovnání s minulým týdnem, rekordy,
/// cvik týdne a partie. Šipkami se jde do starších týdnů.
class WeekReportPage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;
  const WeekReportPage(this.state, {super.key, this.now = DateTime.now});

  @override
  State<WeekReportPage> createState() => _WeekReportPageState();
}

class _WeekReportPageState extends State<WeekReportPage> {
  late DateTime _monday = weekStart(widget.now());

  void _shift(int weeks) => setState(
    () => _monday = DateTime(
      _monday.year,
      _monday.month,
      _monday.day + 7 * weeks,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final thisWeek = weekStart(widget.now());
    final first = firstTrainingWeek(state.workouts) ?? thisWeek;
    final report = weekReport(state.workouts, _monday, state.typeOf);
    final prev = weekReport(
      state.workouts,
      DateTime(_monday.year, _monday.month, _monday.day - 7),
      state.typeOf,
    );
    final canBack = _monday.isAfter(first);
    final canForward = _monday.isBefore(thisWeek);
    return LargeTitlePage(
      title: 'Týdenní report',
      tone: Tone.progress,
      children: [
        _WeekSwitcher(
          monday: _monday,
          current: _monday == thisWeek,
          onBack: canBack ? () => _shift(-1) : null,
          onForward: canForward ? () => _shift(1) : null,
        ),
        const SizedBox(height: Space.m),
        if (report.isEmpty)
          EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Tenhle týden bez tréninku',
            message: _monday == thisWeek
                ? 'Po prvním tréninku tu uvidíš objem, čas a rekordy týdne.'
                : 'Žádný dokončený trénink. Šipkou se vrátíš jinam.',
          )
        else ...[
          _VolumeHero(report: report, prev: prev, today: widget.now()),
          const SizedBox(height: Space.m),
          _CompareGrid(report: report, prev: prev, goal: state.weekGoal),
          const SectionHeader('Rekordy týdne'),
          _Records(state: state, report: report),
          if (report.topExerciseId case final id?) ...[
            const SectionHeader('Cvik týdne'),
            _TopExercise(state: state, report: report, exerciseId: id),
          ],
          const SectionHeader('Série podle partií'),
          _Muscles(coverage: weekCoverage(state.workouts, report.end)),
        ],
        const SizedBox(height: Space.xl),
      ],
    );
  }
}

class _WeekSwitcher extends StatelessWidget {
  final DateTime monday;
  final bool current;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  const _WeekSwitcher({
    required this.monday,
    required this.current,
    this.onBack,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final range = monday.month == sunday.month
        ? '${monday.day}.–${sunday.day}. ${sunday.month}.'
        : '${monday.day}. ${monday.month}. – ${sunday.day}. ${sunday.month}.';
    return Row(
      children: [
        IconButton(
          tooltip: 'Předchozí týden',
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                current ? 'Tento týden' : range,
                style: text.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                current ? range : '${sunday.year}',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Další týden',
          onPressed: onForward,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Změna proti minulému týdnu v procentech (`null`, když minule nic).
int? _pct(num now, num before) =>
    before <= 0 ? null : ((now - before) / before * 100).round();

class _Delta extends StatelessWidget {
  final int? pct;
  const _Delta(this.pct);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = pct;
    if (v == null) return const SizedBox.shrink();
    final color = v > 0
        ? p.positive
        : v < 0
        ? p.secondaryLabel
        : p.tertiaryLabel;
    final icon = v > 0
        ? Icons.arrow_upward_rounded
        : v < 0
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    return Semantics(
      label: v == 0 ? 'stejně jako minule' : '$v % proti minulému týdnu',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text(
            '${v.abs()} %',
            style: TextStyle(
              fontFamily: textFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Velký objem týdne a sloupce po dnech.
class _VolumeHero extends StatelessWidget {
  final WeekReport report;
  final WeekReport prev;
  final DateTime today;
  const _VolumeHero({
    required this.report,
    required this.prev,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final byKg = report.volumeKg > 0;
    final values = byKg
        ? report.dailyVolume
        : [for (final s in report.dailySets) s.toDouble()];
    final max = values.fold(0.0, (a, b) => b > a ? b : a);
    final todayIndex = weekStart(today) == report.monday
        ? today.toLocal().weekday - 1
        : -1;
    return Panel(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            byKg ? 'OBJEM' : 'SÉRIE',
            style: text.labelSmall?.copyWith(
              color: p.secondaryLabel,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Space.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    byKg
                        ? '${formatVolume(report.volumeKg)} kg'
                        : '${report.sets}',
                    style: TextStyle(
                      fontFamily: condensedFont,
                      fontSize: 52,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: p.label,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.m),
              _Delta(
                byKg
                    ? _pct(report.volumeKg, prev.volumeKg)
                    : _pct(report.sets, prev.sets),
              ),
            ],
          ),
          const SizedBox(height: Space.xl),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayBar(
                      label: _dayLetters[i],
                      fraction: max == 0 ? 0 : values[i] / max,
                      trained: report.dailySets[i] > 0,
                      today: i == todayIndex,
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

class _DayBar extends StatelessWidget {
  final String label;
  final double fraction;
  final bool trained;
  final bool today;
  const _DayBar({
    required this.label,
    required this.fraction,
    required this.trained,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Motion.slow,
                curve: Curves.easeOutCubic,
                builder: (context, f, _) => trained
                    ? FractionallySizedBox(
                        heightFactor: f.clamp(0.06, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: p.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const SizedBox.expand(),
                        ),
                      )
                    : Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: today
                              ? p.accent.withValues(alpha: 0.35)
                              : p.fill,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: Space.s),
          Text(
            label,
            style: TextStyle(
              fontFamily: textFont,
              fontSize: 12,
              fontWeight: today ? FontWeight.w700 : FontWeight.w500,
              color: today ? p.accent : p.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareGrid extends StatelessWidget {
  final WeekReport report;
  final WeekReport prev;
  final int goal;
  const _CompareGrid({
    required this.report,
    required this.prev,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final cells = [
      (
        '${report.workouts}/$goal',
        'tréninky',
        _pct(report.workouts, prev.workouts),
      ),
      (
        durationLabel(report.time),
        'v posilovně',
        _pct(report.time.inMinutes, prev.time.inMinutes),
      ),
      ('${report.sets}', setsNoun(report.sets), _pct(report.sets, prev.sets)),
      ('${report.reps}', 'opakování', _pct(report.reps, prev.reps)),
    ];
    return Panel(
      child: Column(
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0)
              Divider(height: Space.xl, color: context.palette.separator),
            Row(
              children: [
                for (var col = 0; col < 2; col++)
                  Expanded(
                    child: _Cell(
                      value: cells[row * 2 + col].$1,
                      label: cells[row * 2 + col].$2,
                      pct: cells[row * 2 + col].$3,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final String label;
  final int? pct;
  const _Cell({required this.value, required this.label, this.pct});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StatTile(value, label),
      const SizedBox(height: 2),
      SizedBox(height: 18, child: _Delta(pct)),
    ],
  );
}

class _Records extends StatelessWidget {
  final AppState state;
  final WeekReport report;
  const _Records({required this.state, required this.report});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    if (report.records.isEmpty) {
      return Panel(
        child: Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: p.tertiaryLabel),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(
                'Tento týden bez nového rekordu. Další série je šance.',
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
            ),
          ],
        ),
      );
    }
    // Jeden řádek na cvik: hlavní hodnota je váha (u vlastní váhy
    // opakování), ostatní druhy rekordu jdou do podtitulku.
    final byExercise = <String, List<PersonalRecord>>{};
    for (final r in report.records) {
      byExercise.putIfAbsent(r.exerciseId, () => []).add(r);
    }
    final now = DateTime.now();
    return Panel(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.l,
        vertical: Space.xs,
      ),
      child: Column(
        children: [
          for (final (i, MapEntry(key: id, value: list))
              in byExercise.entries.indexed) ...[
            if (i > 0) Divider(color: p.separator, height: 1),
            Builder(
              builder: (context) {
                final main = list.firstWhere(
                  (r) =>
                      r.kind ==
                      (state.typeOf(id) == ExerciseType.weighted
                          ? RecordKind.maxWeight
                          : RecordKind.maxReps),
                  orElse: () => list.first,
                );
                final others = [
                  for (final r in list)
                    if (!identical(r, main))
                      '${r.kind.label} ${recordLabel(r.kind, r.value)}',
                ];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: p.gold),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.exercise(id).name,
                              style: text.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              [
                                main.kind.label,
                                ...others,
                                relativeDay(main.date, now),
                              ].join(' · '),
                              style: text.bodySmall?.copyWith(
                                color: p.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        recordLabel(main.kind, main.value),
                        style: text.titleSmall?.copyWith(
                          color: p.gold,
                          fontFeatures: tabular,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TopExercise extends StatelessWidget {
  final AppState state;
  final WeekReport report;
  final String exerciseId;
  const _TopExercise({
    required this.state,
    required this.report,
    required this.exerciseId,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final type = state.typeOf(exerciseId);
    var sets = 0;
    var kg = 0.0;
    SetEntry? best;
    for (final w in state.workouts) {
      if (!w.finished) continue;
      final at = w.date.toLocal();
      if (at.isBefore(report.monday) || at.isAfter(report.end)) continue;
      for (final e in w.exercises) {
        if (e.exerciseId != exerciseId) continue;
        for (final s in e.countedSets) {
          sets++;
          kg += s.weight * s.reps;
          if (best == null ||
              s.weight > best.weight ||
              (s.weight == best.weight && s.reps > best.reps)) {
            best = s;
          }
        }
      }
    }
    return Panel(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExerciseDetailPage(state, exerciseId),
        ),
      ),
      child: Row(
        children: [
          IconTile(Icons.local_fire_department_rounded, color: p.accent),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.exercise(exerciseId).name,
                  style: text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    setsLabel(sets),
                    if (type == ExerciseType.weighted && kg > 0)
                      '${formatVolume(kg)} kg',
                    if (best != null) 'nejlepší ${setLabel(type, best)}',
                  ].join(' · '),
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.tertiaryLabel),
        ],
      ),
    );
  }
}

class _Muscles extends StatelessWidget {
  final Map<String, double> coverage;
  const _Muscles({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final rows = [
      for (final f in dayFocuses)
        if ((coverage[f.id] ?? 0) > 0) (f, coverage[f.id]!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    if (rows.isEmpty) {
      return Panel(
        child: Text(
          'Cviky tohoto týdne nemají přiřazené partie.',
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
      );
    }
    String n(double v) => v % 1 == 0
        ? v.toInt().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return Panel(
      child: Column(
        children: [
          for (final (f, sets) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(f.name, style: text.bodyMedium),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: (sets / weeklyRange(f.id).$2).clamp(0, 1),
                        backgroundColor: p.fill,
                        color: sets >= weeklyRange(f.id).$1
                            ? p.positive
                            : p.accent,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      n(sets),
                      textAlign: TextAlign.end,
                      style: text.bodyMedium?.copyWith(fontFeatures: tabular),
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
