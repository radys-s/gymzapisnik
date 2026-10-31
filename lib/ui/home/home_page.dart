import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/missions.dart';
import '../../coach/plan_quiz.dart';
import '../../coach/progression.dart';
import '../../coach/splits.dart';
import '../../core/format.dart';
import '../../domain/history.dart';
import '../../domain/models.dart';
import '../../premium/entitlements.dart';
import '../../state/app_state.dart';
import '../coach/trainer_page.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../exercises/exercise_detail_page.dart';
import '../history/history_page.dart';
import '../premium/pro_gate.dart';
import '../program/plan_quiz.dart';
import '../program/program_page.dart';
import '../program/program_widgets.dart';
import '../settings/settings_button.dart';
import '../summary/summary_page.dart';
import '../widgets/labels.dart';
import '../workout/builder_page.dart';
import '../workout/workout_page.dart';
import 'dashboard.dart';
import 'recovery_card.dart';

/// Záložka Trénink: pozdrav, jedna hlavní akce, týden, regenerace
/// a poslední tréninky. Statistiky, cviky a váha jsou v záložce Pokrok.
class HomePage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;
  const HomePage(this.state, {super.key, this.now = DateTime.now});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Pojistka proti dvojímu klepnutí na start (dvě obrazovky tréninku).
  bool _starting = false;

  AppState get state => widget.state;

  Future<void> _usePlan(PlanAnswers? answers) async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await state.applyPlan(answers);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

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

  TrainerPage _trainer() => TrainerPage(
    state,
    now: widget.now,
    onStartToday: () => _run(() => state.startSplitDay(state.todaySplitDay)),
  );

  /// Sestavení tréninku z partií; hotový den rovnou začne.
  bool _opening = false;

  Future<void> _build([
    List<String> focuses = const [],
    List<String> avoid = const [],
  ]) async {
    if (_opening || _starting) return;
    _opening = true;
    final SplitDay? day;
    try {
      day = await Navigator.push<SplitDay>(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutBuilderPage(
            state,
            initialFocuses: focuses,
            avoidFocuses: avoid,
          ),
        ),
      );
    } finally {
      _opening = false;
    }
    final picked = day;
    if (picked == null || !mounted) return;
    await _run(() => state.startPlanned(picked));
  }

  /// Jiný trénink než dnešní den plánu: volný, nebo sestavený z partií.
  Future<void> _other() async {
    final pick = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: const Text('Volný trénink'),
                subtitle: const Text('Cviky přidáváš průběžně'),
                onTap: () => Navigator.pop(sheet, 0),
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Sestavit podle partií'),
                subtitle: const Text('Vybereš svaly, cviky navrhne aplikace'),
                onTap: () => Navigator.pop(sheet, 1),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (pick == 0) await _run(state.startWorkout);
    if (pick == 1) await _build();
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
        title: 'Trénink',
        actions: [
          IconButton(
            tooltip: 'Trenér',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => _push(_trainer()),
          ),
          SettingsButton(state),
        ],
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Text(
              greeting(now),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: context.palette.secondaryLabel),
            ),
          ),
          _TodayCard(
            state: state,
            now: now,
            busy: _starting,
            dayIndex: state.todaySplitDay,
            onStart: _run,
            onPickDay: state.pickSplitDay,
            onProgram: () => _push(ProgramPage(state)),
            onOther: _other,
            onQuiz: () => _push(PlanQuizPage(state)),
            onUsePlan: _usePlan,
          ),
          const SizedBox(height: Space.m),
          GroupedSection(
            children: [
              GroupedRow(
                icon: Icons.forum_rounded,
                iconColor: context.palette.accent,
                title: 'Zeptej se trenéra',
                subtitle: 'Co dnes, proč stagnuju, čím nahradit cvik',
                onTap: () => _push(_trainer()),
              ),
            ],
          ),
          const SectionHeader('Tento týden'),
          _WeekPanel(state: state, now: now),
          if (context.palette.telemetry) _RecordsBoard(state),
          if (state.workouts.isNotEmpty && state.active == null) ...[
            const SectionHeader('Regenerace svalů'),
            RecoveryPanel(state: state, now: now, onBuild: _build),
          ],
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
        ],
      );
    },
  );
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
  final VoidCallback onOther;
  final VoidCallback onQuiz;
  final ValueChanged<PlanAnswers?> onUsePlan;

  const _TodayCard({
    required this.state,
    required this.now,
    required this.busy,
    required this.dayIndex,
    required this.onStart,
    required this.onPickDay,
    required this.onProgram,
    required this.onOther,
    required this.onQuiz,
    required this.onUsePlan,
  });

  @override
  Widget build(BuildContext context) => HeroCard(
    vivid: true,
    // Závod: číslo jezdce = pořadí dnešního tréninku.
    watermark: '${state.workouts.where((w) => w.finished).length + 1}',
    child: Builder(builder: _content),
  );

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
        if (p.telemetry)
          const Padding(
            padding: EdgeInsets.only(bottom: Space.xs),
            child: Align(alignment: Alignment.centerLeft, child: LiveTag()),
          ),
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
      // Volno podle plánu: karta ukazuje příští tréninkový den, ne „dnes“.
      final next = state.mission(now).kind == MissionKind.plannedRest
          ? _nextTrainingDay(state.profile.trainingDays, now)
          : null;
      final scope =
          '${exercisesLabel(plan.length)} · '
          '~${workoutMinutes(plan.fold(0, (n, e) => n + e.$1.sets))} min';
      children.addAll([
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Eyebrow(
                    '${next == null ? 'Dnes' : 'Příště · ${weekdayLong[next - 1]}'}'
                    ' · ${split.name} · den '
                    '${dayIndex % split.days.length + 1}/${split.days.length}',
                  ),
                  Text(
                    day.name,
                    style: p.telemetry ? text.displaySmall : text.headlineSmall,
                  ),
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
        // Jedno světlo na cvik; rozsah tréninku ukáže každý vzhled.
        if (p.telemetry)
          StartLights(count: plan.length, caption: scope)
        else
          Text(
            scope,
            style: text.labelMedium?.copyWith(color: p.secondaryLabel),
          ),
        const SizedBox(height: Space.m),
        PrimaryButton(
          next == null ? 'Začít ${day.name}' : 'Začít i dnes',
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(() => state.startSplitDay(dayIndex)),
        ),
        const SizedBox(height: Space.xs),
        Center(
          child: TextButton(
            onPressed: busy ? null : onOther,
            child: const Text('Jiný trénink'),
          ),
        ),
      ]);
    } else {
      // Bez programu: doporučení podle dotazníku (nebo výchozích odpovědí).
      final answers = state.planAnswers;
      final r = recommendPlan(answers ?? const PlanAnswers());
      final pick = findSplit(r.splitId);
      children.addAll([
        _Eyebrow('Vyber si plán', color: p.accent),
        Text(pick?.name ?? 'Program', style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(
          answers == null
              ? 'Program ti řekne, co který den cvičit, a hlídá postup '
                    'vah. Odpověz na čtyři otázky, nebo začni tímhle.'
              : r.why,
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        const SizedBox(height: Space.l),
        PrimaryButton(
          'Použít ${pick?.name ?? 'program'}',
          icon: Icons.check_rounded,
          busy: busy,
          onPressed: () => onUsePlan(answers),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: busy ? null : onQuiz,
              child: Text(
                answers == null ? 'Vybrat podle sebe' : 'Změnit odpovědi',
              ),
            ),
            TextButton(
              onPressed: busy ? null : () => onStart(state.startWorkout),
              child: const Text('Volný trénink'),
            ),
          ],
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
          child: _MissionLine(
            state.mission(now),
            daysSince: _daysSince(state, now),
          ),
        ),
      ],
    );
  }

  static int? _daysSince(AppState state, DateTime now) {
    final last = state.workouts.where((w) => w.finished).firstOrNull;
    if (last == null) return null;
    final day = DateTime(now.year, now.month, now.day);
    final then = DateTime(last.date.year, last.date.month, last.date.day);
    return day.difference(then).inDays;
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
    child: context.palette.tensor
        ? Text(
            text,
            style: TextStyle(
              fontFamily: condensedFont,
              color: color ?? context.palette.secondaryLabel,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          )
        : Text(
            text,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
  );
}

/// Dnešní mise jako jeden řádek pod hlavní akcí.
class _MissionLine extends StatelessWidget {
  final Mission mission;
  final int? daysSince;
  const _MissionLine(this.mission, {this.daysSince});

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
          borderRadius: BorderRadius.circular(context.palette.controlRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              MissionCopy.icon(mission.kind),
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
                  Text(MissionCopy.title(mission), style: text.titleSmall),
                  Text(
                    MissionCopy.subtitle(mission, daysSince: daysSince),
                    style: text.bodySmall,
                  ),
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

/// Závod: nedávné rekordy jako pořadí jezdců (P1–P3) s barvou týmu.
class _RecordsBoard extends StatelessWidget {
  final AppState state;
  const _RecordsBoard(this.state);

  static const _teams = [
    AppPalette.raceRed,
    Color(0xFFFF8000),
    Color(0xFF00D2BE),
  ];

  @override
  Widget build(BuildContext context) {
    final records = recentRecords(state.workouts, state.typeOf);
    if (records.isEmpty) return const SizedBox.shrink();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Pořadí rekordů'),
        Panel(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: Space.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < records.length; i++) ...[
                if (i > 0) Divider(color: p.separator),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseDetailPage(state, records[i].exerciseId),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text('P${i + 1}', style: text.titleLarge),
                        ),
                        Container(
                          width: 4,
                          height: 26,
                          color: _teams[i % _teams.length],
                        ),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.exercise(records[i].exerciseId).name,
                                style: text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${records[i].kind.label} · '
                                '${formatDate(records[i].date)}',
                                style: text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          recordLabel(records[i].kind, records[i].value),
                          style: text.titleSmall?.copyWith(
                            color: p.positive,
                            fontFeatures: tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
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

/// Nejbližší tréninkový den po dnešku (1 = pondělí); `null` bez dnů.
int? _nextTrainingDay(List<int>? days, DateTime now) {
  if (days == null || days.isEmpty) return null;
  for (var i = 1; i <= 7; i++) {
    final d = (now.weekday - 1 + i) % 7 + 1;
    if (days.contains(d)) return d;
  }
  return null;
}
