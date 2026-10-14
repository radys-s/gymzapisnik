import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/missions.dart';
import '../../coach/progression.dart';
import '../../coach/splits.dart';
import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../premium/entitlements.dart';
import '../../state/app_state.dart';
import '../bodyweight/bodyweight_page.dart';
import '../coach/growth_page.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../exercises/exercises_page.dart';
import '../history/history_page.dart';
import '../premium/pro_gate.dart';
import '../program/program_page.dart';
import '../settings/settings_button.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';
import '../workout/builder_page.dart';
import '../workout/workout_page.dart';
import 'dashboard.dart';

/// Záložka Cvičení: jedna hlavní akce, týden, poslední tréninky
/// a cesty k programu, cvikům a váze. Pevné složení, nic nepřibývá.
class HomePage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;
  const HomePage(this.state, {super.key, this.now = DateTime.now});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Ručně zvolený jiný den splitu (jinak den na řadě).
  int? dayOverride;

  /// Program, ke kterému ruční volba dne patří (po změně programu neplatí).
  String? overrideSplit;

  /// Pojistka proti dvojímu klepnutí na start (dvě obrazovky tréninku).
  bool _starting = false;

  AppState get state => widget.state;

  Future<void> _run(Future<void> Function() start) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await start();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          e is StateError
              ? e.message
              : 'Trénink se nepodařilo začít. Zkus to znovu.',
        );
      }
      if (mounted) setState(() => _starting = false);
      return;
    }
    if (!mounted) return;
    setState(() => dayOverride = null);
    final nav = Navigator.of(context, rootNavigator: true);
    final finished = nav.push<Workout>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WorkoutPage(state),
      ),
    );
    // Tlačítko se odemkne, jakmile je obrazovka tréninku nahoře.
    setState(() => _starting = false);
    final workout = await finished;
    if (workout != null && mounted) {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => SummaryPage(state, workout, justFinished: true),
        ),
      );
    }
  }

  /// Sestavení tréninku z partií; hotový den rovnou začne.
  Future<void> _build() async {
    final day = await Navigator.push<SplitDay>(
      context,
      MaterialPageRoute(builder: (_) => WorkoutBuilderPage(state)),
    );
    if (day == null || !mounted) return;
    await _run(() => state.startPlanned(day));
  }

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final now = widget.now();
      final recent = state.workouts.take(3).toList();
      return LargeTitlePage(
        title: 'Cvičení',
        actions: [SettingsButton(state)],
        children: [
          _TodayCard(
            state: state,
            now: now,
            busy: _starting,
            dayIndex: overrideSplit == state.split?.id
                ? dayOverride ?? state.nextSplitDay
                : state.nextSplitDay,
            onStart: _run,
            onPickDay: (i) => setState(() {
              dayOverride = i;
              overrideSplit = state.split?.id;
            }),
            onProgram: () => _push(ProgramPage(state)),
            onBuild: _build,
          ),
          const SectionHeader('Tento týden'),
          _WeekPanel(state: state, now: now),
          if (recent.isNotEmpty) ...[
            SectionHeader(
              'Historie',
              action: 'Vše',
              onAction: () => _push(HistoryPage(state)),
            ),
            GroupedSection(
              children: [
                for (final w in recent)
                  WorkoutRow(state: state, workout: w, now: widget.now),
              ],
            ),
          ] else
            const SizedBox(height: Space.xxl),
          GroupedSection(
            dividerIndent: 58,
            children: [
              GroupedRow(
                icon: Icons.calendar_view_week_rounded,
                iconColor: const Color(0xFF5E5CE6),
                title: 'Program',
                value: state.split?.name ?? 'Volně',
                onTap: () => _push(ProgramPage(state)),
              ),
              GroupedRow(
                icon: Icons.fitness_center_rounded,
                iconColor: const Color(0xFFFF9F0A),
                title: 'Cviky a rekordy',
                subtitle: _recordHint(),
                onTap: () => _push(ExercisesPage(state)),
              ),
              GroupedRow(
                icon: Icons.monitor_weight_outlined,
                iconColor: const Color(0xFF32ADE6),
                title: 'Tělesná váha',
                value: state.bodyweights.isEmpty
                    ? null
                    : '${formatKg(state.bodyweights.first.kg)} kg',
                onTap: () => _push(BodyweightPage(state)),
              ),
              GroupedRow(
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFF34C759),
                title: 'Rady pro růst svalů',
                subtitle: 'Objem, technika, jídlo, spánek',
                onTap: () => _push(GrowthPage(state, now: widget.now)),
              ),
            ],
          ),
        ],
      );
    },
  );

  String? _recordHint() {
    final records = recentRecords(state.workouts, state.typeOf, limit: 1);
    if (records.isEmpty) return null;
    final r = records.first;
    return 'Rekord: ${state.exercise(r.exerciseId).name} '
        '${recordLabel(r.kind, r.value)}';
  }
}

/// Hlavní karta: co dnes cvičit a jedno velké tlačítko.
class _TodayCard extends StatelessWidget {
  final AppState state;
  final DateTime now;
  final bool busy;
  final int dayIndex;
  final Future<void> Function(Future<void> Function() start) onStart;
  final ValueChanged<int> onPickDay;
  final VoidCallback onProgram;
  final VoidCallback onBuild;

  const _TodayCard({
    required this.state,
    required this.now,
    required this.busy,
    required this.dayIndex,
    required this.onStart,
    required this.onPickDay,
    required this.onProgram,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) =>
      HeroCard(vivid: true, child: Builder(builder: _content));

  Widget _content(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final active = state.active;
    final split = state.split;
    final children = <Widget>[];

    if (active != null) {
      final sets = active.exercises.fold(
        0,
        (n, e) => n + e.sets.where((s) => s.done).length,
      );
      children.addAll([
        _Eyebrow('Rozepsaný trénink', color: p.accent),
        Text(active.name, style: text.headlineSmall),
        const SizedBox(height: 2),
        _Elapsed(start: active.startedAt, sets: sets),
        const SizedBox(height: Space.l),
        PrimaryButton(
          'Pokračovat v tréninku',
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(() async {}),
        ),
      ]);
    } else if (split != null) {
      final day = split.day(dayIndex);
      final plan = state.plan(day);
      children.addAll([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow(
                    'Dnes · ${split.name} · den '
                    '${dayIndex % split.days.length + 1}/${split.days.length}',
                  ),
                  Text(day.name, style: text.headlineSmall),
                ],
              ),
            ),
            PopupMenuButton<int>(
              tooltip: 'Jiný den nebo program',
              icon: Icon(Icons.more_horiz, color: p.accent),
              onSelected: (i) => i < 0 ? onProgram() : onPickDay(i),
              itemBuilder: (_) => [
                for (var i = 0; i < split.days.length; i++)
                  PopupMenuItem(value: i, child: Text(split.days[i].name)),
                const PopupMenuDivider(),
                const PopupMenuItem(value: -1, child: Text('Změnit program')),
              ],
            ),
          ],
        ),
        const SizedBox(height: Space.m),
        for (final (pe, s) in plan.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.exercise(pe.exerciseId).name,
                    style: text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _target(state.typeOf(pe.exerciseId), pe, s),
                  style: text.bodyMedium?.copyWith(
                    fontFeatures: tabular,
                    color: s.kind == SuggestionKind.increase
                        ? p.accent
                        : p.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        if (plan.length > 5)
          Text('a další ${plan.length - 5}', style: text.bodySmall),
        const SizedBox(height: Space.m),
        PrimaryButton(
          'Začít ${day.name}',
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(() => state.startSplitDay(dayIndex)),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: busy ? null : () => onStart(state.startWorkout),
              child: const Text('Volný trénink'),
            ),
            TextButton(
              onPressed: busy ? null : onBuild,
              child: const Text('Sestavit trénink'),
            ),
          ],
        ),
      ]);
    } else {
      children.addAll([
        const _Eyebrow('Dnes'),
        Text('Začni trénink', style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(
          'Přidej cviky a zapisuj série. Minulé váhy a opakování '
          'se předvyplní při dalším tréninku.',
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        const SizedBox(height: Space.l),
        PrimaryButton(
          'Začít trénink',
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(state.startWorkout),
        ),
        const SizedBox(height: Space.xs),
        Center(
          child: TextButton(
            onPressed: busy ? null : onBuild,
            child: const Text('Sestavit trénink z partií'),
          ),
        ),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...children,
        ProGate(
          state,
          ProFeature.mission,
          child: _MissionLine(state.mission(now)),
        ),
      ],
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

/// Malý nadpis nad názvem („Dnes · PPL · den 1/3").
class _Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const _Eyebrow(this.text, {this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    ),
  );
}

/// Dnešní mise jako jeden řádek pod hlavní akcí.
class _MissionLine extends StatelessWidget {
  final Mission mission;
  const _MissionLine(this.mission);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final urgent = mission.kind == MissionKind.catchUp;
    return Padding(
      padding: const EdgeInsets.only(top: Space.m),
      child: Container(
        padding: const EdgeInsets.all(Space.m),
        decoration: BoxDecoration(
          color: p.fill,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              MissionCard.icon(mission.kind),
              size: 20,
              // Na světlé barevné kartě by oranžová splynula.
              color: urgent && p.surface != HeroSurface.bright
                  ? const Color(0xFFFF9F0A)
                  : p.accent,
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(MissionCard.title(mission), style: text.titleSmall),
                  Text(MissionCard.subtitle(mission), style: text.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uplynulý čas rozepsaného tréninku, obnovuje se každých 15 s.
class _Elapsed extends StatefulWidget {
  final DateTime start;
  final int sets;
  const _Elapsed({required this.start, required this.sets});

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
    'Běží ${durationLabel(DateTime.now().difference(widget.start))} · '
    '${setsLabel(widget.sets)} hotovo',
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: context.palette.secondaryLabel,
      fontFeatures: tabular,
    ),
  );
}

/// Týden: kruh tréninků vůči cíli, série, objem a streak.
class _WeekPanel extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const _WeekPanel({required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final week = weekSummary(state.workouts, now, state.typeOf);
    final goal = state.weekGoal;
    final streak = state.has(ProFeature.mission) ? state.streak(now) : null;
    final lines = state.has(ProFeature.recap) && state.workouts.isNotEmpty
        ? recapLines(
            week,
            previousWeekSummary(state.workouts, now, state.typeOf),
            weekRecordCount(state.workouts, now, state.typeOf),
          )
        : const <String>[];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                container: true,
                label: 'Tento týden ${week.workouts} z $goal tréninků',
                excludeSemantics: true,
                child: ProgressRing(
                  value: goal == 0 ? 0 : week.workouts / goal,
                  size: 76,
                  stroke: 9,
                  child: Text(
                    '${week.workouts}/$goal',
                    style: text.titleMedium?.copyWith(fontFeatures: tabular),
                  ),
                ),
              ),
              const SizedBox(width: Space.xl),
              Expanded(
                child: Wrap(
                  spacing: Space.xl,
                  runSpacing: Space.m,
                  children: [
                    StatTile('${week.sets}', setsNoun(week.sets)),
                    StatTile('${formatVolume(week.volumeKg)} kg', 'objem'),
                    if (streak != null && streak.weeks > 0)
                      Tooltip(
                        message: streak.jokerReady
                            ? 'Žolík je připravený: zachrání jeden zmeškaný týden.'
                            : 'Žolík se po použití obnoví za pár týdnů.',
                        child: StatTile(weeksLabel(streak.weeks), 'v řadě'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (streak?.jokerJustUsed ?? false) ...[
            const SizedBox(height: Space.m),
            Text(
              'Žolík ti minulý týden zachránil streak.',
              style: text.bodySmall?.copyWith(color: context.palette.accent),
            ),
          ],
          if (lines.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            for (final line in lines) Text(line, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
