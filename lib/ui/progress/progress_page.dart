import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../premium/entitlements.dart';
import '../../state/app_state.dart';
import '../bodyweight/bodyweight_page.dart';
import '../coach/achievements_page.dart';
import '../coach/growth_page.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../exercises/exercises_page.dart';
import '../history/history_page.dart';
import '../home/coverage_card.dart';
import '../home/dashboard.dart';
import '../premium/pro_gate.dart';
import '../program/program_page.dart';
import '../settings/settings_button.dart';
import '../settings/settings_page.dart';
import '../stats/stats_page.dart';
import '../widgets/labels.dart';
import 'progress_cards.dart';
import 'week_report_page.dart';

/// Záložka Pokrok: souhrn, křivka síly, rekordy a cesty ke statistikám,
/// cvikům, odznakům, váze a nastavení.
class ProgressPage extends StatelessWidget {
  final AppState state;
  final DateTime Function() now;
  const ProgressPage(this.state, {super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      final current = now();
      final finished = state.workouts.where((w) => w.finished).toList();
      // Spočte se jednou a předá kartám (záložka je pořád v IndexedStack).
      final top = state.mostTrained();
      final series = top == null
          ? const <ProgressPoint>[]
          : state.progressOf(top);
      final records = state.recentRecordList();
      final sets = finished.fold(
        0,
        (n, w) =>
            n +
            w.exercises.fold(
              0,
              (m, e) => m + e.sets.where((s) => s.counts).length,
            ),
      );
      final badges = state.badgeStates;
      final unlocked = badges.where((b) => b.unlocked).length;
      final rank = _trainingRank(
        finished.length,
        sets,
        unlocked,
        badges.length,
      );
      final blocks = <Widget>[
        if (finished.isEmpty)
          const _Empty()
        else ...[
          _RankCard(rank: rank),
          Panel(
            child: Wrap(
              spacing: Space.xl,
              runSpacing: Space.m,
              children: [
                StatTile(
                  '${finished.length}',
                  workoutsLabel(finished.length).split(' ').last,
                  countTo: finished.length.toDouble(),
                  format: (v) => '${v.round()}',
                ),
                StatTile(
                  '$sets',
                  isEnglish ? (sets == 1 ? 'set' : 'sets') : setsNoun(sets),
                  countTo: sets.toDouble(),
                  format: (v) => '${v.round()}',
                ),
                StatTile(
                  '$unlocked / ${badges.length}',
                  tr('odznaků', 'badges'),
                ),
              ],
            ),
          ),
          if (series.length >= 2)
            ProGate(
              state,
              ProFeature.progress,
              child: QuickProgressCard(state, exerciseId: top, series: series),
            )
          else
            _Hint(
              tr(
                'Křivka síly se ukáže po druhém tréninku stejného cviku.',
                'The strength curve appears after the second workout of the same exercise.',
              ),
            ),
          if (records.isNotEmpty) RecentRecordsCard(state, records: records),
          _NextPrCard(state: state),
          ConsistencyCard(state: state, now: current),
          StrengthLevelsCard(state: state),
        ],
      ];
      return LargeTitlePage(
        title: tr('Pokrok', 'Progress'),
        tone: Tone.progress,
        actions: [
          // Historie a její hledání bez rolování pod grafy.
          if (finished.isNotEmpty)
            IconButton(
              tooltip: tr('Historie', 'History'),
              icon: const Icon(Icons.history_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryPage(state)),
              ),
            ),
          SettingsButton(state),
        ],
        children: [
          for (final (i, b) in blocks.indexed)
            Padding(
              key: ValueKey(b.runtimeType),
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.m),
              child: Reveal(index: i, child: b),
            ),
          if (finished.isNotEmpty) ...[
            SectionHeader(
              tr('Trénink tento týden', "This week's training"),
              action: tr('Zpráva', 'Report'),
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WeekReportPage(state, now: now),
                ),
              ),
            ),
            WeekSummaryCard(state: state, now: current),
            SectionHeader(tr('Objem podle partií', 'Volume by muscle group')),
            CoverageCard(state: state, now: current),
          ],
          SectionHeader(tr('Přehled', 'Overview')),
          GroupedSection(
            dividerIndent: 58,
            children: _rows(context, finished.length, records.firstOrNull),
          ),
          const SizedBox(height: Space.xl),
        ],
      );
    },
  );

  List<Widget> _rows(BuildContext context, int count, PersonalRecord? record) {
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return [
      GroupedRow(
        icon: Icons.calendar_month_rounded,
        title: tr('Týdenní report', 'Weekly report'),
        subtitle: tr(
          'Objem po dnech, rekordy, srovnání s minulým týdnem',
          'Volume by day, records, comparison with last week',
        ),
        onTap: () => push(WeekReportPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.insights_rounded,
        title: tr('Statistiky', 'Statistics'),
        subtitle: tr(
          'Kalendář, grafy, měsíc proti minulému',
          'Calendar, charts, month vs previous',
        ),
        onTap: () => push(StatsPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.fitness_center_rounded,
        title: tr('Cviky a rekordy', 'Exercises & records'),
        subtitle: record == null
            ? null
            : tr(
                'Rekord: ${state.exercise(record.exerciseId).name} '
                    '${recordLabel(record.kind, record.value)}',
                'Record: ${state.exercise(record.exerciseId).name} '
                    '${recordLabel(record.kind, record.value)}',
              ),
        onTap: () => push(ExercisesPage(state)),
      ),
      GroupedRow(
        icon: Icons.history_rounded,
        title: tr('Historie', 'History'),
        value: '$count',
        onTap: () => push(HistoryPage(state)),
      ),
      GroupedRow(
        icon: Icons.military_tech_rounded,
        title: tr('Odznaky', 'Badges'),
        value:
            '${state.badgeStates.where((b) => b.unlocked).length}'
            ' / ${state.badgeStates.length}',
        onTap: () => push(AchievementsPage(state)),
      ),
      GroupedRow(
        icon: Icons.monitor_weight_outlined,
        title: tr('Váha a míry', 'Weight & measurements'),
        value: state.bodyweights.isEmpty
            ? null
            : '${formatKg(state.bodyweights.first.kg)} kg',
        onTap: () => push(BodyweightPage(state)),
      ),
      GroupedRow(
        icon: Icons.calendar_view_week_rounded,
        title: tr('Program', 'Program'),
        value: state.split?.name ?? tr('Volně', 'Freestyle'),
        onTap: () => push(ProgramPage(state)),
      ),
      GroupedRow(
        icon: Icons.lightbulb_outline_rounded,
        title: tr('Rady pro růst svalů', 'Muscle growth tips'),
        subtitle: tr(
          'Objem, technika, jídlo, spánek',
          'Volume, technique, food, sleep',
        ),
        onTap: () => push(GrowthPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.settings_outlined,
        title: tr('Nastavení', 'Settings'),
        subtitle: tr(
          'Pauza, krok váhy, záloha, soukromí',
          'Rest, weight step, backup, privacy',
        ),
        onTap: () => Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => SettingsPage(state))),
      ),
    ];
  }
}

/// Před prvním tréninkem: co tu přibude, místo prázdných nul.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(Icons.show_chart_rounded, color: p.accent),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'Pokrok začne prvním tréninkem',
                    'Progress starts with your first workout',
                  ),
                  style: text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  tr(
                    'Po každém tréninku tu přibudou rekordy, křivka síly '
                        'a odznaky.',
                    'After each workout, records, the strength curve '
                        'and badges appear here.',
                  ),
                  style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Panel(
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: context.palette.secondaryLabel),
    ),
  );
}

class _Rank {
  final String name;
  final String subtitle;
  final int level;
  final int nextAt;
  final int score;
  final Color color;
  const _Rank(
    this.name,
    this.subtitle,
    this.level,
    this.nextAt,
    this.score,
    this.color,
  );
}

_Rank _trainingRank(int workouts, int sets, int badges, int badgesTotal) {
  final score = workouts * 10 + sets + badges * 25;
  final tiers = [
    (
      0,
      tr('Nováček', 'Newcomer'),
      tr(
        'Buduješ základ. Hlavní je pravidelnost.',
        'Building the base. Consistency is what matters.',
      ),
    ),
    (
      120,
      tr('Pravidelný', 'Regular'),
      tr(
        'Základ sedí. Přidávej objem a kvalitu sérií.',
        'The base is solid. Add volume and set quality.',
      ),
    ),
    (
      300,
      tr('Dříč', 'Grinder'),
      tr(
        'Pravidelnost se mění ve výkon. Drž progres.',
        'Consistency is turning into performance. Keep progressing.',
      ),
    ),
    (
      600,
      tr('Atlet', 'Athlete'),
      tr(
        'Silná rutina. Teď hraj o rekordy a kvalitu.',
        'A strong routine. Now play for records and quality.',
      ),
    ),
    (
      1000,
      tr('Elita', 'Elite'),
      tr(
        'Špička pravidelnosti. Sbírej čisté rekordy.',
        'The top of consistency. Collect clean records.',
      ),
    ),
  ];
  var idx = 0;
  for (var i = 0; i < tiers.length; i++) {
    if (score >= tiers[i].$1) idx = i;
  }
  final nextAt = idx < tiers.length - 1 ? tiers[idx + 1].$1 : tiers.last.$1;
  // Jeden akcent; zlatá patří až nejvyšší úrovni (jako rekordy).
  final color = idx == tiers.length - 1 ? AppPalette.amber : AppPalette.ember;
  return _Rank(tiers[idx].$2, tiers[idx].$3, idx + 1, nextAt, score, color);
}

class _RankCard extends StatelessWidget {
  final _Rank rank;
  const _RankCard({required this.rank});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final prev = [0, 120, 300, 600, 1000][(rank.level - 1).clamp(0, 4)];
    final span = (rank.nextAt - prev).clamp(1, 100000);
    final progress = rank.level >= 5
        ? 1.0
        : ((rank.score - prev) / span).clamp(0.0, 1.0);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: rank.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.military_tech_rounded, color: rank.color),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Tvá úroveň', 'Your level'),
                      style: text.labelMedium?.copyWith(
                        color: p.secondaryLabel,
                      ),
                    ),
                    Text(
                      tr(
                        '${rank.name} · úroveň ${rank.level}',
                        '${rank.name} · level ${rank.level}',
                      ),
                      style: text.titleLarge,
                    ),
                  ],
                ),
              ),
              Text(
                '${rank.score}',
                style: text.titleMedium?.copyWith(
                  color: p.secondaryLabel,
                  fontFeatures: tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(
            rank.subtitle,
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: Space.m),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: p.fill,
              valueColor: AlwaysStoppedAnimation(rank.color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rank.level >= 5
                ? tr(
                    'Nejvyšší úroveň. Drž pravidelnost a sbírej rekordy.',
                    'Top level. Stay consistent and collect records.',
                  )
                : tr(
                    'Do další úrovně: ${rank.nextAt - rank.score} bodů',
                    'To the next level: ${rank.nextAt - rank.score} points',
                  ),
            style: text.bodySmall?.copyWith(color: p.tertiaryLabel),
          ),
        ],
      ),
    );
  }
}

class _NextPrCard extends StatelessWidget {
  final AppState state;
  const _NextPrCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final candidates = <({String id, String title, String detail})>[];
    final seen = <String>{};
    final workouts = state.workouts.where((w) => w.finished).toList();
    for (final w in workouts.reversed) {
      for (final e in w.exercises.reversed) {
        if (!seen.add(e.exerciseId)) continue;
        final sessions = state.historyOf(e.exerciseId);
        final last = sessions.lastOrNull;
        if (last == null || last.entry.countedSets.isEmpty) continue;
        final type = state.typeOf(e.exerciseId);
        final bestSet = last.entry.countedSets.reduce((a, b) {
          final av = type == ExerciseType.weighted
              ? e1rm(a.weight, a.reps)
              : a.reps.toDouble();
          final bv = type == ExerciseType.weighted
              ? e1rm(b.weight, b.reps)
              : b.reps.toDouble();
          return bv > av ? b : a;
        });
        String title;
        String detail;
        if (type == ExerciseType.bodyweight) {
          final current =
              state
                  .recordsOf(e.exerciseId)[RecordKind.maxReps]
                  ?.value
                  .round() ??
              bestSet.reps;
          title = '${current + 1} reps';
          detail = tr(
            'Teď: $current reps. Přidej 1 čisté opakování.',
            'Now: $current reps. Add 1 clean rep.',
          );
        } else {
          final w0 = bestSet.weight;
          final r0 = bestSet.reps;
          if (w0 <= 0 || r0 <= 0) continue;
          final nextW = ((w0 + (w0 >= 40 ? 2.5 : 1.25)) * 4).round() / 4;
          title = '${formatKg(nextW)} kg × $r0';
          detail = tr(
            'Nebo ${formatKg(w0)} kg × ${r0 + 1}. Až to půjde lehce.',
            'Or ${formatKg(w0)} kg × ${r0 + 1}. When it feels easy.',
          );
        }
        candidates.add((id: e.exerciseId, title: title, detail: detail));
        if (candidates.length >= 3) break;
      }
      if (candidates.length >= 3) break;
    }
    if (candidates.isEmpty) return const SizedBox.shrink();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: p.accent),
              const SizedBox(width: 8),
              Text(
                tr('Další PR cíle', 'Next PR targets'),
                style: text.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          for (final c in candidates) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(state.exercise(c.id).name, style: text.bodyLarge),
                        Text(
                          c.detail,
                          style: text.bodySmall?.copyWith(
                            color: p.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.s),
                  Text(
                    c.title,
                    style: text.titleSmall?.copyWith(
                      color: p.accent,
                      fontFeatures: tabular,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
