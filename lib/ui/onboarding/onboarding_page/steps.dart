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
  Joint.knees => 'Méně hlubokých dřepů a výpadů',
  Joint.lowerBack => 'Bez mrtvých tahů a předklonů s osou',
  Joint.shoulders => 'Bez tlaků nad hlavu a kliků na bradlech',
};

/// Počet tréninků, délka a (nepovinně) konkrétní dny.
class _Schedule extends StatelessWidget {
  final PlanAnswers answers;
  final Set<int> days;
  final ValueChanged<PlanAnswers> onChanged;
  final ValueChanged<int> onDay;
  const _Schedule({
    required this.answers,
    required this.days,
    required this.onChanged,
    required this.onDay,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final hint = days.isEmpty
        ? 'Nepovinné. Bez výběru plán rozloží tréninky do týdne.'
        : days.length == answers.days
        ? 'Plán a připomínky v tyto dny.'
        : 'Vyber ${answers.days} dny, nebo nech plán rozložit do týdne.';
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Text(s, style: text.titleMedium),
    );
    return StaggerColumn(
      children: [
        label('Kolikrát týdně'),
        TileRow(
          children: [
            for (var d = 2; d <= 6; d++)
              ChoiceTile(
                label: '$d×',
                spoken: '$d× týdně',
                selected: answers.days == d,
                onTap: () => onChanged(answers.copyWith(days: d)),
              ),
          ],
        ),
        const SizedBox(height: Space.xxl),
        label('Jak dlouhý trénink'),
        TileRow(
          children: [
            for (final m in planMinutes)
              ChoiceTile(
                label: '$m',
                hint: 'min',
                spoken: '$m minut',
                selected: answers.minutes == m,
                onTap: () => onChanged(answers.copyWith(minutes: m)),
              ),
          ],
        ),
        const SizedBox(height: Space.xxl),
        label('Ve které dny'),
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
        Text(hint, style: text.bodySmall?.copyWith(color: p.secondaryLabel)),
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

/// Velká karta volby cesty na konci dotazníku.
class _PathCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool busy;
  final VoidCallback onTap;
  const _PathCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $body',
      excludeSemantics: true,
      child: Panel(
        onTap: busy ? null : onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: p.linear,
                borderRadius: BorderRadius.circular(p.controlRadius + 2),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.onGradient,
                      ),
                    )
                  : Icon(icon, color: p.onGradient, size: 28),
            ),
            const SizedBox(width: Space.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: text.bodyMedium?.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.tertiaryLabel),
          ],
        ),
      ),
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
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return QuestionScaffold(
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
              color: p.accent,
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
