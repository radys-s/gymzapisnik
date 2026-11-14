import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../core/diagnostics.dart';
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

part 'onboarding_page/steps.dart';

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
    unawaited(
      state
          .setOnboardingStep(index, draft: draft)
          .catchError(
            (Object e, StackTrace s) =>
                Diagnostics.record(e, stack: s, where: 'krok úvodu'),
          ),
    );
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
          'Chybějící stroje odškrtneš později v Nastavení.',
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
