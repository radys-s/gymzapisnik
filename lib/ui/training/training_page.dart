import 'package:flutter/material.dart';

import '../../core/i18n.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../home/recovery_card.dart';
import '../onboarding/onboarding_page.dart' show PlanSetupPage;
import '../program/program_page.dart';
import '../widgets/labels.dart';
import '../workout/launcher.dart';

/// Záložka Trénink (jako v Hevy): prázdný trénink jako první akce, pod ním
/// rutiny z programu, hotové plány a regenerace svalů.
class TrainingPage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;
  const TrainingPage(this.state, {super.key, this.now = DateTime.now});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> with WorkoutLauncher {
  @override
  AppState get state => widget.state;

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.any,
    builder: (context, _) {
      final p = context.palette;
      final split = state.split;
      final active = state.active;
      final today = state.todaySplitDay;
      return LargeTitlePage(
        title: tr('Trénink', 'Training'),
        children: [
          if (active != null)
            PrimaryButton(
              tr('Pokračovat: ${active.name}', 'Continue: ${active.name}'),
              icon: Icons.play_arrow_rounded,
              busy: starting,
              onPressed: () => runWorkout(() async {}),
            )
          else
            PrimaryButton(
              tr('Začít prázdný trénink', 'Start empty workout'),
              icon: Icons.add_rounded,
              busy: starting,
              onPressed: () => runWorkout(state.startWorkout),
            ),
          const SizedBox(height: Space.s),
          SecondaryButton(
            tr('Sestavit podle partií', 'Build by muscle groups'),
            icon: Icons.tune_rounded,
            onPressed: active == null ? buildWorkout : null,
          ),
          SectionHeader(
            tr('Moje rutiny', 'My routines'),
            action: split == null ? null : tr('Upravit', 'Edit'),
            onAction: split == null ? null : () => _push(ProgramPage(state)),
          ),
          if (split == null)
            GroupedSection(
              children: [
                GroupedRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: p.accent,
                  title: tr('Sestavit plán na míru', 'Build a tailored plan'),
                  subtitle: tr(
                    'Pár otázek a rutiny jsou hotové',
                    'A few questions and your routines are ready',
                  ),
                  onTap: () => _push(PlanSetupPage(state)),
                ),
              ],
            )
          else
            for (var i = 0; i < split.days.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: _RoutineCard(
                  state: state,
                  index: i,
                  today: i == today % split.days.length,
                  onStart: active == null
                      ? () => runWorkout(() => state.startSplitDay(i))
                      : null,
                ),
              ),
          SectionHeader(tr('Prozkoumat', 'Explore')),
          GroupedSection(
            dividerIndent: 58,
            children: [
              GroupedRow(
                icon: Icons.view_list_rounded,
                title: tr('Hotové programy', 'Ready-made programs'),
                subtitle: split == null
                    ? null
                    : tr('Teď: ${split.name}', 'Now: ${split.name}'),
                onTap: () => _push(ProgramPage(state)),
              ),
              GroupedRow(
                icon: Icons.quiz_outlined,
                title: tr('Plán podle dotazníku', 'Plan from quiz'),
                subtitle: tr(
                  'Cíl, čas a vybavení',
                  'Goal, time, and equipment',
                ),
                onTap: () => _push(PlanSetupPage(state)),
              ),
            ],
          ),
          if (state.workouts.isNotEmpty && active == null) ...[
            SectionHeader(tr('Regenerace svalů', 'Muscle recovery')),
            RecoveryPanel(
              state: state,
              now: widget.now(),
              onBuild: buildWorkout,
            ),
          ],
          const SizedBox(height: Space.xl),
        ],
      );
    },
  );
}

/// Rutina jako karta (Hevy): název, náhled cviků, rozsah a tlačítko Začít.
class _RoutineCard extends StatelessWidget {
  final AppState state;
  final int index;
  final bool today;
  final VoidCallback? onStart;
  const _RoutineCard({
    required this.state,
    required this.index,
    required this.today,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final day = state.split!.days[index];
    final names = [
      for (final e in day.exercises) state.exercise(e.exerciseId).name,
    ];
    final preview =
        names.take(3).join(', ') +
        (names.length > 3
            ? tr(
                ' a další ${names.length - 3}',
                ' and ${names.length - 3} more',
              )
            : '');
    final minutes = workoutMinutes(day.exercises.fold(0, (n, e) => n + e.sets));
    return Panel(
      onTap: onStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.name,
                  style: text.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (today)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tr('DNES', 'TODAY'),
                    style: text.labelSmall?.copyWith(color: p.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
          ),
          const SizedBox(height: 4),
          Text(
            '${exercisesLabel(day.exercises.length)} · ~$minutes min',
            style: text.bodySmall?.copyWith(
              color: p.tertiaryLabel,
              fontFeatures: tabular,
            ),
          ),
          const SizedBox(height: Space.m),
          FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: today ? p.accent : p.fill,
              foregroundColor: today ? p.onAccent : p.label,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 20),
            label: Text(tr('Začít ${day.name}', 'Start ${day.name}')),
          ),
        ],
      ),
    );
  }
}
