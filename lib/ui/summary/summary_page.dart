import 'package:flutter/material.dart';

import '../../coach/achievements.dart';
import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';
import '../../state/app_state.dart';
import '../coach/achievements_page.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../history/compare_page.dart';
import '../history/edit_workout_page.dart';
import '../widgets/labels.dart';
import '../workout/workout_page.dart';
import 'share_card.dart';

/// Souhrn dokončeného tréninku: dnes proti minulému provedení a nové rekordy.
class SummaryPage extends StatefulWidget {
  final AppState state;
  final Workout workout;

  /// Po dokončení se ukáže „Hotovo"; z historie běžný návrat zpět.
  final bool justFinished;

  const SummaryPage(
    this.state,
    this.workout, {
    this.justFinished = false,
    super.key,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  AppState get state => widget.state;
  bool _busy = false;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      // Po úpravě je v historii nová instance; smazaný trénink zmizí.
      final current = state.workouts
          .where((w) => w.id == widget.workout.id)
          .firstOrNull;
      if (current == null) return const Scaffold();
      return _page(context, current);
    },
  );

  Future<void> _edit(Workout workout) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EditWorkoutPage(state, workout)),
  );

  Future<void> _repeat(Workout workout) async {
    if (_busy) return;
    if (state.active != null) {
      showToast(context, 'Nejdřív dokonči rozepsaný trénink.');
      return;
    }
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await state.repeatWorkout(workout);
    } catch (_) {
      if (mounted) showToast(context, 'Trénink se nepodařilo založit.');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    final finished = await navigator.push<Workout>(
      MaterialPageRoute(builder: (_) => WorkoutPage(state)),
    );
    if (finished != null) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => SummaryPage(state, finished, justFinished: true),
        ),
      );
    }
  }

  Future<void> _delete(Workout workout) async {
    final ok = await confirmAction(
      context,
      title: 'Smazat trénink?',
      message: '${workout.name}, ${formatDate(workout.date)}',
      confirm: 'Smazat',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await state.deleteWorkout(workout);
    } catch (_) {
      if (mounted) showToast(context, 'Trénink se nepodařilo smazat.');
      return;
    }
    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Trénink smazán.')));
  }

  Widget _page(BuildContext context, Workout workout) {
    final p = context.palette;
    final records = newRecords(workout, state.workouts, state.typeOf);
    final sets = workout.exercises.fold<int>(
      0,
      (sum, e) => sum + e.countedSets.length,
    );
    var kg = 0.0;
    for (final e in workout.exercises) {
      if (state.typeOf(e.exerciseId) == ExerciseType.weighted) {
        kg += volume(ExerciseType.weighted, e.sets);
      }
    }
    final duration = workout.finishedAt?.difference(workout.startedAt);
    final finished = widget.justFinished;
    // Pořadí a týden jen do tohoto tréninku (stejný čas rozhodne id).
    final ordered = state.workouts.where((w) => w.finished).toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });
    final index = ordered.indexWhere((w) => w.id == workout.id);
    final upTo = index < 0 ? ordered : ordered.sublist(0, index + 1);
    final number = index < 0 ? ordered.length + 1 : index + 1;
    final week = weekSummary(
      [...upTo, if (index < 0) workout],
      workout.date,
      state.typeOf,
    );
    return LargeTitlePage(
      title: finished ? 'Trénink hotový' : workout.name,
      implyLeading: !finished,
      actions: [
        IconButton(
          tooltip: 'Sdílet',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: () => showShareCard(
            context,
            state,
            workout,
            number: number,
            records: records.length,
          ),
        ),
        if (!finished)
          PopupMenuButton<String>(
            tooltip: 'Možnosti',
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (a) => switch (a) {
              'edit' => _edit(workout),
              'compare' => compareWithAnother(context, state, workout),
              _ => _delete(workout),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Upravit')),
              if (state.workouts.any((w) => w.finished && w.id != workout.id))
                const PopupMenuItem(
                  value: 'compare',
                  child: Text('Porovnat s jiným'),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Smazat', style: TextStyle(color: p.negative)),
              ),
            ],
          ),
      ],
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            Space.s,
            Space.page,
            Space.s,
          ),
          child: finished
              ? PrimaryButton('Hotovo', onPressed: () => Navigator.pop(context))
              : PrimaryButton(
                  'Zopakovat trénink',
                  icon: Icons.replay_rounded,
                  busy: _busy,
                  onPressed: () => _repeat(workout),
                ),
        ),
      ),
      children: [
        HeroCard(
          vivid: true,
          child: Builder(
            builder: (context) {
              final p = context.palette;
              final text = Theme.of(context).textTheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (finished) ...[
                    Text(workout.name, style: text.titleLarge),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    formatDateTime(workout.date),
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.s,
                    runSpacing: Space.xs,
                    children: [
                      Pill('$number. trénink', icon: Icons.flag_rounded),
                      Pill(
                        'Týden ${week.workouts}/${state.weekGoal}',
                        icon: week.workouts >= state.weekGoal
                            ? Icons.check_circle_rounded
                            : Icons.date_range_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.l),
                  Row(
                    children: [
                      if (duration != null)
                        Expanded(
                          child: StatTile(durationLabel(duration), 'Délka'),
                        ),
                      Expanded(child: StatTile('$sets', 'Série')),
                      Expanded(
                        child: StatTile('${formatVolume(kg)} kg', 'Objem'),
                      ),
                    ],
                  ),
                  if (workout.note.isNotEmpty) ...[
                    const SizedBox(height: Space.l),
                    Text(workout.note, style: text.bodyMedium),
                  ],
                ],
              );
            },
          ),
        ),
        if (records.isNotEmpty) ...[
          const SizedBox(height: Space.m),
          _RecordsPanel(state: state, records: records),
        ],
        if (state.badgesFrom(workout.id) case final badges
            when badges.isNotEmpty) ...[
          const SizedBox(height: Space.m),
          _BadgesPanel(state: state, badges: badges, fresh: finished),
        ],
        const SizedBox(height: Space.xl),
        SectionHeader('Cviky (${workout.exercises.length})'),
        for (final entry in workout.exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.m),
            child: _ComparisonPanel(
              state: state,
              workout: workout,
              entry: entry,
            ),
          ),
      ],
    );
  }
}

class _RecordsPanel extends StatelessWidget {
  final AppState state;
  final List<PersonalRecord> records;
  const _RecordsPanel({required this.state, required this.records});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(Icons.emoji_events_rounded, color: p.accent),
              const SizedBox(width: Space.m),
              Expanded(
                child: Text(
                  records.length == 1
                      ? 'Nový osobní rekord'
                      : 'Nové osobní rekordy: ${records.length}',
                  style: text.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s),
          for (final r in records)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                '${state.exercise(r.exerciseId).name} – ${r.kind.label}: '
                '${recordLabel(r.kind, r.value)}',
                style: text.bodyMedium?.copyWith(fontFeatures: tabular),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  final AppState state;
  final List<BadgeState> badges;

  /// Hned po tréninku „Nové odznaky“, z historie jen čím se odemkly.
  final bool fresh;
  const _BadgesPanel({
    required this.state,
    required this.badges,
    required this.fresh,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            !fresh
                ? 'Odznaky z tohoto tréninku'
                : badges.length == 1
                ? 'Nový odznak'
                : 'Nové odznaky (${badges.length})',
            style: text.titleMedium,
          ),
          const SizedBox(height: Space.m),
          for (final b in badges)
            InkWell(
              borderRadius: BorderRadius.circular(Radii.control),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AchievementsPage(state)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Row(
                  children: [
                    BadgeMedal(b, size: 44),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.badge.title, style: text.bodyLarge),
                          Text(b.badge.detail, style: text.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String trendLabel(Trend t) => switch (t) {
  Trend.better => 'Lepší než minule',
  Trend.same => 'Stejně jako minule',
  Trend.worse => 'Slabší než minule',
  Trend.added => 'Poprvé',
  Trend.missing => 'Bez pracovní série',
};

class TrendIcon extends StatelessWidget {
  final Trend trend;
  const TrendIcon(this.trend, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return switch (trend) {
      Trend.better => Icon(
        Icons.arrow_upward_rounded,
        size: 18,
        color: p.positive,
        semanticLabel: 'lepší',
      ),
      Trend.worse => Icon(
        Icons.arrow_downward_rounded,
        size: 18,
        color: p.negative,
        semanticLabel: 'slabší',
      ),
      Trend.same => Icon(
        Icons.drag_handle_rounded,
        size: 18,
        color: p.tertiaryLabel,
        semanticLabel: 'stejně',
      ),
      _ => const SizedBox(width: 18),
    };
  }
}

class _ComparisonPanel extends StatelessWidget {
  final AppState state;
  final Workout workout;
  final WorkoutExercise entry;
  const _ComparisonPanel({
    required this.state,
    required this.workout,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercise = state.exercise(entry.exerciseId);
    final type = exercise.type;
    final last = lastPerformance(
      state.workouts,
      entry.exerciseId,
      excludeWorkoutId: workout.id,
      before: workout.date,
    );
    final c = compareExercise(type, entry, last?.entry);
    final warmups = entry.sets.where((s) => s.done && s.warmup).length;
    final muted = text.bodySmall?.copyWith(color: p.secondaryLabel);
    final numbers = text.bodyMedium?.copyWith(fontFeatures: tabular);
    String delta(double v) {
      final sign = v > 0 ? '+' : (v < 0 ? '−' : '±');
      return '$sign${volumeLabel(type, v.abs())}';
    }

    String oneRm(SetEntry s) =>
        '${formatKg(e1rm(s.weight, s.reps).roundToDouble())} kg';

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(exercise.name, style: text.titleMedium)),
              TrendIcon(c.overall),
            ],
          ),
          Text(
            last == null
                ? trendLabel(c.overall)
                : '${trendLabel(c.overall)} (${formatDate(last.date)})',
            style: muted,
          ),
          const SizedBox(height: Space.m),
          for (var i = 0; i < c.sets.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('${i + 1}', style: muted)),
                  Expanded(
                    child: Text(
                      c.sets[i].today == null
                          ? '–'
                          : setLabel(type, c.sets[i].today!),
                      style: numbers,
                    ),
                  ),
                  TrendIcon(c.sets[i].trend),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(
                      c.sets[i].last == null
                          ? ''
                          : 'minule ${setLabel(type, c.sets[i].last!)}',
                      style: numbers?.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          if (warmups > 0)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text('Rozcvička: ${setsLabel(warmups)}', style: muted),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            child: Divider(height: 0.5, thickness: 0.5, color: p.separator),
          ),
          Text(
            last == null
                ? 'Objem ${volumeLabel(type, c.volumeToday)}'
                : 'Objem ${volumeLabel(type, c.volumeToday)} '
                      '(${delta(c.volumeDelta)})',
            style: numbers,
          ),
          if (type == ExerciseType.weighted && c.bestToday != null)
            Text(
              'Odhad 1RM ${oneRm(c.bestToday!)}'
              '${c.bestLast == null ? '' : ' (minule ${oneRm(c.bestLast!)})'}',
              style: numbers,
            ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: Space.s),
            Text(entry.note, style: muted),
          ],
        ],
      ),
    );
  }
}
