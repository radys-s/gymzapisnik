import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../coach/overview.dart';
import '../../coach/splits.dart';
import '../../coach/tips.dart';
import '../../coach/weeks.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../widgets/labels.dart';

const _months = [
  'leden',
  'únor',
  'březen',
  'duben',
  'květen',
  'červen',
  'červenec',
  'srpen',
  'září',
  'říjen',
  'listopad',
  'prosinec',
];

/// Statistiky: součty, měsíc proti minulému, kalendář a grafy po týdnech.
class StatsPage extends StatelessWidget {
  final AppState state;
  final DateTime Function() now;
  const StatsPage(this.state, {super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final at = now();
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final all = totalsOf(state.workouts, state.typeOf);
      final thisMonth = totalsOf(
        state.workouts,
        state.typeOf,
        from: monthStart(at),
        to: monthStart(at, 1),
      );
      // Minulý měsíc jen za stejný počet dní, ať je srovnání férové.
      final lastMonth = totalsOf(
        state.workouts,
        state.typeOf,
        from: monthStart(at, -1),
        to: sameTimeLastMonth(at),
      );
      final weeks = weeklyBuckets(state.workouts, at, state.typeOf);
      final focus = weeklyHardSets(
        state.workouts,
        at,
        (id) => state.exercise(id).muscle,
        days: 30,
      );
      if (all.workouts == 0) {
        return const LargeTitlePage(
          title: 'Statistiky',
          children: [
            EmptyState(
              icon: Icons.insights_rounded,
              title: 'Zatím bez dat',
              message:
                  'Po prvním dokončeném tréninku tu uvidíš kalendář, '
                  'grafy a součty.',
            ),
          ],
        );
      }
      return LargeTitlePage(
        title: 'Statistiky',
        children: [
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: StatTile('${all.workouts}', 'Tréninky')),
                    Expanded(
                      child: StatTile(
                        '${(all.time.inMinutes / 60).round()} h',
                        'Čas v posilovně',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.l),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        '${formatKg((all.volumeKg / 100).round() / 10)} t',
                        'Zvednuto',
                      ),
                    ),
                    Expanded(child: StatTile('${all.sets}', 'Série')),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader('Tento měsíc (${_months[at.toLocal().month - 1]})'),
          Panel(
            child: Column(
              children: [
                _CompareRow(
                  label: 'Tréninky',
                  now: '${thisMonth.workouts}',
                  before: '${lastMonth.workouts}',
                  better: thisMonth.workouts > lastMonth.workouts,
                ),
                _CompareRow(
                  label: 'Série',
                  now: '${thisMonth.sets}',
                  before: '${lastMonth.sets}',
                  better: thisMonth.sets > lastMonth.sets,
                ),
                _CompareRow(
                  label: 'Objem',
                  now: '${formatVolume(thisMonth.volumeKg)} kg',
                  before: '${formatVolume(lastMonth.volumeKg)} kg',
                  better: thisMonth.volumeKg > lastMonth.volumeKg,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 6, Space.l, 0),
            child: Text(
              '„Minule“ = minulý měsíc za stejný počet dní.',
              style: text.bodySmall,
            ),
          ),
          const SectionHeader('Kalendář'),
          Panel(
            child: _Heatmap(counts: dailyCounts(state.workouts), now: at),
          ),
          const SectionHeader('Tréninky po týdnech'),
          Panel(
            child: _WeekBars(
              weeks: weeks,
              value: (w) => w.totals.workouts.toDouble(),
              label: (v) => '${v.round()}',
              unit: 'tréninků',
            ),
          ),
          const SectionHeader('Objem po týdnech'),
          Panel(
            child: _WeekBars(
              weeks: weeks,
              value: (w) => w.totals.volumeKg / 1000,
              label: (v) => v == 0 ? '0' : formatKg((v * 10).round() / 10),
              unit: 'tun',
            ),
          ),
          const SectionHeader('Série na partii (30 dní)'),
          Panel(
            child: Column(
              children: [
                for (final f in dayFocuses)
                  _FocusBar(
                    name: f.name,
                    sets: focus[f.id] ?? 0,
                    max: focus.values.fold(1, math.max),
                  ),
              ],
            ),
          ),
          if (state.profile.adult)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, 6, Space.l, 0),
              child: Text(
                'Pro růst zhruba ${weeklySetsMin * 4}–${weeklySetsMax * 4} '
                'sérií na partii za 30 dní.',
                style: text.bodySmall?.copyWith(color: p.secondaryLabel),
              ),
            ),
        ],
      );
    },
  );
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String now;
  final String before;
  final bool better;
  const _CompareRow({
    required this.label,
    required this.now,
    required this.before,
    required this.better,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: tento měsíc $now, minulý $before',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label, style: text.bodyLarge)),
              const SizedBox(width: Space.m),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    now,
                    style: text.titleMedium?.copyWith(
                      fontFeatures: tabular,
                      color: better ? p.positive : p.label,
                    ),
                  ),
                  Text(
                    'minule $before',
                    style: text.bodySmall?.copyWith(fontFeatures: tabular),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kalendář posledních 16 týdnů: sloupec = týden, řádek = den.
class _Heatmap extends StatelessWidget {
  final Map<DateTime, int> counts;
  final DateTime now;
  const _Heatmap({required this.counts, required this.now});

  static const weeks = 16;
  static const _days = ['Po', '', 'St', '', 'Pá', '', 'Ne'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final current = weekStart(now);
    final first = DateTime(
      current.year,
      current.month,
      current.day - 7 * (weeks - 1),
    );
    final today = dayStart(now);
    var total = 0;
    var active = 0;
    for (var i = 0; i < weeks * 7; i++) {
      final n = counts[DateTime(first.year, first.month, first.day + i)] ?? 0;
      total += n;
      if (n > 0) active++;
    }
    return Semantics(
      label:
          'Za posledních $weeks týdnů ${workoutsLabel(total)}, '
          'dny s tréninkem: $active',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, c) {
            const gap = 3.0;
            const labelWidth = 22.0;
            final cell = math.min(
              18.0,
              (c.maxWidth - labelWidth - gap * (weeks - 1)) / weeks,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var d = 0; d < 7; d++)
                  Padding(
                    padding: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
                    child: Row(
                      children: [
                        SizedBox(
                          width: labelWidth,
                          child: Text(_days[d], style: text.labelSmall),
                        ),
                        for (var w = 0; w < weeks; w++) ...[
                          if (w > 0) const SizedBox(width: gap),
                          _cell(
                            p,
                            DateTime(
                              first.year,
                              first.month,
                              first.day + w * 7 + d,
                            ),
                            today,
                            cell,
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: Space.s),
                Text(
                  'Za $weeks týdnů ${workoutsLabel(total)}, dny s tréninkem: $active',
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cell(AppPalette p, DateTime day, DateTime today, double size) {
    final n = counts[day] ?? 0;
    final future = day.isAfter(today);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 4),
        color: future
            ? Colors.transparent
            : n == 0
            ? p.fill
            : p.accent.withValues(alpha: n == 1 ? 0.6 : 1),
        border: day == today ? Border.all(color: p.label, width: 1.5) : null,
      ),
    );
  }
}

/// Sloupcový graf po týdnech s hodnotou nad sloupcem.
class _WeekBars extends StatelessWidget {
  final List<WeekBucket> weeks;
  final double Function(WeekBucket) value;
  final String Function(double) label;
  final String unit;
  const _WeekBars({
    required this.weeks,
    required this.value,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final values = [for (final w in weeks) value(w)];
    final top = values.fold<double>(0, math.max);
    String date(DateTime d) => '${d.day}. ${d.month}.';
    return Semantics(
      label:
          'Posledních ${weeks.length} týdnů, $unit: '
          '${values.map(label).join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < weeks.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (values[i] > 0)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label(values[i]),
                                  style: text.labelSmall,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              height: top == 0
                                  ? 3
                                  : math.max(3, 90 * values[i] / top),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: values[i] == 0
                                    ? p.fill
                                    : i == weeks.length - 1
                                    ? p.accent
                                    : p.accent.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: Space.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date(weeks.first.monday),
                    maxLines: 1,
                    style: text.labelSmall,
                  ),
                ),
                Text('tento týden', maxLines: 1, style: text.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusBar extends StatelessWidget {
  final String name;
  final int sets;
  final int max;
  const _FocusBar({required this.name, required this.sets, required this.max});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$name: ${setsLabel(sets)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sets / max,
                    minHeight: 8,
                    backgroundColor: p.fill,
                    color: p.accent,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$sets',
                  textAlign: TextAlign.end,
                  style: text.bodyMedium?.copyWith(fontFeatures: tabular),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
