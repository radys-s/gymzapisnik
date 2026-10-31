import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../core/format.dart';
import '../../coach/reminders.dart';
import '../../domain/bodyweight.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../program/plan_quiz.dart';
import '../program/program_widgets.dart';
import '../welcome/whats_new.dart';
import '../widgets/labels.dart';
import 'consent_page.dart';

/// První spuštění: co aplikace umí, dotazník, hotový plán, připomínka
/// a souhlas. Krok se ukládá, takže po zavření aplikace úvod pokračuje,
/// kde skončil. Když uvítání už proběhlo (nové podmínky), ukáže jen
/// souhlas.
class OnboardingPage extends StatefulWidget {
  final AppState state;
  const OnboardingPage(this.state, {super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  AppState get state => widget.state;

  /// Uvítání jen pro nové uživatele; stávající (nové podmínky) vidí
  /// rovnou souhlas.
  late final bool welcome =
      !state.profile.welcomeSeen && state.profile.consentAt == null;

  /// Připomínky jdou jen tam, kde umí aplikace poslat oznámení.
  late final bool reminders = state.notifier.supported;

  static const _quizStep = 1;
  static const _planStep = 2;
  int get _consentStep => reminders ? 4 : 3;

  late final int _first = state.onboardingStep.clamp(0, _consentStep);
  late final _pages = PageController(initialPage: _first);
  late int page = _first;

  late PlanAnswers plan = state.planAnswers ?? const PlanAnswers();
  late Set<int> days = {
    if (state.profile.trainingDays case final d? when d.length == plan.days)
      ...d,
  };
  late final _kg = TextEditingController(
    text: switch (state.bodyweights.firstOrNull?.kg) {
      final kg? => formatKg(kg),
      null => '',
    },
  );
  bool busy = false;

  /// Dotazník přeskočen: zpět z dalšího kroku vede na dotazník, ne na
  /// odhalení plánu, který se neuložil.
  bool skipped = false;

  void _go(int to) {
    _pages.animateToPage(
      to,
      duration: Motion.of(context, Motion.base),
      curve: Motion.curve,
    );
    // Uložení kroku nesmí zastavit úvod.
    unawaited(state.setOnboardingStep(to).catchError((_) {}));
  }

  /// Dotazník: plán, dny a váha se uloží najednou, pak přijde odhalení.
  Future<void> _applyQuiz() async {
    final raw = _kg.text.trim().replaceAll(',', '.');
    final kg = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && (kg == null || !validBodyWeight(kg))) {
      showToast(context, 'Zadej váhu v kg, třeba 72,5. Nebo ji nech prázdnou.');
      return;
    }
    setState(() => busy = true);
    try {
      final r = await state.applyPlan(plan);
      if (days.length == plan.days) {
        await state.setFrequency(days: days.toList());
      } else if (state.profile.trainingDays != null) {
        // Dny odebrané po návratu zpět se nesmí dál držet v profilu.
        await state.setFrequency(perWeek: r.perWeek);
      }
      // Váha se ukládá na desetinu, porovnává se taky tak.
      final rounded = kg == null ? null : double.parse(kg.toStringAsFixed(1));
      if (rounded != null && rounded != state.bodyweights.firstOrNull?.kg) {
        await state.addBodyweight(rounded);
      }
      skipped = false;
      if (mounted) _go(_planStep);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Klepnutí na den: počet vybraných dnů je zároveň počet tréninků.
  void _toggleDay(int d) {
    final next = {...days};
    if (!next.remove(d)) {
      if (next.length >= 6) {
        showToast(context, 'Aspoň jeden den v týdnu nech na odpočinek.');
        return;
      }
      next.add(d);
    }
    setState(() {
      days = next;
      if (next.length >= 2) plan = plan.copyWith(days: next.length);
    });
  }

  /// Krok, kam vede zpět z kroku [from].
  int _back(int from) =>
      from == _planStep + 1 && skipped ? _quizStep : from - 1;

  void _changePlan(PlanAnswers a) => setState(() {
    // Jiný počet tréninků: vybrané dny už nesedí.
    if (a.days != plan.days) days = {};
    plan = a;
  });

  Future<void> _enableReminder(int minutes) async {
    setState(() => busy = true);
    try {
      final ok = await state.setReminder(minutes);
      if (!ok && mounted) {
        showToast(
          context,
          'Bez povolení oznámení připomínky nepřijdou. Zapneš je v Nastavení.',
        );
      }
    } catch (_) {
      if (mounted) showToast(context, 'Připomínku se nepodařilo nastavit.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
        _go(_consentStep);
      }
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    _kg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consent = ConsentPage(
      state,
      welcomeVersion: welcome ? whatsNewRelease : null,
    );
    if (!welcome) return consent;
    final dots = _consentStep;
    return PopScope(
      canPop: page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && page > 0 && !busy) _go(_back(page));
      },
      child: PageView(
        controller: _pages,
        // Kroky na sobě závisí (plán až po dotazníku): jen tlačítky.
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => page = i),
        children: [
          _Step(
            index: 0,
            count: dots,
            action: 'Sestavit můj plán',
            onNext: () => _go(_quizStep),
            child: const _Value(),
          ),
          _Step(
            index: _quizStep,
            count: dots,
            title: 'Tvůj plán',
            lead:
                'Pár otázek a sestavím ti program na míru. Změníš ho '
                'kdykoli v Programu.',
            action: 'Ukázat plán',
            busy: busy,
            onBack: () => _go(0),
            onSkip: () {
              skipped = true;
              _go(_planStep + 1);
            },
            onNext: _applyQuiz,
            child: _Quiz(
              answers: plan,
              onChanged: _changePlan,
              days: days,
              onDay: _toggleDay,
              kg: _kg,
            ),
          ),
          _Step(
            index: _planStep,
            count: dots,
            action: 'Pokračovat',
            onBack: () => _go(_quizStep),
            onNext: () => _go(_planStep + 1),
            child: _PlanReveal(state, answers: plan),
          ),
          if (reminders)
            _ReminderStep(
              index: 3,
              count: dots,
              busy: busy,
              onBack: () => _go(_back(3)),
              onEnable: _enableReminder,
              onSkip: () => _go(_consentStep),
            ),
          consent,
        ],
      ),
    );
  }
}

/// Kostra kroku: horní lišta (zpět, přeskočit), nadpis, obsah, tečky
/// postupu a hlavní tlačítko.
class _Step extends StatelessWidget {
  final int index;
  final int count;
  final String? title;
  final String? lead;
  final Widget child;
  final String action;
  final bool busy;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final Widget? secondary;
  const _Step({
    required this.index,
    required this.count,
    required this.child,
    required this.action,
    required this.onNext,
    this.title,
    this.lead,
    this.busy = false,
    this.onBack,
    this.onSkip,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.page,
            0,
            Space.page,
            Space.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: minTap,
                child: Row(
                  children: [
                    if (onBack != null)
                      Semantics(
                        button: true,
                        label: 'Zpět',
                        excludeSemantics: true,
                        child: IconButton(
                          onPressed: busy ? null : onBack,
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                    const Spacer(),
                    if (onSkip != null)
                      TextButton(
                        onPressed: busy ? null : onSkip,
                        child: const Text('Přeskočit'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: Space.l),
                  children: [
                    if (title case final t?)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              container: true,
                              header: true,
                              child: Text(t, style: text.headlineLarge),
                            ),
                            if (lead case final l?) ...[
                              const SizedBox(height: Space.m),
                              Text(
                                l,
                                style: text.bodyLarge?.copyWith(
                                  color: p.secondaryLabel,
                                ),
                              ),
                            ],
                            const SizedBox(height: Space.l),
                          ],
                        ),
                      ),
                    child,
                  ],
                ),
              ),
              // Odstup od posouvaného obsahu, ať tečky nesedí na seznamu.
              const SizedBox(height: Space.l),
              _Dots(index: index, count: count),
              const SizedBox(height: Space.xl),
              PrimaryButton(action, busy: busy, onPressed: onNext),
              ?secondary,
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int index;
  final int count;
  const _Dots({required this.index, required this.count});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      container: true,
      label: 'Krok ${index + 1} z $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: Motion.of(context, Motion.quick),
              curve: Motion.curve,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? p.accent : p.tertiaryLabel,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}

/// Jediný úvodní slide: co aplikace za tebe udělá.
class _Value extends StatelessWidget {
  const _Value();

  static const _points = [
    (Icons.today_rounded, 'Každý den víš, co cvičit', 'Plán podle tvého času'),
    (
      Icons.trending_up_rounded,
      'Váhy se předvyplní samy',
      'Potvrdíš sérii a vidíš, jak sílíš',
    ),
    (
      Icons.lock_outline_rounded,
      'Bez účtu a bez reklam',
      'Tréninky zůstávají v telefonu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const SizedBox(height: Space.xl),
        const Reveal(child: AppMark(size: 112)),
        const SizedBox(height: Space.xxl),
        Reveal(
          index: 1,
          child: Semantics(
            container: true,
            header: true,
            child: Text(
              'Gym zápisník',
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: Space.s),
        Reveal(
          index: 2,
          child: Text(
            'Trenér do kapsy: řekne, co dnes, a hlídá, jak rosteš.',
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: p.secondaryLabel),
          ),
        ),
        const SizedBox(height: Space.xxl),
        for (final (i, (icon, title, body)) in _points.indexed)
          Reveal(
            index: 3 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.l),
              child: Row(
                children: [
                  IconTile(icon, color: p.accent),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleMedium),
                        Text(
                          body,
                          style: text.bodyMedium?.copyWith(
                            color: p.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Dotazník: cíl, počet a dny tréninků, zkušenost, čas a váha.
class _Quiz extends StatelessWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;
  final Set<int> days;
  final ValueChanged<int> onDay;
  final TextEditingController kg;
  const _Quiz({
    required this.answers,
    required this.onChanged,
    required this.days,
    required this.onDay,
    required this.kg,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final hint = days.isEmpty
        ? 'Nepovinné. Bez výběru plán rozloží tréninky do týdne.'
        : days.length == answers.days
        ? 'Plán a připomínky v tyto dny.'
        : 'Vyber aspoň 2 dny, nebo nech plán rozložit do týdne.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlanQuizForm(answers: answers, onChanged: onChanged),
        GroupedSection(
          header: 'Ve které dny',
          children: [
            Padding(
              padding: const EdgeInsets.all(Space.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var d = 1; d <= 7; d++)
                        DayToggle(
                          label: weekdayShort[d - 1],
                          spoken: weekdayLong[d - 1],
                          selected: days.contains(d),
                          onTap: () => onDay(d),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.s),
                  Text(
                    hint,
                    style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
        GroupedSection(
          header: 'Tělesná váha',
          footer:
              'Nepovinné. Podle ní doporučím ve Stravě, kolik bílkovin '
              'denně sníst.',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.m),
              child: Semantics(
                // Nápověda po psaní zmizí, čtečka potřebuje stálý název.
                label: 'Tělesná váha v kg',
                child: TextField(
                  controller: kg,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'např. 72,5',
                    suffixText: 'kg',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Hotový plán: program, týden a první trénink. Čte uložený stav, takže
/// ukazuje přesně to, co uvidí domov.
class _PlanReveal extends StatelessWidget {
  final AppState state;
  final PlanAnswers answers;
  const _PlanReveal(this.state, {required this.answers});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final p = context.palette;
      final text = Theme.of(context).textTheme;
      final r = recommendPlan(answers);
      final split = state.split;
      final week =
          state.profile.trainingDays ??
          reminderDays[state.weekGoal.clamp(1, 7)]!;
      final first = split?.days.firstOrNull;
      final blocks = <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plán je hotový',
              style: text.labelLarge?.copyWith(
                color: p.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Semantics(
              container: true,
              header: true,
              child: Text(
                split?.name ?? 'Tvůj program',
                style: text.headlineLarge,
              ),
            ),
            const SizedBox(height: Space.s),
            Text(
              planFacts(r),
              style: text.bodyLarge?.copyWith(fontFeatures: tabular),
            ),
            const SizedBox(height: Space.xs),
            Text(
              r.why,
              style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
        Panel(
          child: Semantics(
            label:
                'Trénink v ${[for (final d in week) weekdayLong[d - 1]].join(', ')}',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 1; d <= 7; d++)
                    _WeekDay(
                      label: weekdayShort[d - 1],
                      on: week.contains(d),
                      index: d,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (first != null)
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('První trénink · ${first.name}', style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${exercisesLabel(first.exercises.length)} · ~'
                  '${workoutMinutes(first.exercises.fold(0, (n, e) => n + e.sets))} min',
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
                const SizedBox(height: Space.m),
                for (final e in first.exercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            state.exercise(e.exerciseId).name,
                            style: text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.sets}× ${e.repMin}–${e.repMax}',
                          style: text.bodyMedium?.copyWith(
                            fontFeatures: tabular,
                            color: p.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Space.xs),
                Text(
                  'Váhy ti při prvním tréninku navrhnu podle cviku.',
                  style: text.bodySmall?.copyWith(color: p.secondaryLabel),
                ),
              ],
            ),
          ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, b) in blocks.indexed)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : Space.l),
              child: Reveal(index: i * 2, child: b),
            ),
        ],
      );
    },
  );
}

/// Den v týdnu v náhledu plánu; tréninkové dny se rozsvítí postupně.
class _WeekDay extends StatelessWidget {
  final String label;
  final bool on;
  final int index;
  const _WeekDay({required this.label, required this.on, required this.index});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.titleSmall;
    final cell = Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: on ? p.linear : null,
        color: on ? null : p.fill,
        borderRadius: BorderRadius.circular(context.palette.controlRadius),
      ),
      child: Text(
        label,
        style: style?.copyWith(color: on ? p.onGradient : p.secondaryLabel),
      ),
    );
    return on ? Reveal(index: 2 + index, offset: 8, child: cell) : cell;
  }
}

/// Připomínka tréninku: výchozí čas je předvybraný, stačí jedno klepnutí.
class _ReminderStep extends StatefulWidget {
  final int index;
  final int count;
  final bool busy;
  final VoidCallback onBack;
  final ValueChanged<int> onEnable;
  final VoidCallback onSkip;
  const _ReminderStep({
    required this.index,
    required this.count,
    required this.busy,
    required this.onBack,
    required this.onEnable,
    required this.onSkip,
  });

  @override
  State<_ReminderStep> createState() => _ReminderStepState();
}

class _ReminderStepState extends State<_ReminderStep> {
  static const _times = [7, 12, 16, 18, 20];
  int hour = 18;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return _Step(
      index: widget.index,
      count: widget.count,
      title: 'Připomenu ti trénink?',
      lead:
          'Jen v tréninkové dny a jen když ještě nemáš hotovo. Vypneš to '
          'kdykoli v Nastavení.',
      action: 'Zapnout připomínky',
      busy: widget.busy,
      onBack: widget.onBack,
      onNext: () => widget.onEnable(hour * 60),
      secondary: TextButton(
        onPressed: widget.busy ? null : widget.onSkip,
        child: const Text('Teď ne'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: IconTile(
              Icons.notifications_active_rounded,
              color: p.accent,
              size: 72,
            ),
          ),
          const SizedBox(height: Space.xl),
          Text('Kdy ti to nejvíc sedí?', style: text.titleMedium),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final h in _times)
                ChoiceChip(
                  label: Text('$h:00'),
                  selected: h == hour,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => hour = h),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
