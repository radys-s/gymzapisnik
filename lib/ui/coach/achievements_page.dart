import 'package:flutter/material.dart';

import '../../coach/achievements.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../summary/share_card.dart';

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
  if (unit.isEmpty || s.badge.target == 1) return 'Stačí jednou';
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
        borderRadius: BorderRadius.circular(context.palette.controlRadius),
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

  void _details(BuildContext outer) => showModalBottomSheet<void>(
    context: outer,
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
              if (state.unlocked) ...[
                const SizedBox(height: Space.l),
                PrimaryButton(
                  'Sdílet odznak',
                  icon: Icons.ios_share_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    showShareImage(
                      outer,
                      fileName: 'odznak-${state.badge.id}.png',
                      button: 'Sdílet odznak',
                      child: BadgeShareCard(state),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Odemčený odznak jako obrázek ke sdílení: vždy tmavý, pevná velikost.
class BadgeShareCard extends StatelessWidget {
  final BadgeState state;
  const BadgeShareCard(this.state, {super.key});

  static const _bg = Color(0xFF0C0C10);
  static const _muted = Color(0xFFB4B4BC);
  static const _gold = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final at = state.unlockedAt;
    const white = TextStyle(color: Colors.white);
    return SizedBox(
      width: 360,
      height: 450,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(28),
          gradient: RadialGradient(
            center: const Alignment(0, -0.35),
            radius: 0.9,
            // Neprůhledné barvy, jinak PNG propustí pozadí (viz ShareCard).
            colors: [Color.alphaBlend(_gold.withValues(alpha: 0.22), _bg), _bg],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const AppMark(size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Gym zápisník',
                    style: white.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _gold,
                      Color.lerp(_gold, Colors.deepOrange, 0.45)!,
                    ],
                  ),
                ),
                child: Icon(
                  badgeIcon(state.badge.metric),
                  size: 60,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'ODZNAK ODEMČEN',
                style: white.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: white.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.badge.detail,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: white.copyWith(fontSize: 15, color: _muted),
              ),
              const Spacer(),
              if (at != null)
                Text(
                  formatDate(at),
                  style: white.copyWith(fontSize: 13, color: _muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
