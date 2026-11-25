import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../domain/stats.dart';
import '../../domain/strength.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';

/// Pravidelnost: posledních [weeks] týdnů po dnech, odcvičený den svítí.
class ConsistencyCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  final int weeks;
  const ConsistencyCard({
    super.key,
    required this.state,
    required this.now,
    this.weeks = 16,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    final first = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));
    final days = <int>{};
    for (final w in state.workouts) {
      if (!w.finished) continue;
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      final i = d.difference(first).inDays;
      if (i >= 0 && i < weeks * 7) days.add(i);
    }
    final activeWeeks = {for (final d in days) d ~/ 7}.length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('PRAVIDELNOST', 'CONSISTENCY'),
                      style: text.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr(
                        '${days.length} ${_days(days.length)} za $weeks týdnů',
                        '${days.length} ${days.length == 1 ? 'workout' : 'workouts'} in $weeks weeks',
                      ),
                      style: text.titleMedium,
                    ),
                  ],
                ),
              ),
              Text(
                tr('$activeWeeks/$weeks týdnů', '$activeWeeks/$weeks weeks'),
                style: text.labelMedium?.copyWith(fontFeatures: tabular),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          Semantics(
            label: tr(
              'Kalendář posledních $weeks týdnů, '
                  'odcvičeno ${days.length} dní',
              'Calendar of the last $weeks weeks, '
                  '${days.length} days trained',
            ),
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, box) {
                const gap = 3.0;
                final cell = ((box.maxWidth - gap * (weeks - 1)) / weeks).clamp(
                  6.0,
                  22.0,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var w = 0; w < weeks; w++)
                      Column(
                        children: [
                          for (var d = 0; d < 7; d++)
                            Container(
                              width: cell,
                              height: cell,
                              margin: EdgeInsets.only(bottom: d == 6 ? 0 : gap),
                              decoration: BoxDecoration(
                                color: _color(p, w * 7 + d, days, today, first),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Text(_month(first), style: text.labelSmall),
              const Spacer(),
              Text(tr('dnes', 'today'), style: text.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  static Color _color(
    AppPalette p,
    int index,
    Set<int> days,
    DateTime today,
    DateTime first,
  ) {
    if (days.contains(index)) return p.accent;
    final day = first.add(Duration(days: index));
    if (day.isAfter(today)) return Colors.transparent;
    return p.fill;
  }

  static String _days(int n) => n == 1
      ? 'trénink'
      : n >= 2 && n <= 4
      ? 'tréninky'
      : 'tréninků';

  static const _months = [
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
  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static String _month(DateTime d) =>
      isEnglish ? _monthsEn[d.month - 1] : _months[d.month - 1];
}

/// Úroveň síly ve čtyřech základních cvicích (dřep, bench, mrtvý tah,
/// tlak nad hlavu) jako žebříček: kde jsi a kolik chybí na další stupeň.
class StrengthLevelsCard extends StatelessWidget {
  final AppState state;
  const StrengthLevelsCard({super.key, required this.state});

  static const lifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bodyweight = state.bodyweights.firstOrNull?.kg;
    final standard = state.profile.strengthStandard ?? StrengthStandard.men;
    final rows = <Widget>[];
    for (final id in lifts) {
      final best = state.recordsOf(id)[RecordKind.bestE1rm];
      if (best == null) continue;
      final level = bodyweight == null
          ? null
          : strengthLevel(id, best.value, bodyweight, standard);
      rows.add(_LiftRow(state: state, id: id, oneRm: best.value, level: level));
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('ÚROVEŇ SÍLY', 'STRENGTH LEVEL'), style: text.labelSmall),
          const SizedBox(height: 2),
          Text(
            bodyweight == null
                ? tr(
                    'Zapiš tělesnou váhu a uvidíš svou úroveň',
                    'Log your body weight to see your level',
                  )
                : tr(
                    'Odhad 1RM vůči tělesné váze '
                        '${formatKg(bodyweight)} kg',
                    'Estimated 1RM vs body weight '
                        '${formatKg(bodyweight)} kg',
                  ),
            style: text.bodySmall,
          ),
          const SizedBox(height: Space.m),
          if (rows.isEmpty)
            Text(
              tr(
                'Zacvič dřep, bench, mrtvý tah nebo tlak nad hlavu a ukáže '
                    'se tvůj stupeň: od začátečníka po elitu.',
                'Train squat, bench, deadlift or overhead press and your '
                    'level will show: from beginner to elite.',
              ),
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            )
          else
            for (final (i, r) in rows.indexed) ...[
              if (i > 0) const SizedBox(height: Space.m),
              r,
            ],
        ],
      ),
    );
  }
}

class _LiftRow extends StatelessWidget {
  final AppState state;
  final String id;
  final double oneRm;
  final StrengthLevel? level;
  const _LiftRow({
    required this.state,
    required this.id,
    required this.oneRm,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final l = level;
    final name = state.exercise(id).name;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => ExerciseDetailPage(state, id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${formatKg(oneRm.roundToDouble())} kg',
                style: TextStyle(
                  fontFamily: condensedFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: p.label,
                  fontFeatures: tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Semantics(
            label: l == null
                ? tr('$name, úroveň neznámá', '$name, level unknown')
                : '$name, ${l.label}',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var s = 0; s < strengthLevels.length - 1; s++) ...[
                  if (s > 0) const SizedBox(width: 3),
                  Expanded(child: _Segment(fill: _fill(l, s))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                l?.label ?? '—',
                style: text.labelMedium?.copyWith(
                  color: l == null ? p.tertiaryLabel : p.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (l?.toNext case final kg?)
                Text(
                  '+${formatKg(kg.ceilToDouble())} kg → ${l!.nextLabel}',
                  style: text.labelMedium?.copyWith(fontFeatures: tabular),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Výplň dílku [segment] (0–1) podle úrovně a postupu k další.
  static double _fill(StrengthLevel? l, int segment) {
    if (l == null) return 0;
    if (segment < l.level) return 1;
    if (segment == l.level) return l.progress;
    return 0;
  }
}

class _Segment extends StatelessWidget {
  final double fill;
  const _Segment({required this.fill});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 6,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: p.fill),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fill.clamp(0, 1),
              child: ColoredBox(color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}
