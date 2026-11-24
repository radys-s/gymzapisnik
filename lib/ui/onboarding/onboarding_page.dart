import 'dart:async';

import 'package:flutter/material.dart';

import '../../coach/evidence.dart';
import '../../coach/plan_quiz.dart';
import '../../core/diagnostics.dart';
import '../../core/i18n.dart';
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
import '../settings/my_gym_page.dart' show gymMachinesByMuscle;
import '../widgets/exercise_media.dart' show ExerciseThumb;
import '../welcome/whats_new.dart';
import '../widgets/labels.dart';
import 'consent_page.dart';
import 'question.dart';

part 'onboarding_page/steps.dart';

/// První spuštění: co aplikace umí, souhlas, pět krátkých otázek (každá
/// na vlastní obrazovce a s vysvětlením proč), hotový plán s možností
/// složit si vlastní a připomínka. Krok se ukládá, takže po zavření
/// aplikace úvod pokračuje, kde skončil. Když uvítání už proběhlo (nové
/// podmínky), ukáže jen souhlas.
class OnboardingPage extends StatefulWidget {
  final AppState state;

  /// Nastavení plánu později (z Domova, Tréninku nebo Programu): stejné
  /// otázky jako v úvodu a navíc tělo a zaměření, bez uvítání, souhlasu
  /// a připomínky. Na konci se obrazovka zavře.
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

/// Kroky úvodu a nastavení plánu. Ukládá se pořadí kroku v daném běhu
/// (`steps`), ne pořadí v tomto výčtu.
enum _S {
  language,
  value,
  consent,
  path,
  goal,
  experience,
  schedule,
  gym,
  body,
  focus,
  reveal,
  reminder,
}

/// Otázky dotazníku: mají lištu postupu a jejich odpovědi se průběžně
/// ukládají.
const _questions = {
  _S.path,
  _S.goal,
  _S.experience,
  _S.schedule,
  _S.gym,
  _S.body,
  _S.focus,
};

/// „z 5“, ale „ze 7“.
String _outOf(int n) => const {4, 6, 7}.contains(n) ? 'ze $n' : 'z $n';

class _OnboardingPageState extends State<OnboardingPage> {
  AppState get state => widget.state;
  bool get setup => widget.setup;

  /// Uvítání jen pro nové uživatele (i po návratu doprostřed úvodu);
  /// stávající (nové podmínky) vidí rovnou souhlas.
  late final bool welcome =
      setup ||
      state.profile.onboarding ||
      (!state.profile.welcomeSeen && state.profile.consentAt == null);

  /// Připomínky jdou jen tam, kde umí aplikace poslat oznámení.
  late final bool reminders = !setup && state.notifier.supported;

  /// Own plan instead of a recommended one: after days and gym the
  /// editor opens.
  bool own = false;

  /// Steps answered in this run. An unanswered question shows no choice,
  /// so nothing looks picked before the user taps.
  late final Set<_S> answered = {
    if (setup) ..._S.values,
    if (!setup)
      for (final (i, s) in _flow(plan.style).indexed)
        if (i < state.onboardingStep) s,
  };

  /// Steps of a run. The path (own plan or a style) comes first and
  /// decides the questions: an own plan needs only days and gym, the
  /// strength style implies the goal. Body and focus are only in the
  /// later plan setup.
  List<_S> _flow(PlanStyle? style) => [
    if (!setup) ...[_S.language, _S.value, _S.consent],
    _S.path,
    if (!own && style != PlanStyle.strength) _S.goal,
    if (!own) _S.experience,
    _S.schedule,
    _S.gym,
    if (setup && !own) ...[_S.body, _S.focus],
    _S.reveal,
    if (!setup && reminders) _S.reminder,
  ];

  List<_S> get steps => _flow(plan.style);

  List<_S> get _asked => [
    for (final s in steps)
      if (_questions.contains(s)) s,
  ];

  late final int _first = setup ? 0 : _resume();

  /// Krok, kde úvod skončil. Bez souhlasu nejdál na souhlas (i když
  /// starší verze uložila pozdější krok), se souhlasem až za něj.
  int _resume() {
    final consent = steps.indexOf(_S.consent);
    final saved = state.onboardingStep;
    if (!state.profile.hasValidConsent) return saved.clamp(0, consent);
    // The own-plan choice is not saved: back to the path question.
    final path = steps.indexOf(_S.path);
    return plan.style == null
        ? path
        : saved.clamp(consent + 1, steps.length - 1);
  }

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

  /// Dotazník přeskočen: zpět z připomínky vede na dotazník, ne na
  /// odhalení plánu, který se neuložil.
  bool skipped = false;

  /// Odložený posun po výběru jedné odpovědi (krátké zvýraznění).
  Timer? _advance;

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
    final draft = _questions.contains(to) ? plan : null;
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

  /// Dál z otázky [from]. Za poslední otázkou se plán nejdřív uloží.
  void _forward(_S from) {
    final to = _next(from);
    if (to == _S.reveal) {
      unawaited(_toReveal());
    } else {
      _go(to);
    }
  }

  /// Jedna odpověď: zvýraznit, chvilku nechat vidět a jet dál.
  void _pick(PlanAnswers a, _S from) {
    answered.add(from);
    _changePlan(a);
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 300), () {
      if (mounted && step == from) _forward(from);
    });
  }

  /// Odpovědi, dny a váha se uloží najednou. Vrací, jestli se to povedlo.
  Future<bool> _save() async {
    final raw = _kg.text.trim().replaceAll(',', '.');
    final kg = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && (kg == null || !validBodyWeight(kg))) {
      showToast(
        context,
        tr(
          'Zadej váhu v kg, třeba 72,5. Nebo ji nech prázdnou.',
          'Enter weight in kg, e.g. 72.5. Or leave it empty.',
        ),
      );
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
        showToast(
          context,
          tr(
            'Plán se nepodařilo uložit. Zkus to znovu.',
            'The plan could not be saved. Try again.',
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Uloží plán z odpovědí a ukáže ho.
  Future<void> _toReveal() async {
    if (busy) return;
    if (!await _save() || !mounted) return;
    if (own) {
      await _buildOwn();
      return;
    }
    _go(_S.reveal);
  }

  /// Vlastní program místo navrženého: otevře editor. Návrh platí dál,
  /// dokud si vlastní neuloží, takže návrat bez uložení nic nezmění.
  Future<void> _buildOwn() async {
    if (busy) return;
    final saved = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            ProgramEditorPage(state, initialDayCount: plan.days.clamp(1, 7)),
      ),
    );
    if (!mounted) return;
    if (saved != null) {
      _afterReveal();
      return;
    }
    // Back from the editor without saving: the recommended plan stays.
    if (step != _S.reveal) {
      setState(() => own = false);
      _go(_S.reveal);
    }
  }

  /// Dál z hotového plánu: připomínka, jinak konec.
  void _afterReveal() {
    if (reminders) return _go(_S.reminder);
    unawaited(_finish());
  }

  /// Konec: úvod pustí do aplikace, nastavení plánu se zavře.
  Future<void> _finish() async {
    if (!setup) {
      if (busy) return;
      setState(() => busy = true);
      try {
        // Po uložení aplikace úvod sama vymění za hlavní obrazovku.
        await state.finishWelcome(whatsNewRelease);
      } catch (_) {
        if (!mounted) return;
        setState(() => busy = false);
        showToast(
          context,
          tr('Uložení se nezdařilo. Zkus to znovu.', 'Save failed. Try again.'),
        );
      }
      return;
    }
    final name = state.split?.name;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            name == null
                ? tr('Plán je uložený.', 'Plan is saved.')
                : tr('Program $name je nastavený.', 'Program $name is set.'),
          ),
        ),
      );
  }

  /// Klepnutí na den: počet vybraných dnů je zároveň počet tréninků.
  void _toggleDay(int d) {
    final next = {...days};
    if (!next.remove(d)) {
      if (next.length >= 6) {
        showToast(
          context,
          tr(
            'Aspoň jeden den v týdnu nech na odpočinek.',
            'Leave at least one rest day in the week.',
          ),
        );
        return;
      }
      next.add(d);
    }
    setState(() {
      days = next;
      if (next.length >= 2) plan = plan.copyWith(days: next.length);
    });
  }

  /// Days and length both picked: the schedule question is answered.
  bool get _scheduleDone =>
      days.length >= 2 && (answered.contains(_S.schedule) || minutesPicked);

  late bool minutesPicked = setup;

  /// The language applies at once; the app rebuilds in it and the intro
  /// resumes on the next step, which is saved first.
  Future<void> _pickLanguage(AppLang lang) async {
    await state.setOnboardingStep(steps.indexOf(_S.value));
    if (lang != state.profile.appLanguage) {
      await state.setAppLanguage(lang);
    } else if (mounted) {
      _go(_S.value);
    }
  }

  /// Machines of this gym type, ticked = available. Kept in the answers,
  /// the same way My gym in Settings stores them.
  Future<void> _pickMachines() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final groups = gymMachinesByMuscle(plan.place);
          void toggle(String id) {
            final preset = plan.place.presetMissing.contains(id);
            setState(() {
              plan = preset
                  ? plan.copyWith(present: _toggle(plan.present, id))
                  : plan.copyWith(missing: _toggle(plan.missing, id));
            });
            setSheet(() {});
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            builder: (ctx, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(
                Space.page,
                0,
                Space.page,
                Space.xl,
              ),
              children: [
                Text(
                  tr('Stroje ve tvém fitku', 'Machines at your gym'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                Text(
                  tr(
                    'Odškrtni, co tam není. Plán je pak nebude navrhovat.',
                    'Untick what is missing. The plan will not suggest it.',
                  ),
                  style: Theme.of(ctx).textTheme.bodySmall
                      ?.copyWith(color: ctx.palette.secondaryLabel),
                ),
                for (final MapEntry(key: muscle, value: list)
                    in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: Space.l),
                    child: Text(
                      muscleLabel(muscle),
                      style: Theme.of(ctx).textTheme.titleSmall,
                    ),
                  ),
                  for (final e in list)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: ExerciseThumb(e.id),
                      title: Text(e.name),
                      value: !plan.unavailable.contains(e.id),
                      onChanged: (_) => toggle(e.id),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Own plan or one of the styles. A style also fixes the goal for the
  /// strength plan.
  void _pickPath({required bool own, PlanStyle? style}) {
    answered.add(_S.path);
    setState(() => this.own = own);
    _pick(
      plan.copyWith(
        style: style,
        goal: style == PlanStyle.strength ? PlanGoal.strength : null,
      ),
      _S.path,
    );
  }

  /// Krok, kam vede zpět z kroku [from]; `null` = zavřít obrazovku.
  _S? _back(_S from) {
    if (from == _S.reminder) return skipped ? _S.path : _S.reveal;
    // Consent is saved; there is no way back before the first question.
    if (from == _S.path) return null;
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
          tr(
            'Bez povolení oznámení připomínky nepřijdou. Zapneš je v Nastavení.',
            'Without notification permission, reminders will not arrive. You can enable them in Settings.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          tr(
            'Připomínku se nepodařilo nastavit.',
            'Could not set the reminder.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        unawaited(_finish());
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
    String? skipLabel,
    Widget? secondary,
    Tone tone = Tone.training,
  }) {
    final i = _asked.indexOf(s) + 1;
    return QuestionScaffold(
      tone: tone,
      progress: i / _asked.length,
      step: tr(
        'Otázka $i ${_outOf(_asked.length)}',
        'Question $i of ${_asked.length}',
      ),
      progressLabel: '$i/${_asked.length}',
      title: title,
      why: why,
      action: action,
      onNext: onNext,
      busy: busy,
      // V úvodu před první otázkou nic není (souhlas je uložený).
      onBack: !setup && _back(s) == null ? null : () => _goBack(s),
      onSkip: onSkip,
      skipLabel: skipLabel ?? tr('Přeskočit', 'Skip'),
      secondary: secondary,
      child: child,
    );
  }

  Widget _page(_S s) => switch (s) {
    _S.language => QuestionScaffold(
      tone: Tone.progress,
      child: StaggerColumn(
        gap: Space.s,
        children: [
          const SizedBox(height: Space.xl),
          const Center(child: AppMark(size: 96)),
          const SizedBox(height: Space.l),
          Text(
            tr('Gym zápisník', 'Gym Log'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: Space.xxl),
          Semantics(
            header: true,
            child: Text(
              'Vyber jazyk · Choose language',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: context.palette.secondaryLabel),
            ),
          ),
          const SizedBox(height: Space.xs),
          for (final lang in AppLang.values)
            ChoiceCard(
              leading: _LangBadge(lang),
              label: lang.native,
              hint: lang == AppLang.cs
                  ? tr('Aplikace bude česky', 'The app will be in Czech')
                  : 'The app will be in English',
              selected: false,
              onTap: () => _pickLanguage(lang),
            ),
        ],
      ),
    ),
    _S.path => _question(
      s: s,
      onSkip: setup
          ? null
          : () {
              skipped = true;
              _afterReveal();
            },
      title: tr('Jak chceš trénovat?', 'How do you want to train?'),
      why: tr(
        'Vlastní plán si složíš za minutu. Nebo ti ho sestavím podle '
            'stylu, který ti sedí. Změníš to kdykoli v Programu.',
        'Build your own plan in a minute, or let me put one together in '
            'the style that suits you. You can change it any time.',
      ),
      tone: Tone.coach,
      child: StaggerColumn(
        gap: Space.s,
        children: [
          _OwnPlanCard(
            selected: answered.contains(_S.path) && own,
            onTap: () => _pickPath(own: true),
          ),
          const SizedBox(height: Space.m),
          Padding(
            padding: const EdgeInsets.only(left: Space.xs),
            child: Text(
              tr('Nebo ti plán sestavím', 'Or let me build one'),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: context.palette.secondaryLabel),
            ),
          ),
          for (final st in PlanStyle.values)
            ChoiceCard(
              icon: _styleIcon(st),
              label: st.label,
              hint: st.hint,
              selected: answered.contains(_S.path) && !own && plan.style == st,
              onTap: () => _pickPath(own: false, style: st),
            ),
        ],
      ),
    ),
    _S.value => QuestionScaffold(
      tone: Tone.progress,
      action: tr('Začít', 'Start'),
      onNext: () => _go(_S.consent),
      child: const _Value(),
    ),
    _S.consent => ConsentPage(
      state,
      resumeAt: steps.indexOf(_S.path),
      onAccepted: () => _go(_S.path),
      onBack: () => _go(_S.value),
    ),
    _S.goal => _question(
      s: s,
      title: tr('Co chceš hlavně?', 'What is your main goal?'),
      why: tr(
        'Podle cíle nastavím opakování: na svaly 8–12, na sílu méně '
            'a těžší, na kondici víc a s kratší pauzou.',
        'The goal sets the reps: 8–12 for muscle, fewer and heavier for '
            'strength, more with shorter rests for fitness.',
      ),
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final g in PlanGoal.values)
            ChoiceCard(
              icon: _goalIcon(g),
              label: g.label,
              hint: g.hint,
              selected: answered.contains(s) && g == plan.goal,
              onTap: () => _pick(plan.copyWith(goal: g), s),
            ),
        ],
      ),
    ),
    _S.experience => _question(
      s: s,
      title: tr('Jak dlouho cvičíš?', 'How long have you been training?'),
      why: tr(
        'Začátečník roste i z menšího objemu. Po letech je potřeba '
            'víc sérií a pomalejší postup ve vahách.',
        'Beginners grow from less volume. After years you need more sets '
            'and slower weight increases.',
      ),
      tone: Tone.progress,
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final (i, e) in Experience.values.indexed)
            ChoiceCard(
              leading: LevelBars(
                level: i + 1,
                selected: answered.contains(s) && e == plan.experience,
              ),
              label: e.label,
              hint: e.hint,
              selected: answered.contains(s) && e == plan.experience,
              onTap: () => _pick(plan.copyWith(experience: e), s),
            ),
        ],
      ),
    ),
    _S.schedule => _question(
      s: s,
      title: tr('Kdy cvičíš?', 'When do you train?'),
      why: own
          ? tr(
              'Tolik dní dostane tvůj plán. Ve vybrané dny ti připomenu '
                  'trénink.',
              'Your plan gets this many days. I will remind you on them.',
            )
          : tr(
              'Počet dní určí rozdělení (celé tělo, horní a dolní, push '
                  'pull legs), minuty to, kolik cviků se vejde.',
              'The number of days picks the split (full body, upper/lower, '
                  'push/pull/legs), minutes how many exercises fit.',
            ),
      action: tr('Pokračovat', 'Continue'),
      onNext: _scheduleDone
          ? () {
              answered.add(s);
              _forward(s);
            }
          : null,
      tone: Tone.coach,
      child: _Schedule(
        answers: plan,
        days: days,
        minutesPicked: minutesPicked,
        onMinutes: (m) => setState(() {
          minutesPicked = true;
          plan = plan.copyWith(minutes: m);
        }),
        onDay: _toggleDay,
      ),
    ),
    _S.gym => _question(
      s: s,
      title: tr('Kde cvičíš?', 'Where do you train?'),
      why: tr(
        'Nabídnu jen cviky na vybavení, které tam opravdu je. '
            'Jednotlivé stroje upřesníš v Moje posilovna.',
        'I will only suggest exercises for the equipment you have. '
            'Fine-tune single machines in My gym.',
      ),
      tone: Tone.food,
      // No auto-advance here: after the pick the machine list is offered.
      action: answered.contains(s) ? tr('Pokračovat', 'Continue') : null,
      onNext: () => _forward(s),
      secondary:
          answered.contains(s) && gymMachinesByMuscle(plan.place).isNotEmpty
          ? TextButton.icon(
              onPressed: _pickMachines,
              icon: const Icon(Icons.checklist_rounded),
              label: Text(
                tr(
                  'Zaškrtnout stroje ve fitku (nepovinné)',
                  'Tick the machines at your gym (optional)',
                ),
              ),
            )
          : null,
      child: StaggerColumn(
        gap: Space.s,
        children: [
          for (final g in TrainingPlace.values)
            ChoiceCard(
              icon: placeIcon(g),
              label: g.label,
              hint: g.hint,
              selected: answered.contains(s) && g == plan.place,
              onTap: () => setState(() {
                answered.add(s);
                plan = plan.copyWith(place: g);
              }),
            ),
        ],
      ),
    ),
    _S.body => _question(
      s: s,
      title: tr('Něco o tobě', 'About you'),
      why: tr(
        'Z váhy a výšky spočítám bílkoviny a kalorie ve Stravě. '
            'Nepovinné, údaje zůstanou jen v telefonu.',
        'Weight and height give your protein and calorie targets. '
            'Optional, and it stays on this phone.',
      ),
      action: tr('Pokračovat', 'Continue'),
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
        _forward(s);
      },
      onSkip: _skipBody,
      skipLabel: tr('Doplním později', 'Later'),
      tone: Tone.food,
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
      title: tr('Na co se zaměřit?', 'What to focus on?'),
      why: tr(
        'Vybrané partie dostanou v plánu sérii navíc. Oblíbený cvik '
            'nahradí jiný cvik na stejný sval. Obojí je nepovinné.',
        'Picked muscles get an extra set. A favourite exercise replaces '
            'another one for the same muscle. Both optional.',
      ),
      action: tr('Pokračovat', 'Continue'),
      onNext: () => _forward(s),
      tone: Tone.coach,
      child: _Focus(answers: plan, state: state, onChanged: _changePlan),
    ),
    _S.reveal => QuestionScaffold(
      action: setup
          ? tr('Hotovo', 'Done')
          : tr('Beru tenhle plán', 'Use this plan'),
      busy: busy,
      onBack: () => _goBack(s),
      onNext: _afterReveal,
      // Návrh a vlastní program vedle sebe: jedno klepnutí na každý.
      secondary: TextButton(
        onPressed: busy ? null : _buildOwn,
        child: Text(tr('Upravím si ho sám', 'Let me edit it')),
      ),
      child: _PlanReveal(state, answers: plan),
    ),
    _S.reminder => _ReminderStep(
      busy: busy,
      onBack: () => _goBack(s),
      onEnable: _enableReminder,
      onSkip: _finish,
    ),
  };

  @override
  Widget build(BuildContext context) {
    if (!welcome) return ConsentPage(state);
    return PopScope(
      canPop: _back(step) == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) _goBack(step);
      },
      child: PageView(
        controller: _pages,
        // Kroky na sobě závisí (plán až po dotazníku): jen tlačítky.
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => page = i),
        children: [for (final s in steps) _page(s)],
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
        Text(tr('Partie', 'Muscle groups'), style: text.titleMedium),
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
        Text(
          tr('Oblíbené cviky', 'Favorite exercises'),
          style: text.titleMedium,
        ),
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
