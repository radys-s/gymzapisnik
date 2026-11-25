import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/missions.dart';
import '../../coach/plan_quiz.dart';
import '../../coach/progression.dart';
import '../../coach/splits.dart';
import '../../core/i18n.dart';
import '../../domain/models.dart';
import '../../premium/entitlements.dart';
import '../../state/app_state.dart';
import '../coach/push_widgets.dart';
import '../coach/trainer_page.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../history/history_page.dart';
import '../premium/pro_gate.dart';
import '../onboarding/onboarding_page.dart' show PlanSetupPage;
import '../program/program_page.dart';
import '../program/program_widgets.dart';
import '../progress/week_report_page.dart';
import '../settings/settings_button.dart';
import '../widgets/labels.dart';
import '../workout/launcher.dart';
import '../settings/file_io.dart';
import 'dashboard.dart';
import 'food_block.dart';
import 'home_technical.dart';

/// Home shows today's action, food, this week's focus, and recent workouts.
/// Routines live in Training, while deeper metrics live in Progress.
class HomePage extends StatefulWidget {
  final AppState state;
  final DateTime Function() now;

  /// Uložení zálohy z připomínky (v testech náhrada).
  final FileIo files;
  const HomePage(
    this.state, {
    super.key,
    this.now = DateTime.now,
    this.files = const PickerFileIo(),
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WorkoutLauncher {
  @override
  AppState get state => widget.state;

  TrainerPage _trainer() => TrainerPage(
    state,
    now: widget.now,
    onStartToday: () =>
        runWorkout(() => state.startSplitDay(state.todaySplitDay)),
  );

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  bool _savingBackup = false;

  /// Záloha jedním klepnutím z připomínky na Domů.
  Future<void> _backup() async {
    if (_savingBackup) return;
    final messenger = ScaffoldMessenger.of(context);
    final d = widget.now();
    final name =
        'gymzapisnik-zaloha-${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}.json';
    setState(() => _savingBackup = true);
    String? message;
    try {
      final bool saved;
      try {
        saved = await widget.files.saveText(
          name,
          state.exportBackup(),
          'application/json',
        );
      } catch (_) {
        message = tr(
          'Zálohu se nepodařilo uložit. Zkus to znovu.',
          'Could not save backup. Try again.',
        );
        return;
      }
      if (!saved) return;
      message = tr('Uloženo: $name', 'Saved: $name');
      try {
        await state.markBackedUp();
      } catch (_) {
        message = tr(
          'Soubor $name je uložený, připomínka ale zůstane.',
          'File $name is saved, but the reminder will remain.',
        );
      }
    } finally {
      if (mounted) setState(() => _savingBackup = false);
      if (message != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state.on.resting,
    builder: (context, _) {
      final now = widget.now();
      final recent = state.workouts.take(3).toList();
      return LargeTitlePage(
        // The tab bar already says "Domů"; the title greets instead.
        title: greeting(now),
        titleLeading: const AppMark(size: 30),
        background: const HomeTechnicalBackground(),
        actions: [
          IconButton(
            tooltip: tr('Trenér', 'Coach'),
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => _push(_trainer()),
          ),
          SettingsButton(state),
        ],
        children: [
          HomeSystemLine(
            now: now,
            workouts: state.workouts.where((w) => w.finished).length,
          ),
          if (state.backupDue)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: Panel(
                onTap: _savingBackup ? null : _backup,
                child: Row(
                  children: [
                    IconTile(
                      Icons.save_alt_rounded,
                      color: context.palette.accent,
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('Ulož si zálohu', 'Save a backup'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            tr(
                              'Data jsou jen v tomto zařízení. Jedno klepnutí '
                                  'uloží všechno do souboru.',
                              'Data is only on this device. One tap saves '
                                  'everything to a file.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.palette.secondaryLabel,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.l),
            child: ListenableBuilder(
              listenable: state.on.history,
              builder: (context, _) => _WeekStrip(state: state, now: now),
            ),
          ),
          // Put the next clear action before food and progress details.
          Reveal(
            child: _TodayCard(
              state: state,
              now: now,
              busy: starting,
              dayIndex: state.todaySplitDay,
              onStart: runWorkout,
              onPickDay: state.pickSplitDay,
              onProgram: () => _push(ProgramPage(state)),
              onOther: otherWorkout,
              onQuiz: () => _push(PlanSetupPage(state)),
              onUsePlan: usePlan,
            ),
          ),
          const SizedBox(height: Space.m),
          LastWeekCard(state: state, now: now),
          Reveal(
            index: 1,
            child: HomeFoodBlock(state: state, now: now),
          ),
          const SizedBox(height: Space.m),
          Reveal(
            index: 2,
            child: WeekFocusCard(state: state, now: now),
          ),
          const SizedBox(height: Space.m),
          if (recent.isNotEmpty) ...[
            SectionHeader(
              tr('Historie', 'History'),
              action: tr('Vše', 'All'),
              onAction: () => _push(HistoryPage(state)),
            ),
            GroupedSection(
              children: [
                for (final w in recent)
                  WorkoutRow(state: state, workout: w, now: widget.now),
              ],
            ),
          ],
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
  Widget build(BuildContext context) => HomeConsoleSurface(
    // Rozepsaný trénink se mění při každé sérii: překreslí se jen karta.
    child: ListenableBuilder(
      listenable: state.on.active,
      builder: (context, _) => _content(context),
    ),
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
        const Padding(
          padding: EdgeInsets.only(bottom: Space.xs),
          child: Align(alignment: Alignment.centerLeft, child: LiveTag()),
        ),
        _Eyebrow(
          tr('Rozepsaný trénink', 'Workout in progress'),
          color: p.accent,
        ),
        Text(active.name, style: text.headlineSmall),
        const SizedBox(height: 2),
        _Elapsed(start: active.startedAt, sets: sets),
        const SizedBox(height: Space.l),
        PrimaryButton(
          tr('Pokračovat v tréninku', 'Continue workout'),
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(() async {}),
        ),
      ]);
    } else if (split != null) {
      final day = split.day(dayIndex);
      final plan = state.plan(day);
      final mission = state.mission(now);
      final nextUp = switch (mission.kind) {
        MissionKind.plannedRest ||
        MissionKind.doneToday ||
        MissionKind.weekDone => true,
        _ => false,
      };
      // Volno podle plánu: karta ukazuje příští tréninkový den, ne „dnes“.
      final next = nextUp
          ? _nextTrainingDay(state.profile.trainingDays, now)
          : null;
      final String when;
      if (!nextUp) {
        when = tr('Dnes', 'Today');
      } else if (next == null) {
        when = tr('Příště', 'Next');
      } else {
        when = tr(
          'Příště · ${weekdayLong[next - 1]}',
          'Next · ${weekdayLong[next - 1]}',
        );
      }
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
                    tr(
                      '$when · ${split.name} · den '
                          '${dayIndex % split.days.length + 1}/${split.days.length}',
                      '$when · ${split.name} · day '
                          '${dayIndex % split.days.length + 1}/${split.days.length}',
                    ),
                  ),
                  Text(
                    day.name,
                    style: text.headlineMedium?.copyWith(
                      fontFamily: condensedFont,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<int>(
              tooltip: tr('Jiný den nebo program', 'Another day or program'),
              icon: Icon(Icons.more_horiz, color: p.secondaryLabel),
              onSelected: (i) => i < 0 ? onProgram() : onPickDay(i),
              itemBuilder: (_) => [
                for (var i = 0; i < split.days.length; i++)
                  PopupMenuItem(value: i, child: Text(split.days[i].name)),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: -1,
                  child: Text(tr('Změnit program', 'Change program')),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Space.m),
        for (final (i, (pe, s)) in plan.take(5).indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 28,
                    child: Text(
                      (i + 1).toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: technicalFont,
                        fontSize: 10,
                        color: p.accent.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    state.exercise(pe.exerciseId).name,
                    style: text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Space.s),
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
          Text(
            tr('a další ${plan.length - 5}', 'and ${plan.length - 5} more'),
            style: text.bodySmall,
          ),
        const SizedBox(height: Space.s),
        // Rozsah tréninku a vedlejší volba na jednom řádku.
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 16, color: p.tertiaryLabel),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                scope,
                style: text.bodySmall?.copyWith(fontFeatures: tabular),
              ),
            ),
            const SizedBox(width: Space.s),
            TextButton(
              onPressed: busy ? null : onOther,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: Space.s),
                minimumSize: const Size(0, minTap),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: text.titleSmall,
              ),
              child: Text(tr('Jiný trénink', 'Another workout')),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        PrimaryButton(
          nextUp
              ? tr('Bonusový trénink', 'Bonus workout')
              : tr('Začít ${day.name}', 'Start ${day.name}'),
          icon: Icons.play_arrow_rounded,
          busy: busy,
          onPressed: () => onStart(() => state.startSplitDay(dayIndex)),
        ),
      ]);
    } else {
      // Bez programu: doporučení podle dotazníku (nebo výchozích odpovědí).
      final answers = state.planAnswers;
      final r = recommendPlan(answers ?? const PlanAnswers());
      final pick = findSplit(r.splitId);
      children.addAll([
        _Eyebrow(tr('Vyber si plán', 'Pick a plan'), color: p.accent),
        Text(pick?.name ?? tr('Program', 'Program'), style: text.headlineSmall),
        const SizedBox(height: 2),
        Text(
          answers == null
              ? tr(
                  'Program ti řekne, co který den cvičit, a hlídá postup '
                      'vah. Odpověz na čtyři otázky, nebo začni tímhle.',
                  'A program tells you what to train each day and tracks '
                      'weight progression. Answer four questions, or start with this one.',
                )
              : r.why,
          style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
        ),
        const SizedBox(height: Space.l),
        PrimaryButton(
          tr(
            'Použít ${pick?.name ?? 'program'}',
            'Use ${pick?.name ?? 'program'}',
          ),
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
                answers == null
                    ? tr('Vybrat podle sebe', 'Pick for myself')
                    : tr('Změnit odpovědi', 'Change answers'),
              ),
            ),
            TextButton(
              onPressed: busy ? null : () => onStart(state.startWorkout),
              child: Text(tr('Volný trénink', 'Free workout')),
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
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: technicalFont,
        color: color ?? context.palette.secondaryLabel,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: Space.m,
          vertical: Space.s + 2,
        ),
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
              color: urgent ? p.accent : p.secondaryLabel,
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
    tr(
      'Běží ${durationLabel(DateTime.now().difference(widget.start))} · '
          '${setsLabel(widget.sets)} hotovo',
      'Running ${durationLabel(DateTime.now().difference(widget.start))} · '
          '${setsLabel(widget.sets)} done',
    ),
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: context.palette.secondaryLabel,
      fontFeatures: tabular,
    ),
  );
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

/// Týden po dnech: odcvičené dny plné, plánované s tečkou, dnešek
/// orámovaný. Vpravo série týdnů v řadě.
class _WeekStrip extends StatelessWidget {
  final AppState state;
  final DateTime now;
  const _WeekStrip({required this.state, required this.now});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final trained = <int>{
      for (final w in state.workouts)
        if (w.finished && !w.date.isBefore(monday))
          if (DateTime(
                w.date.year,
                w.date.month,
                w.date.day,
              ).difference(monday).inDays
              case final d when d >= 0 && d < 7)
            d,
    };
    final planned = state.profile.trainingDays ?? const <int>[];
    final streak = state.streak(now);
    final letters = weekdayShort;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              tr(
                'TENTO TÝDEN · ${trained.length}/${state.weekGoal}',
                'THIS WEEK · ${trained.length}/${state.weekGoal}',
              ),
              style: text.labelSmall,
            ),
            const Spacer(),
            if (streak.weeks > 0)
              Semantics(
                label: tr(
                  'Série ${streak.weeks} týdnů v řadě',
                  '${streak.weeks}-week streak',
                ),
                excludeSemantics: true,
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: p.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      tr(
                        '${streak.weeks} ${streak.weeks == 1
                            ? 'týden'
                            : streak.weeks < 5
                            ? 'týdny'
                            : 'týdnů'}',
                        '${streak.weeks} ${streak.weeks == 1 ? 'week' : 'weeks'}',
                      ),
                      style: text.labelMedium?.copyWith(
                        color: p.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: _DayDot(
                  letter: letters[i],
                  day: monday.add(Duration(days: i)).day,
                  done: trained.contains(i),
                  today: i == today.weekday - 1,
                  planned: planned.contains(i + 1),
                  past: i < today.weekday - 1,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayDot extends StatelessWidget {
  final String letter;
  final int day;
  final bool done;
  final bool today;
  final bool planned;
  final bool past;
  const _DayDot({
    required this.letter,
    required this.day,
    required this.done,
    required this.today,
    required this.planned,
    required this.past,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final Color bg = done ? p.positive : p.grouped;
    final Color fg = done
        ? AppPalette.ink
        : past
        ? p.tertiaryLabel
        : p.label;
    return Semantics(
      label:
          '$letter $day.${done
              ? tr(', odcvičeno', ', done')
              : planned
              ? tr(', plánovaný trénink', ', planned workout')
              : ''}'
          '${today ? tr(', dnes', ', today') : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            letter,
            style: text.labelSmall?.copyWith(
              color: today ? p.accent : p.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
              border: today && !done
                  ? Border.all(color: p.accent, width: 2)
                  : null,
            ),
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: AppPalette.ink,
                  )
                : Text(
                    '$day',
                    style: text.titleSmall?.copyWith(
                      color: fg,
                      fontFeatures: tabular,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: planned && !done ? p.tertiaryLabel : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
