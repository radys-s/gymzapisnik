import 'package:flutter/material.dart';

import '../../coach/progression.dart';
import '../../coach/splits.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../../premium/entitlements.dart';
import '../premium/pro_gate.dart';
import '../program/program_page.dart';
import '../settings/settings_page.dart';
import 'dashboard.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';
import '../workout/workout_page.dart';

class HomePage extends StatefulWidget {
  final AppState state;
  const HomePage(this.state, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Ručně zvolený jiný den splitu (jinak den na řadě).
  int? dayOverride;

  AppState get state => widget.state;

  Future<void> _run(Future<void> Function() start) async {
    await start();
    if (!mounted) return;
    setState(() => dayOverride = null);
    final finished = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(builder: (_) => WorkoutPage(state)),
    );
    if (finished != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryPage(state, finished, justFinished: true),
        ),
      );
    }
  }

  void _openProgram() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProgramPage(state)),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final active = state.active;
      final split = state.split;
      final last = state.workouts.firstOrNull;
      final text = Theme.of(context).textTheme;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: Text('Domů', style: text.headlineMedium)),
              IconButton(
                tooltip: 'Nastavení',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage(state)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProGate(
            state,
            ProFeature.mission,
            child: MissionCard(state, DateTime.now()),
          ),
          const SizedBox(height: 8),
          if (active != null)
            FilledButton.icon(
              onPressed: () => _run(() async {}),
              icon: const Icon(Icons.fitness_center),
              label: const Text('Pokračovat v tréninku'),
            )
          else if (split != null)
            _TodayCard(
              state: state,
              split: split,
              dayIndex: dayOverride ?? state.nextSplitDay,
              onStart: (i) => _run(() => state.startSplitDay(i)),
              onPickDay: (i) => setState(() => dayOverride = i),
              onFree: () => _run(state.startWorkout),
              onChangeSplit: _openProgram,
            )
          else ...[
            FilledButton.icon(
              onPressed: () => _run(state.startWorkout),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Začít trénink'),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('Vyber si split'),
                subtitle: const Text(
                  'Aplikace ti každý den nabídne trénink na řadě a návrh váhy.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openProgram,
              ),
            ),
          ],
          if (last != null) ...[
            const SizedBox(height: 16),
            WeekCard(state, DateTime.now()),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                title: const Text('Poslední trénink'),
                subtitle: Text(
                  '${last.name}\n${formatDateTime(last.date)} · '
                  '${setsLabel(_countedSets(last))}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SummaryPage(state, last)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            RecentRecordsCard(state),
            const SizedBox(height: 8),
            ProGate(
              state,
              ProFeature.progress,
              child: QuickProgressCard(state),
            ),
          ],
        ],
      );
    },
  );
}

int _countedSets(Workout w) =>
    w.exercises.fold(0, (n, e) => n + e.countedSets.length);

/// „Dnes: Push" – den splitu na řadě s návrhem pro každý cvik.
class _TodayCard extends StatelessWidget {
  final AppState state;
  final SplitTemplate split;
  final int dayIndex;
  final ValueChanged<int> onStart;
  final ValueChanged<int> onPickDay;
  final VoidCallback onFree;
  final VoidCallback onChangeSplit;

  const _TodayCard({
    required this.state,
    required this.split,
    required this.dayIndex,
    required this.onStart,
    required this.onPickDay,
    required this.onFree,
    required this.onChangeSplit,
  });

  @override
  Widget build(BuildContext context) {
    final day = split.day(dayIndex);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dnes: ${day.name}', style: text.titleLarge),
                      Text(
                        '${split.name} · den ${dayIndex % split.days.length + 1}'
                        '/${split.days.length}',
                        style: TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: 'Jiný den nebo split',
                  onSelected: (i) => i < 0 ? onChangeSplit() : onPickDay(i),
                  itemBuilder: (_) => [
                    for (var i = 0; i < split.days.length; i++)
                      PopupMenuItem(value: i, child: Text(split.days[i].name)),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: -1, child: Text('Změnit split')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final (p, s) in state.plan(day))
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(state.exercise(p.exerciseId).name)),
                    Text(
                      _target(state.typeOf(p.exerciseId), p, s),
                      style: TextStyle(
                        color: s.kind == SuggestionKind.increase
                            ? Theme.of(context).colorScheme.primary
                            : muted,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => onStart(dayIndex),
                icon: const Icon(Icons.play_arrow),
                label: Text('Začít ${day.name}'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: onFree,
                child: const Text('Volný trénink'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _target(ExerciseType type, PlannedExercise p, Suggestion s) {
    if (s.kind == SuggestionKind.start) {
      return '${p.sets}× ${p.repMin}–${p.repMax}';
    }
    final set = SetEntry(weight: s.weight, reps: s.reps);
    final arrow = switch (s.kind) {
      SuggestionKind.increase => ' ↑',
      SuggestionKind.deload => ' ↓',
      _ => '',
    };
    return '${s.sets}× ${setLabel(type, set)}$arrow';
  }
}
