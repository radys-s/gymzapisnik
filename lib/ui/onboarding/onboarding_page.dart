import 'package:flutter/material.dart';

import '../../coach/plan_quiz.dart';
import '../../state/app_state.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../program/plan_quiz.dart';
import '../welcome/whats_new.dart';
import 'accent_picker.dart';
import 'consent_page.dart';

/// Úvodní strana: obrázek, nadpis, jedna myšlenka.
typedef _Intro = ({IconData? icon, String title, String body});

const _intro = <_Intro>[
  (
    icon: null,
    title: 'Gym zápisník',
    body:
        'Aplikace předvyplní minulé váhy a opakování. Upravíš je podle '
        'dnešního výkonu a potvrdíš sérii.',
  ),
  (
    icon: Icons.restaurant_rounded,
    title: 'Trénink i jídlo na jednom místě',
    body:
        'Vybereš si program a den tréninku. Ve Stravě sleduješ '
        'bílkoviny a necháš si poradit, co uvařit z ledničky.',
  ),
  (
    icon: Icons.lock_outline_rounded,
    title: 'Tvoje data zůstávají u tebe',
    body:
        'Bez účtu a bez reklam. Zápis tréninku, historie a ruční deník '
        'fungují bez internetu. AI a hledání čárových kódů potřebují '
        'připojení a odesílají údaje ke zpracování. Data si zálohuj do souboru.',
  ),
];

/// První spuštění: uvítání (jednou), výběr barvy, plán, souhlas.
/// Když uvítání už proběhlo (např. nové podmínky), ukáže jen souhlas.
class OnboardingPage extends StatefulWidget {
  final AppState state;
  const OnboardingPage(this.state, {super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  /// Uvítání jen pro nové uživatele; stávající (nové podmínky) vidí
  /// rovnou souhlas.
  late final bool welcome =
      !widget.state.profile.welcomeSeen &&
      widget.state.profile.consentAt == null;
  final _pages = PageController();
  int page = 0;
  PlanAnswers plan = const PlanAnswers();
  bool savingPlan = false;

  /// Tečky postupu patří uvítání, vzhledu a plánu (souhlas je samostatný).
  int get _dots => _intro.length + 2;
  int get _accentStep => _intro.length;
  int get _planStep => _intro.length + 1;

  Future<void> _applyPlan() async {
    setState(() => savingPlan = true);
    try {
      await widget.state.applyPlan(plan);
      if (mounted) _go(_planStep + 1);
    } catch (_) {
      if (mounted) {
        showToast(context, 'Plán se nepodařilo uložit. Zkus to znovu.');
      }
    } finally {
      if (mounted) setState(() => savingPlan = false);
    }
  }

  void _go(int to) => _pages.animateToPage(
    to,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320),
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consent = ConsentPage(
      widget.state,
      welcomeVersion: welcome ? whatsNewRelease : null,
    );
    if (!welcome) return consent;
    return PopScope(
      canPop: page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && page > 0) _go(page - 1);
      },
      child: PageView(
        controller: _pages,
        onPageChanged: (i) => setState(() => page = i),
        children: [
          for (var i = 0; i < _intro.length; i++)
            _IntroStep(
              intro: _intro[i],
              index: i,
              count: _dots,
              onNext: () => _go(i + 1),
              onSkip: () => _go(_accentStep),
            ),
          _AccentStep(
            state: widget.state,
            index: _accentStep,
            count: _dots,
            onNext: () => _go(_planStep),
          ),
          _PlanStep(
            answers: plan,
            onChanged: (a) => setState(() => plan = a),
            index: _planStep,
            count: _dots,
            busy: savingPlan,
            onNext: _applyPlan,
            onSkip: () => _go(_planStep + 1),
          ),
          consent,
        ],
      ),
    );
  }
}

/// Spodní část kroku: tečky postupu a hlavní tlačítko.
class _StepFooter extends StatelessWidget {
  final int index;
  final int count;
  final VoidCallback onNext;
  final String label;
  final bool busy;
  const _StepFooter({
    required this.index,
    required this.count,
    required this.onNext,
    this.label = 'Pokračovat',
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        // Odstup od posouvaného obsahu, ať tečky nesedí na seznamu.
        const SizedBox(height: Space.l),
        Semantics(
          container: true,
          label: 'Krok ${index + 1} z $count',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
        ),
        const SizedBox(height: Space.xxl),
        PrimaryButton(label, busy: busy, onPressed: onNext),
      ],
    );
  }
}

class _IntroStep extends StatelessWidget {
  final _Intro intro;
  final int index;
  final int count;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _IntroStep({
    required this.intro,
    required this.index,
    required this.count,
    required this.onNext,
    required this.onSkip,
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
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('Přeskočit'),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: Space.l),
                    child: Column(
                      children: [
                        if (intro.icon == null)
                          const AppMark(size: 112)
                        else
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              gradient: p.linear,
                              borderRadius: BorderRadius.circular(112 * 0.23),
                            ),
                            child: Icon(
                              intro.icon,
                              size: 52,
                              color: p.onGradient,
                            ),
                          ),
                        const SizedBox(height: Space.xxxl),
                        Semantics(
                          container: true,
                          header: true,
                          child: Text(
                            intro.title,
                            style: text.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: Space.m),
                        Text(
                          intro.body,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: p.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _StepFooter(index: index, count: count, onNext: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentStep extends StatelessWidget {
  final AppState state;
  final int index;
  final int count;
  final VoidCallback onNext;
  const _AccentStep({
    required this.state,
    required this.index,
    required this.count,
    required this.onNext,
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
            Space.xxxl,
            Space.page,
            Space.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            container: true,
                            header: true,
                            child: Text(
                              'Vyber si vzhled',
                              style: text.headlineLarge,
                            ),
                          ),
                          const SizedBox(height: Space.m),
                          Text(
                            'Změníš ho kdykoli v Nastavení.',
                            style: text.bodyLarge?.copyWith(
                              color: p.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: Space.xxl),
                        ],
                      ),
                    ),
                    AppearanceOptions(state),
                  ],
                ),
              ),
              _StepFooter(index: index, count: count, onNext: onNext),
            ],
          ),
        ),
      ),
    );
  }
}

/// Krátký dotazník: z odpovědí vybere program a počet cviků.
class _PlanStep extends StatelessWidget {
  final PlanAnswers answers;
  final ValueChanged<PlanAnswers> onChanged;
  final int index;
  final int count;
  final bool busy;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  const _PlanStep({
    required this.answers,
    required this.onChanged,
    required this.index,
    required this.count,
    required this.busy,
    required this.onNext,
    required this.onSkip,
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : onSkip,
                  child: const Text('Přeskočit'),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            container: true,
                            header: true,
                            child: Text('Tvůj plán', style: text.headlineLarge),
                          ),
                          const SizedBox(height: Space.m),
                          Text(
                            'Čtyři otázky a doporučím ti program. Změníš ho '
                            'kdykoli v Programu.',
                            style: text.bodyLarge?.copyWith(
                              color: p.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: Space.l),
                        ],
                      ),
                    ),
                    PlanQuizForm(answers: answers, onChanged: onChanged),
                    const SizedBox(height: Space.l),
                    PlanPreview(recommendPlan(answers)),
                  ],
                ),
              ),
              _StepFooter(
                index: index,
                count: count,
                label: 'Použít plán',
                busy: busy,
                onNext: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
