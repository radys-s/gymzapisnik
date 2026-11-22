import 'package:flutter/material.dart';

import '../../core/format.dart';
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
                  setsNoun(sets),
                  countTo: sets.toDouble(),
                  format: (v) => '${v.round()}',
                ),
                StatTile('$unlocked / ${badges.length}', 'odznaků'),
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
            const _Hint(
              'Křivka síly se ukáže po druhém tréninku stejného cviku.',
            ),
          if (records.isNotEmpty) RecentRecordsCard(state, records: records),
          _NextPrCard(state: state),
          ConsistencyCard(state: state, now: current),
          StrengthLevelsCard(state: state),
        ],
      ];
      return LargeTitlePage(
        title: 'Pokrok',
        tone: Tone.progress,
        actions: [
          // Historie a její hledání bez rolování pod grafy.
          if (finished.isNotEmpty)
            IconButton(
              tooltip: 'Historie',
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
            const SectionHeader('Trénink tento týden'),
            WeekSummaryCard(state: state, now: current),
            const SectionHeader('Objem podle partií'),
            CoverageCard(state: state, now: current),
          ],
          const SectionHeader('Přehled'),
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
        icon: Icons.insights_rounded,
        title: 'Statistiky',
        subtitle: 'Kalendář, grafy, měsíc proti minulému',
        onTap: () => push(StatsPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.fitness_center_rounded,
        title: 'Cviky a rekordy',
        subtitle: record == null
            ? null
            : 'Rekord: ${state.exercise(record.exerciseId).name} '
                  '${recordLabel(record.kind, record.value)}',
        onTap: () => push(ExercisesPage(state)),
      ),
      GroupedRow(
        icon: Icons.history_rounded,
        title: 'Historie',
        value: '$count',
        onTap: () => push(HistoryPage(state)),
      ),
      GroupedRow(
        icon: Icons.military_tech_rounded,
        title: 'Odznaky',
        value:
            '${state.badgeStates.where((b) => b.unlocked).length}'
            ' / ${state.badgeStates.length}',
        onTap: () => push(AchievementsPage(state)),
      ),
      GroupedRow(
        icon: Icons.monitor_weight_outlined,
        title: 'Váha a míry',
        value: state.bodyweights.isEmpty
            ? null
            : '${formatKg(state.bodyweights.first.kg)} kg',
        onTap: () => push(BodyweightPage(state)),
      ),
      GroupedRow(
        icon: Icons.calendar_view_week_rounded,
        title: 'Program',
        value: state.split?.name ?? 'Volně',
        onTap: () => push(ProgramPage(state)),
      ),
      GroupedRow(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Rady pro růst svalů',
        subtitle: 'Objem, technika, jídlo, spánek',
        onTap: () => push(GrowthPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.settings_outlined,
        title: 'Nastavení',
        subtitle: 'Pauza, krok váhy, záloha, soukromí',
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
                Text('Pokrok začne prvním tréninkem', style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Po každém tréninku tu přibudou rekordy, křivka síly '
                  'a odznaky.',
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
  const tiers = [
    (0, 'Starter', 'Buduješ základ. Hlavní je konzistence.'),
    (120, 'Builder', 'Základ sedí. Přidávej objem a kvalitu sérií.'),
    (300, 'Grinder', 'Pravidelnost se mění v výkon. Drž progres.'),
    (600, 'Athlete', 'Silná rutina. Teď hraj o PR a kvalitu.'),
    (1000, 'Elite', 'Top úroveň konzistence. Sbírej čisté PR.'),
  ];
  var idx = 0;
  for (var i = 0; i < tiers.length; i++) {
    if (score >= tiers[i].$1) idx = i;
  }
  final nextAt = idx < tiers.length - 1 ? tiers[idx + 1].$1 : tiers.last.$1;
  final color = [
    AppPalette.blue,
    AppPalette.green,
    AppPalette.orange,
    AppPalette.violet,
    AppPalette.yellow,
  ][idx];
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
                      'Tvá úroveň',
                      style: text.labelMedium?.copyWith(
                        color: p.secondaryLabel,
                      ),
                    ),
                    Text(
                      '${rank.name} · Lv. ${rank.level}',
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
                ? 'Max level - drž konzistenci a sbírej další PR.'
                : 'Do další úrovně: ${rank.nextAt - rank.score} bodů',
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
          final av = type == ExerciseType.weighted ? e1rm(a.weight, a.reps) : a.reps.toDouble();
          final bv = type == ExerciseType.weighted ? e1rm(b.weight, b.reps) : b.reps.toDouble();
          return bv > av ? b : a;
        });
        String title;
        String detail;
        if (type == ExerciseType.bodyweight) {
          final current = state.recordsOf(e.exerciseId)[RecordKind.maxReps]?.value.round() ?? bestSet.reps;
          title = '${current + 1} reps';
          detail = 'Teď: $current reps. Přidej 1 čisté opakování.';
        } else {
          final w0 = bestSet.weight;
          final r0 = bestSet.reps;
          if (w0 <= 0 || r0 <= 0) continue;
          final nextW = ((w0 + (w0 >= 40 ? 2.5 : 1.25)) * 4).round() / 4;
          title = '${formatKg(nextW)} kg × $r0';
          detail = 'Nebo ${formatKg(w0)} kg × ${r0 + 1}. Až to půjde lehce.';
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
              Text('Další PR cíle', style: text.titleMedium),
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
                        Text(c.detail, style: text.bodySmall?.copyWith(color: p.secondaryLabel)),
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
