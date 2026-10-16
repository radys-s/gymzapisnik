import 'package:flutter/material.dart';

import '../../coach/achievements.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';

/// Ikona podle toho, co odznak měří.
IconData badgeIcon(BadgeMetric m) => switch (m) {
  BadgeMetric.workouts => Icons.fitness_center_rounded,
  BadgeMetric.weekRun => Icons.local_fire_department_rounded,
  BadgeMetric.weekWorkouts => Icons.date_range_rounded,
  BadgeMetric.volumeTons => Icons.scale_rounded,
  BadgeMetric.records => Icons.emoji_events_rounded,
  BadgeMetric.sets => Icons.repeat_rounded,
  BadgeMetric.longMinutes => Icons.timer_outlined,
  BadgeMetric.earlyStarts => Icons.wb_twilight_rounded,
  BadgeMetric.lateStarts => Icons.nightlight_round,
  BadgeMetric.distinctExercises => Icons.explore_rounded,
};

/// Postup u zamčeného odznaku, např. „12 / 25 tréninků“.
String badgeProgressLabel(BadgeState s) {
  final unit = switch (s.badge.metric) {
    BadgeMetric.workouts => 'tréninků',
    BadgeMetric.weekRun => 'týdnů v řadě',
    BadgeMetric.weekWorkouts => 'tréninků za týden',
    BadgeMetric.volumeTons => 't',
    BadgeMetric.records => 'rekordů',
    BadgeMetric.sets => 'sérií',
    BadgeMetric.longMinutes => 'min',
    BadgeMetric.earlyStarts || BadgeMetric.lateStarts => '',
    BadgeMetric.distinctExercises => 'cviků',
  };
  if (unit.isEmpty) return 'Stačí jednou';
  final value = s.value > s.badge.target ? s.badge.target : s.value;
  return '$value / ${s.badge.target} $unit';
}

/// Odznaky: odemčené i zamčené s postupem.
class AchievementsPage extends StatelessWidget {
  final AppState state;
  const AchievementsPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final all = state.badgeStates;
      final count = all.where((b) => b.unlocked).length;
      return LargeTitlePage(
        title: 'Odznaky',
        children: [
          Text(
            '$count z ${all.length} odemčeno. Odznaky přibývají za '
            'pravidelnost, rekordy a odcvičený objem.',
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          for (final group in BadgeGroup.values) ...[
            SectionHeader(group.label),
            Panel(
              child: LayoutBuilder(
                builder: (context, c) {
                  final columns = c.maxWidth >= 480 ? 4 : 3;
                  final width =
                      (c.maxWidth - (columns - 1) * Space.s) / columns;
                  return Wrap(
                    spacing: Space.s,
                    runSpacing: Space.l,
                    children: [
                      for (final b in all)
                        if (b.badge.group == group)
                          SizedBox(width: width, child: BadgeTile(b)),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      );
    },
  );
}

/// Medaile s názvem; klepnutí ukáže detail.
class BadgeTile extends StatelessWidget {
  final BadgeState state;
  const BadgeTile(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final b = state.badge;
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: () => _details(context),
      label:
          '${b.title}, ${state.unlocked ? 'odemčeno' : badgeProgressLabel(state)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.control),
        onTap: () => _details(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              BadgeMedal(state),
              const SizedBox(height: Space.s),
              Text(
                b.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: state.unlocked ? p.label : p.secondaryLabel,
                ),
              ),
              if (!state.unlocked) ...[
                const SizedBox(height: Space.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 4,
                    backgroundColor: p.fill,
                    color: p.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _details(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final at = state.unlockedAt;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeMedal(state, size: 88),
              const SizedBox(height: Space.m),
              Text(state.badge.title, style: text.titleLarge),
              const SizedBox(height: Space.xs),
              Text(
                state.badge.detail,
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const SizedBox(height: Space.s),
              Text(
                at != null
                    ? 'Odemčeno ${formatDate(at)}'
                    : badgeProgressLabel(state),
                style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Kruhová medaile: zlatá, když je odznak odemčený.
class BadgeMedal extends StatelessWidget {
  final BadgeState state;
  final double size;
  const BadgeMedal(this.state, {super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = state.unlocked;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? null : p.fill,
        gradient: on
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.gold, Color.lerp(p.gold, Colors.deepOrange, 0.45)!],
              )
            : null,
        border: on ? null : Border.all(color: p.separator),
      ),
      child: Icon(
        badgeIcon(state.badge.metric),
        size: size * 0.46,
        color: on ? Colors.black : p.tertiaryLabel,
      ),
    );
  }
}
