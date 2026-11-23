part of '../onboarding_page.dart';

// Obsah jednotlivých kroků úvodu.

IconData _goalIcon(PlanGoal g) => switch (g) {
  PlanGoal.muscle => Icons.fitness_center_rounded,
  PlanGoal.strength => Icons.bolt_rounded,
  PlanGoal.fitness => Icons.favorite_rounded,
};

IconData placeIcon(TrainingPlace p) => switch (p) {
  TrainingPlace.gym => Icons.apartment_rounded,
  TrainingPlace.smallGym => Icons.storefront_rounded,
  TrainingPlace.home => Icons.home_rounded,
  TrainingPlace.bodyweight => Icons.accessibility_new_rounded,
};

IconData _jointIcon(Joint j) => switch (j) {
  Joint.knees => Icons.directions_walk_rounded,
  Joint.lowerBack => Icons.airline_seat_recline_normal_rounded,
  Joint.shoulders => Icons.sports_handball_rounded,
};

String _jointHint(Joint j) => switch (j) {
  Joint.knees => tr(
    'Méně hlubokých dřepů a výpadů',
    'Fewer deep squats and lunges',
  ),
  Joint.lowerBack => tr(
    'Bez mrtvých tahů a předklonů s osou',
    'No deadlifts or bent-over barbell work',
  ),
  Joint.shoulders => tr(
    'Bez tlaků nad hlavu a kliků na bradlech',
    'No overhead presses or dips',
  ),
};

IconData _styleIcon(PlanStyle s) => switch (s) {
  PlanStyle.science => Icons.science_outlined,
  PlanStyle.oldSchool => Icons.fitness_center_rounded,
  PlanStyle.strength => Icons.bolt_rounded,
};

/// Training days (their count is the plan's frequency) and session length.
/// Nothing is picked until the user taps.
class _Schedule extends StatelessWidget {
  final PlanAnswers answers;
  final Set<int> days;
  final bool minutesPicked;
  final ValueChanged<int> onMinutes;
  final ValueChanged<int> onDay;
  const _Schedule({
    required this.answers,
    required this.days,
    required this.minutesPicked,
    required this.onMinutes,
    required this.onDay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final n = days.length;
    final hint = n < 2
        ? tr('Vyber aspoň 2 dny.', 'Pick at least 2 days.')
        : tr('$n× týdně · připomenu ti je.', '$n× a week · I will remind you.');
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Text(s, style: text.titleMedium),
    );
    return StaggerColumn(
      children: [
        label(tr('Ve které dny', 'Which days')),
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
          style: text.bodySmall?.copyWith(
            color: n < 2 ? p.secondaryLabel : p.accent,
            fontFeatures: tabular,
          ),
        ),
        const SizedBox(height: Space.xxl),
        label(tr('Jak dlouhý trénink', 'Session length')),
        TileRow(
          children: [
            for (final m in planMinutes)
              ChoiceTile(
                label: '$m',
                hint: 'min',
                spoken: tr('$m minut', '$m minutes'),
                selected: minutesPicked && answers.minutes == m,
                onTap: () => onMinutes(m),
              ),
          ],
        ),
      ],
    );
  }
}

/// Váha, výška, rok narození, pohlaví a cíl váhy. Všechno nepovinné.
class _Body extends StatelessWidget {
  final PlanAnswers answers;
  final TextEditingController kg;
  final TextEditingController height;
  final TextEditingController year;
  final bool goalAllowed;
  final void Function({Sex? sex, WeightGoal? goal, bool clearGoal}) onChanged;
  const _Body({
    required this.answers,
    required this.kg,
    required this.height,
    required this.year,
    required this.goalAllowed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    Widget field(
      TextEditingController c,
      String label,
      String hint,
      String suffix, {
      bool decimal = false,
    }) => Expanded(
      child: Semantics(
        label: label,
        child: TextField(
          controller: c,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixText: suffix,
          ),
        ),
      ),
    );
    return StaggerColumn(
      children: [
        TileRow(
          children: [
            for (final s in Sex.values)
              ChoiceTile(
                label: s.label,
                selected: answers.sex == s,
                onTap: () => onChanged(sex: s),
              ),
          ],
        ),
        const SizedBox(height: Space.xl),
        Row(
          children: [
            field(kg, 'Váha', '72,5', 'kg', decimal: true),
            const SizedBox(width: Space.s),
            field(height, 'Výška', '180', 'cm'),
            const SizedBox(width: Space.s),
            field(year, 'Rok narození', '2008', ''),
          ],
        ),
        if (goalAllowed) ...[
          const SizedBox(height: Space.xxl),
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: Text('S váhou chci', style: text.titleMedium),
          ),
          TileRow(
            children: [
              for (final g in WeightGoal.values)
                ChoiceTile(
                  label: g.label,
                  selected: answers.weightGoal == g,
                  onTap: () => answers.weightGoal == g
                      ? onChanged(clearGoal: true)
                      : onChanged(goal: g),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Připomínka tréninku: výchozí čas je předvybraný, stačí jedno klepnutí.
class _ReminderStep extends StatefulWidget {
  final bool busy;
  final VoidCallback onBack;
  final ValueChanged<int> onEnable;
  final VoidCallback onSkip;
  const _ReminderStep({
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
    final text = Theme.of(context).textTheme;
    return QuestionScaffold(
      tone: Tone.coach,
      title: 'Připomenu ti trénink?',
      why:
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
      child: StaggerColumn(
        children: [
          Center(
            child: IconTile(
              Icons.notifications_active_rounded,
              color: context.palette.secondaryLabel,
              size: 72,
            ),
          ),
          const SizedBox(height: Space.xl),
          Text('Kdy ti to nejvíc sedí?', style: text.titleMedium),
          const SizedBox(height: Space.m),
          TileRow(
            children: [
              for (final h in _times)
                ChoiceTile(
                  label: '$h',
                  hint: ':00',
                  spoken: '$h hodin',
                  selected: h == hour,
                  onTap: () => setState(() => hour = h),
                ),
            ],
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
                  IconTile(icon, color: p.secondaryLabel, size: 40),
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
        color: on ? p.accent : p.fill,
        borderRadius: BorderRadius.circular(context.palette.controlRadius),
      ),
      child: Text(
        label,
        style: style?.copyWith(color: on ? p.onAccent : p.secondaryLabel),
      ),
    );
    return on ? Reveal(index: 2 + index, offset: 8, child: cell) : cell;
  }
}

/// Two-letter badge on the language cards (no flags: a language is not
/// a country).
class _LangBadge extends StatelessWidget {
  final AppLang lang;
  const _LangBadge(this.lang);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.fill,
        borderRadius: BorderRadius.circular(p.controlRadius + 2),
      ),
      child: Text(
        lang.name.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: condensedFont,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// The own-plan path, larger than the styles: for people who already
/// train and only want to log their routine. Shows the three steps.
class _OwnPlanCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _OwnPlanCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(p.controlRadius + 4);
    final steps = [
      tr('Dny', 'Days'),
      tr('Cviky', 'Exercises'),
      tr('Cvič', 'Train'),
    ];
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: tr(
        'Mám vlastní plán. Vyber dny, přidej cviky, cvič.',
        'I have my own plan. Pick days, add exercises, train.',
      ),
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: Color.lerp(p.grouped, p.accent, selected ? 0.22 : 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: p.accent, width: selected ? 2 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.accent,
                          borderRadius: BorderRadius.circular(
                            p.controlRadius + 2,
                          ),
                        ),
                        child: Icon(
                          Icons.edit_calendar_rounded,
                          color: p.onAccent,
                        ),
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('Mám vlastní plán', 'I have my own plan'),
                              style: text.titleLarge,
                            ),
                            Text(
                              tr(
                                'Cvičíš už nějakou dobu a víš, co děláš',
                                'You already train and know your routine',
                              ),
                              style: text.bodySmall?.copyWith(
                                color: p.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded, color: p.accent),
                    ],
                  ),
                  const SizedBox(height: Space.m),
                  Row(
                    children: [
                      for (final (i, label) in steps.indexed) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.xs,
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: p.tertiaryLabel,
                            ),
                          ),
                        Flexible(
                          child: Text(
                            '${i + 1}  $label',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelLarge?.copyWith(
                              fontFeatures: tabular,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
