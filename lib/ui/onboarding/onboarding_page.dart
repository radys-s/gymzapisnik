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
import '../program/plan_quiz.dart' show planFacts;
import '../program/program_editor_page.dart';
import '../program/program_widgets.dart';
import '../welcome/whats_new.dart';
import '../widgets/labels.dart';
import 'consent_page.dart';
import 'question.dart';

/// První spuštění: co aplikace umí, sedm krátkých otázek (každá na
/// vlastní obrazovce a s vysvětlením proč), volba „vyber za mě“ nebo
/// „složím si sám“, připomínka a souhlas. Krok se ukládá, takže po
/// zavření aplikace úvod pokračuje, kde skončil. Když uvítání už
/// proběhlo (nové podmínky), ukáže jen souhlas.
class OnboardingPage extends StatefulWidget {
  final AppState state;

  /// Nastavení plánu později (z Domova, Tréninku nebo Programu): stejné
  /// otázky jako v úvodu a navíc zaměření, bez uvítání, připomínky
  /// a souhlasu. Na konci se obrazovka zavře.
  final bool setup;
  const OnboardingPage(this.state, {super.key, this.setup = false});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

/// Plán sestavený stejnými otázkami jako v úvodu. Jediný formulář plánu
/// v aplikaci.
class PlanSetupPage extends OnboardingPage {
  const PlanSetupPage(super.state, {super.key}) : super(setup: true);
}

/// Kroky úvodu. Pořadí v úvodu se ukládá jako číslo kroku, takže se
/// nesmí měnit (jen přidávat za konec).
enum _S {
  value,
  goal,
  experience,
  schedule,
  gym,
  pain,
  body,
  focus,
  path,
  reveal,
  reminder,
  consent,
}

/// Kroky s lištou postupu.
const _questions = {
  _S.goal,
  _S.experience,
  _S.schedule,
  _S.gym,
  _S.pain,
  _S.body,
  _S.focus,
  _S.path,
};

class _OnboardingPageState extends State<OnboardingPage> {
  AppState get state => widget.state;
  bool get setup => widget.setup;

  /// Uvítání jen pro nové uživatele; stávající (nové podmínky) vidí
  /// rovnou souhlas.
  late final bool welcome =
      setup || (!state.profile.welcomeSeen && state.profile.consentAt == null);

  /// Připomínky jdou jen tam, kde umí aplikace poslat oznámení.
  late final bool reminders = !setup && state.notifier.supported;

  /// Kroky v tomto běhu. Úvod je bez zaměření (to se doladí později),
  /// nastavení plánu bez uvítání, připomínky a souhlasu.
  late final List<_S> steps = setup
      ? const [
          _S.goal,
          _S.experience,
          _S.schedule,
          _S.gym,
          _S.pain,
          _S.body,
          _S.focus,
          _S.path,
          _S.reveal,
        ]
      : [
          _S.value,
          _S.goal,
          _S.experience,
          _S.schedule,
          _S.gym,
          _S.pain,
          _S.body,
          _S.path,
          _S.reveal,
          if (reminders) _S.reminder,
          _S.consent,
        ];

  late final List<_S> _asked = [
    for (final s in steps)
      if (_questions.contains(s)) s,
  ];

  late final int _first = setup
      ? 0
      : state.onboardingStep.clamp(0, steps.length - 1);
  late final _pages = PageController(initialPage: _first);
  late int page = _first;
  _S get step => steps[page];

  late PlanAnswers plan =
      (setup ? null : state.planDraft) ??
      state.planAnswers ??
      const PlanAnswers();
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
  late final _height = TextEditingController(
    text: plan.heightCm?.toString() ?? '',
  );
  late final _year = TextEditingController(
    text: plan.birthYear?.toString() ?? '',
  );
  bool busy = false;

  /// Dotazník přeskočen: zpět z dalšího kroku vede na dotazník, ne na
  /// odhalení plánu, který se neuložil.
  bool skipped = false;

  /// Program si skládá sám: zpět vede na volbu cesty, ne na odhalení.
  bool own = false;

  /// Odložený posun po výběru jedné odpovědi (krátké zvýraznění).
  Timer? _advance;

  /// Krok po odhalení plánu: připomínka nebo souhlas.
  _S get _after => reminders ? _S.reminder : _S.consent;

  void _go(_S to) {
    _advance?.cancel();
    final index = steps.indexOf(to);
    assert(index >= 0, '$to not in this flow');
    _pages.animateToPage(
      index,
      duration: Motion.of(context, Motion.base),
      curve: Motion.curve,
    );
    if (setup) return;
    // Uložení kroku nesmí zastavit úvod. Rozpracované odpovědi se
    // ukládají s ním.
    final draft = to.index > _S.value.index && to.index <= _S.path.index
        ? plan
        : null;
    unawaited(state.setOnboardingStep(index, draft: draft).catchError((_) {}));
  }

  /// Další krok po [from] v tomto běhu.
  _S _next(_S from) => steps[steps.indexOf(from) + 1];

  /// Jedna odpověď: zvýraznit, chvilku nechat vidět a jet dál.
  void _pick(PlanAnswers a, _S from) {
    _changePlan(a);
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 300), () {
      if (mounted && step == from) _go(_next(from));
    });
  }

  /// Odpovědi, dny a váha se uloží najednou. Vrací, jestli se to povedlo.
  Future<bool> _save() async {
    final raw = _kg.text.trim().replaceAll(',', '.');
    final kg = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && (kg == null || !validBodyWeight(kg))) {
      showToast(context, 'Zadej váhu v kg, třeba 72,5. Nebo ji nech prázdnou.');
      return false;
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
      return true;
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _chooseForMe() async {
    if (busy) return;
    own = false;
    if (await _save() && mounted) _go(_S.reveal);
  }

  /// Vlastní program: uloží odpovědi (posilovna, klouby) a otevře
  /// editor. Plán z odpovědí zůstane, dokud si neuloží vlastní.
  Future<void> _buildOwn() async {
    if (busy) return;
    own = true;
    if (!await _save() || !mounted) return;
    await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => ProgramEditorPage(state)));
    if (mounted) _finish();
  }

  /// Konec dotazníku: v úvodu další krok, v nastavení plánu zavřít.
  void _finish() {
    if (!setup) return _go(_after);
    final name = state.split?.name;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            name == null ? 'Plán je uložený.' : 'Program $name je nastavený.',
          ),
        ),
      );
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

  /// Krok, kam vede zpět z kroku [from]; `null` = zavřít obrazovku.
  _S? _back(_S from) {
    if (from == _after && !setup) {
      return skipped
          ? _S.goal
          : own
          ? _S.path
          : _S.reveal;
    }
    if (from == _S.reveal) return _S.path;
    final i = steps.indexOf(from);
    return i > 0 ? steps[i - 1] : null;
  }

  void _goBack(_S from) {
    final to = _back(from);
    if (to == null) {
      Navigator.maybePop(context);
    } else {
      _go(to);
    }
  }

  void _changePlan(PlanAnswers a) => setState(() {
    // Jiný počet tréninků: vybrané dny už nesedí.
    if (a.days != plan.days) days = {};
    plan = a;
  });

  /// Údaje o těle z polí; neplatné hodnoty se neuloží.
  void _bodyChanged({Sex? sex, WeightGoal? goal, bool clearGoal = false}) {
    int? whole(String raw, int min, int max) {
      final v = int.tryParse(raw.trim());
      return v != null && v >= min && v <= max ? v : null;
    }

    final now = DateTime.now().year;
    final year = whole(_year.text, now - 100, now - 10);
    _changePlan(
      plan.withBody(
        sex: sex ?? plan.sex,
        heightCm: whole(_height.text, 120, 230),
        birthYear: year,
        weightGoal: clearGoal || !_goalAllowed(year)
            ? null
            : goal ?? plan.weightGoal,
      ),
    );
  }

  /// Kalorie jen pro dospělé. Z roku narození jde věk určit jen na rok
  /// přesně: 18 let jistě má až ten, komu letos bude 19.
  bool _goalAllowed(int? birthYear) =>
      state.profile.adult ||
      (birthYear != null && DateTime.now().year - birthYear >= 19);

  void _skipBody() {
    _kg.clear();
    _height.clear();
    _year.clear();
    _changePlan(
      plan.withBody(
        sex: null,
        heightCm: null,
        birthYear: null,
        weightGoal: null,
      ),
    );
    _go(_next(_S.body));
  }

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
        _go(_S.consent);
      }
    }
  }

  @override
  void dispose() {
    _advance?.cancel();
    _pages.dispose();
    _kg.dispose();
    _height.dispose();
    _year.dispose();
    super.dispose();
  }

  /// Otázka [s]: lišta postupu, zpět a přeskočení.
  Widget _question({
    required _S s,
    required String title,
    required String why,
    required Widget child,
    String? action,
    VoidCallback? onNext,
    VoidCallback? onSkip,
    String skipLabel = 'Přeskočit',
  }) {
    final i = _asked.indexOf(s) + 1;
    return QuestionScaffold(
      progress: i / _asked.length,
      step: 'Otázka $i ze ${_asked.length}',
      title: title,
      why: why,
      action: action,
      onNext: onNext,
      busy: busy,
      onBack: () => _goBack(s),
      onSkip: onSkip,
      skipLabel: skipLabel,
      child: child,
    );
  }

  Widget _page(_S s, Widget consent) => switch (s) {
    _S.value => QuestionScaffold(
      action: 'Sestavit můj plán',
      onNext: () => _go(_S.goal),
      child: const _Value(),
    ),
    _S.goal => _question(
      s: s,
      title: 'Co chceš hlavně?',
      why:
          'Podle cíle nastavím opakování: na svaly 8–12, na sílu méně '
          'a těžší, na kondici víc a s kratší pauzou.',
      onSkip: setup
          ? null
          : () {
              skipped = true;
              _go(_after);
            },
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final g in PlanGoal.values)
            ChoiceCard(
              icon: _goalIcon(g),
              label: g.label,
              hint: g.hint,
              selected: g == plan.goal,
              onTap: () => _pick(plan.copyWith(goal: g), s),
            ),
        ],
      ),
    ),
    _S.experience => _question(
      s: s,
      title: 'Jak dlouho cvičíš?',
      why:
          'Začátečník roste i z menšího objemu. Po letech je potřeba '
          'víc sérií a pomalejší postup ve vahách.',
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final (i, e) in Experience.values.indexed)
            ChoiceCard(
              leading: LevelBars(level: i + 1, selected: e == plan.experience),
              label: e.label,
              hint: e.hint,
              selected: e == plan.experience,
              onTap: () => _pick(plan.copyWith(experience: e), s),
            ),
        ],
      ),
    ),
    _S.schedule => _question(
      s: s,
      title: 'Kolik času máš?',
      why:
          'Počet dní určí rozdělení (celé tělo, horní a dolní, push '
          'pull legs), minuty to, kolik cviků se do tréninku vejde.',
      action: 'Pokračovat',
      onNext: () => _go(_next(s)),
      child: _Schedule(
        answers: plan,
        days: days,
        onChanged: _changePlan,
        onDay: _toggleDay,
      ),
    ),
    _S.gym => _question(
      s: s,
      title: 'Kde cvičíš?',
      why:
          'Do plánu dám jen cviky na vybavení, které tam opravdu je. '
          'Chybějící stroje odškrtneš později v Profilu.',
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final g in TrainingPlace.values)
            ChoiceCard(
              icon: placeIcon(g),
              label: g.label,
              hint: g.hint,
              selected: g == plan.place,
              onTap: () => _pick(plan.copyWith(place: g), s),
            ),
        ],
      ),
    ),
    _S.pain => _question(
      s: s,
      title: 'Bolí tě něco?',
      why:
          'Cviky, které bolavý kloub zatěžují, vyměním za šetrnější '
          'na stejný sval. Vybrat můžeš víc.',
      action: plan.avoid.isEmpty ? 'Nic mě nebolí' : 'Pokračovat',
      onNext: () => _go(_next(s)),
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final j in Joint.values)
            ChoiceCard(
              icon: _jointIcon(j),
              label: j.label,
              hint: _jointHint(j),
              multi: true,
              selected: plan.avoid.contains(j),
              onTap: () =>
                  _changePlan(plan.copyWith(avoid: _toggle(plan.avoid, j))),
            ),
        ],
      ),
    ),
    _S.body => _question(
      s: s,
      title: 'Něco o tobě',
      why:
          'Z váhy a výšky spočítám bílkoviny a kalorie ve Stravě. '
          'Nepovinné, údaje zůstanou jen v telefonu.',
      action: 'Pokračovat',
      onNext: () {
        final raw = _kg.text.trim().replaceAll(',', '.');
        final kg = raw.isEmpty ? null : double.tryParse(raw);
        if (raw.isNotEmpty && (kg == null || !validBodyWeight(kg))) {
          showToast(
            context,
            'Zadej váhu v kg, třeba 72,5. Nebo ji nech prázdnou.',
          );
          return;
        }
        _go(_next(s));
      },
      onSkip: _skipBody,
      skipLabel: 'Doplním později',
      child: _Body(
        answers: plan,
        kg: _kg,
        height: _height,
        year: _year,
        goalAllowed: _goalAllowed(plan.birthYear),
        onChanged: _bodyChanged,
      ),
    ),
    _S.focus => _question(
      s: s,
      title: 'Na co se zaměřit?',
      why:
          'Vybrané partie dostanou v plánu sérii navíc. Oblíbený cvik '
          'nahradí jiný cvik na stejný sval. Obojí je nepovinné.',
      action: 'Pokračovat',
      onNext: () => _go(_next(s)),
      child: _Focus(answers: plan, state: state, onChanged: _changePlan),
    ),
    _S.path => _question(
      s: s,
      title: 'Jak chceš začít?',
      why:
          'Oboje jde kdykoli změnit v Programu. Vlastní rutinu ti '
          'zkontroluju, ať žádné hlavě svalu nechybí cvik.',
      child: StaggerColumn(
        gap: Space.m,
        children: [
          _PathCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Vyber za mě',
            body:
                'Sestavím program podle tvých odpovědí. Váhy navrhnu '
                'při prvním tréninku.',
            busy: busy && !own,
            onTap: _chooseForMe,
          ),
          _PathCard(
            icon: Icons.edit_note_rounded,
            title: 'Složím si sám',
            body:
                'Vybereš cviky, které chceš dělat. Řeknu ti, když '
                'třeba na biceps chybí cvik na krátkou hlavu.',
            busy: busy && own,
            onTap: _buildOwn,
          ),
        ],
      ),
    ),
    _S.reveal => QuestionScaffold(
      action: setup ? 'Hotovo' : 'Pokračovat',
      onBack: () => _go(_S.path),
      onNext: _finish,
      child: _PlanReveal(state, answers: plan),
    ),
    _S.reminder => _ReminderStep(
      busy: busy,
      onBack: () => _goBack(_S.reminder),
      onEnable: _enableReminder,
      onSkip: () => _go(_S.consent),
    ),
    _S.consent => consent,
  };

  @override
  Widget build(BuildContext context) {
    final consent = ConsentPage(
      state,
      welcomeVersion: welcome ? whatsNewRelease : null,
    );
    if (!welcome) return consent;
    return PopScope(
      canPop: page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && page > 0 && !busy) _goBack(step);
      },
      child: PageView(
        controller: _pages,
        // Kroky na sobě závisí (plán až po dotazníku): jen tlačítky.
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => page = i),
        children: [for (final s in steps) _page(s, consent)],
      ),
    );
  }
}

Set<T> _toggle<T>(Set<T> set, T v) =>
    set.contains(v) ? ({...set}..remove(v)) : {...set, v};

/// Zaměření plánu: partie se sérií navíc a oblíbené cviky.
class _Focus extends StatelessWidget {
  final PlanAnswers answers;
  final AppState state;
  final ValueChanged<PlanAnswers> onChanged;
  const _Focus({
    required this.answers,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final a = answers;
    Widget chips(List<Widget> children) =>
        Wrap(spacing: Space.s, runSpacing: Space.s, children: children);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Partie', style: text.titleMedium),
        const SizedBox(height: Space.s),
        chips([
          for (final f in focusChoices)
            FilterChip(
              label: Text(focusName(f)),
              selected: a.focus.contains(f),
              onSelected: (_) =>
                  onChanged(a.copyWith(focus: _toggle(a.focus, f))),
            ),
        ]),
        const SizedBox(height: Space.xl),
        Text('Oblíbené cviky', style: text.titleMedium),
        const SizedBox(height: Space.s),
        chips([
          for (final id in favoriteChoices)
            FilterChip(
              label: Text(state.exercise(id).name),
              selected: a.favorites.contains(id),
              onSelected: (_) =>
                  onChanged(a.copyWith(favorites: _toggle(a.favorites, id))),
            ),
        ]),
      ],
    );
  }
}

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
