import 'package:flutter/material.dart';

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
        title: 'Trénink',
        children: [
          if (active != null)
            PrimaryButton(
              'Pokračovat: ${active.name}',
              icon: Icons.play_arrow_rounded,
              busy: starting,
              onPressed: () => runWorkout(() async {}),
            )
          else
            PrimaryButton(
              'Začít prázdný trénink',
              icon: Icons.add_rounded,
              busy: starting,
              onPressed: () => runWorkout(state.startWorkout),
            ),
          const SizedBox(height: Space.s),
          SecondaryButton(
            'Sestavit podle partií',
            icon: Icons.tune_rounded,
            onPressed: active == null ? buildWorkout : null,
          ),
          SectionHeader(
            'Moje rutiny',
            action: split == null ? null : 'Upravit',
            onAction: split == null ? null : () => _push(ProgramPage(state)),
          ),
          if (split == null)
            GroupedSection(
              children: [
                GroupedRow(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: p.accent,
                  title: 'Sestavit plán na míru',
                  subtitle: 'Pár otázek a rutiny jsou hotové',
                  onTap: () => _push(PlanSetupPage(state)),
                ),
              ],
            )
          else
            GroupedSection(
              dividerIndent: 58,
              children: [
                for (final (i, day) in split.days.indexed)
                  GroupedRow(
                    icon: i == today % split.days.length
                        ? Icons.play_circle_fill_rounded
                        : Icons.play_circle_outline_rounded,
                    iconColor: i == today % split.days.length
                        ? p.accent
                        : p.secondaryLabel,
                    title: day.name,
                    subtitle:
                        '${exercisesLabel(day.exercises.length)} · '
                        '~${workoutMinutes(day.exercises.fold(0, (n, e) => n + e.sets))} min'
                        '${i == today % split.days.length ? ' · dnes' : ''}',
                    onTap: active == null
                        ? () => runWorkout(() => state.startSplitDay(i))
                        : null,
                  ),
              ],
            ),
          const SectionHeader('Prozkoumat'),
          GroupedSection(
            dividerIndent: 58,
            children: [
              GroupedRow(
                icon: Icons.view_list_rounded,
                iconColor: p.accent,
                title: 'Hotové programy',
                subtitle: split == null ? null : 'Teď: ${split.name}',
                onTap: () => _push(ProgramPage(state)),
              ),
              GroupedRow(
                icon: Icons.quiz_outlined,
                iconColor: p.accent,
                title: 'Plán podle dotazníku',
                subtitle: 'Cíl, čas a vybavení',
                onTap: () => _push(PlanSetupPage(state)),
              ),
            ],
          ),
          if (state.workouts.isNotEmpty && active == null) ...[
            const SectionHeader('Regenerace svalů'),
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
