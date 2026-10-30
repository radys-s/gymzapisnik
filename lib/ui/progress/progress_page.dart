import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/history.dart';
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
import '../home/dashboard.dart';
import '../premium/pro_gate.dart';
import '../program/program_page.dart';
import '../settings/settings_button.dart';
import '../stats/stats_page.dart';
import '../widgets/labels.dart';

/// Záložka Pokrok: křivka síly, rekordy, souhrn a cesty ke statistikám,
/// cvikům, odznakům a váze. Domov zůstává jen o dnešním tréninku.
class ProgressPage extends StatelessWidget {
  final AppState state;
  final DateTime Function() now;
  const ProgressPage(this.state, {super.key, this.now = DateTime.now});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final finished = state.workouts.where((w) => w.finished).toList();
      // Spočte se jednou a předá kartám (záložka je pořád v IndexedStack).
      final top = mostTrainedExercise(state.workouts);
      final series = top == null
          ? const <ProgressPoint>[]
          : progressSeries(state.workouts, top, state.typeOf(top));
      final records = recentRecords(state.workouts, state.typeOf);
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
      final blocks = <Widget>[
        if (finished.isEmpty)
          const _Empty()
        else ...[
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
        ],
      ];
      return LargeTitlePage(
        title: 'Pokrok',
        actions: [SettingsButton(state)],
        children: [
          for (final (i, b) in blocks.indexed)
            Padding(
              key: ValueKey(b.runtimeType),
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.m),
              child: Reveal(index: i, child: b),
            ),
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
    final accent = context.palette.accent;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    return [
      GroupedRow(
        icon: Icons.insights_rounded,
        iconColor: accent,
        title: 'Statistiky',
        subtitle: 'Kalendář, grafy, měsíc proti minulému',
        onTap: () => push(StatsPage(state, now: now)),
      ),
      GroupedRow(
        icon: Icons.fitness_center_rounded,
        iconColor: accent,
        title: 'Cviky a rekordy',
        subtitle: record == null
            ? null
            : 'Rekord: ${state.exercise(record.exerciseId).name} '
                  '${recordLabel(record.kind, record.value)}',
        onTap: () => push(ExercisesPage(state)),
      ),
      GroupedRow(
        icon: Icons.history_rounded,
        iconColor: accent,
        title: 'Historie',
        value: '$count',
        onTap: () => push(HistoryPage(state)),
      ),
      GroupedRow(
        icon: Icons.military_tech_rounded,
        iconColor: accent,
        title: 'Odznaky',
        value:
            '${state.badgeStates.where((b) => b.unlocked).length}'
            ' / ${state.badgeStates.length}',
        onTap: () => push(AchievementsPage(state)),
      ),
      GroupedRow(
        icon: Icons.monitor_weight_outlined,
        iconColor: accent,
        title: 'Tělesná váha',
        value: state.bodyweights.isEmpty
            ? null
            : '${formatKg(state.bodyweights.first.kg)} kg',
        onTap: () => push(BodyweightPage(state)),
      ),
      GroupedRow(
        icon: Icons.calendar_view_week_rounded,
        iconColor: accent,
        title: 'Program',
        value: state.split?.name ?? 'Volně',
        onTap: () => push(ProgramPage(state)),
      ),
      GroupedRow(
        icon: Icons.lightbulb_outline_rounded,
        iconColor: accent,
        title: 'Rady pro růst svalů',
        subtitle: 'Objem, technika, jídlo, spánek',
        onTap: () => push(GrowthPage(state, now: now)),
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
