import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'coach/tips.dart';
import 'core/i18n.dart';
import 'state/app_state.dart';
import 'ui/widgets/keyboard_done_bar.dart';
import 'ui/home/home_page.dart';
import 'ui/nutrition/nutrition_page.dart';
import 'ui/design/components.dart';
import 'ui/onboarding/onboarding_page.dart';
import 'ui/design/motion.dart';
import 'ui/progress/progress_page.dart';
import 'ui/training/training_page.dart';
import 'ui/workout/active_workout_bar.dart';
import 'ui/theme.dart';
import 'ui/welcome/whats_new.dart';

const _czech = Locale('cs');

class GymApp extends StatelessWidget {
  final AppState state;
  const GymApp(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final lang = appLang = state.profile.appLanguage;
      // Texts are picked in build, so a new language rebuilds everything.
      return appFrame(
        home: KeyedSubtree(
          key: ValueKey(lang),
          child: state.profile.ready ? AppShell(state) : OnboardingPage(state),
        ),
        locale: Locale(lang.name),
      );
    },
  );
}

/// Shared app frame: theme, locale, and keyboard helpers.
MaterialApp appFrame({required Widget home, Locale locale = _czech}) =>
    MaterialApp(
      title: 'Gym zápisník',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: const [Locale('cs'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (_, child) => KeyboardDoneBar(child: child!),
      home: home,
    );

/// Hlavní navigace: Domů / Trénink / Strava / Pokrok. Každá záložka má vlastní
/// navigaci, takže přepnutí neztratí rozpracovanou stránku, hledání ani posun.
/// Nad lištou visí běžící trénink, ať je odkudkoli na jedno klepnutí.
class AppShell extends StatefulWidget {
  final AppState state;
  const AppShell(this.state, {super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  late int tab = widget.state.profile.lastTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Po aktualizaci jednou ukáže novinky (nové instalace je mají za sebou).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showWhatsNewOnce(context, widget.state);
    });
  }

  final _navigators = [
    GlobalKey<NavigatorState>(debugLabel: 'Domů'),
    GlobalKey<NavigatorState>(debugLabel: 'Trénink'),
    GlobalKey<NavigatorState>(debugLabel: 'Strava'),
    GlobalKey<NavigatorState>(debugLabel: 'Pokrok'),
  ];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Telefon nechá aplikaci otevřenou přes noc: ráno má ukázat nový den.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.state.checkNewDay();
  }

  void _select(int i) {
    widget.state.checkNewDay();
    if (i == tab) {
      // Druhé klepnutí na záložku vrátí na její začátek (jako v iOS).
      _navigators[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => tab = i);
    widget.state.setLastTab(i);
  }

  static const _items = [
    (
      icon: Icons.home_outlined,
      active: Icons.home_rounded,
      label: 'Domů',
      tone: Tone.training,
    ),
    (
      icon: Icons.fitness_center_outlined,
      active: Icons.fitness_center,
      label: 'Trénink',
      tone: Tone.training,
    ),
    (
      icon: Icons.restaurant_outlined,
      active: Icons.restaurant_rounded,
      label: 'Strava',
      tone: Tone.food,
    ),
    (
      icon: Icons.insights_outlined,
      active: Icons.insights_rounded,
      label: 'Pokrok',
      tone: Tone.progress,
    ),
  ];

  Widget _tab(int i, Widget root) => Navigator(
    key: _navigators[i],
    onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigators[tab].currentState;
        if (nav != null && nav.canPop()) {
          nav.maybePop();
        } else if (tab != 0) {
          _select(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: FadeIndexedStack(
          index: tab,
          children: [
            _tab(0, HomePage(widget.state)),
            _tab(1, TrainingPage(widget.state)),
            _tab(2, NutritionPage(widget.state, root: true)),
            _tab(3, ProgressPage(widget.state)),
          ],
        ),
        bottomNavigationBar: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.contentMax),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActiveWorkoutBar(widget.state),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.elevated.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: p.separator.withValues(alpha: 0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < _items.length; i++)
                              Expanded(
                                child: _NavItem(
                                  icon: _items[i].icon,
                                  activeIcon: _items[i].active,
                                  label: _items[i].label,
                                  color: _items[i].tone.color,
                                  selected: i == tab,
                                  onTap: () => _select(i),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? color : p.tertiaryLabel;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    selected ? activeIcon : icon,
                    key: ValueKey(selected),
                    color: fg,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontFamily: textFont,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: fg,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                height: 3,
                width: selected ? 18 : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spuštění: značka hned (navazuje na nativní spouštěcí obrazovku) a pod
/// ní rada nebo motivační věta. Obrazovka zůstane aspoň [minShow], aby
/// šla přečíst; klepnutí ji po načtení přeskočí.
class AppLoader extends StatefulWidget {
  final Future<AppState> Function() open;
  final void Function(AppState state)? onReady;
  final Duration minShow;

  /// Číslo rady (jinak náhodně).
  final int? tipSeed;
  const AppLoader({
    super.key,
    required this.open,
    this.onReady,
    this.minShow = const Duration(milliseconds: 2200),
    this.tipSeed,
  });

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  AppState? state;
  Object? error;
  late final Tip tip = tipAt(widget.tipSeed ?? Random().nextInt(1 << 16));

  /// Rada ještě musí zůstat vidět.
  late bool held = widget.minShow > Duration.zero;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    if (held) {
      _hold = Timer(widget.minShow, () {
        if (mounted) setState(() => held = false);
      });
    }
    _load();
  }

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _skip() {
    _hold?.cancel();
    if (held) setState(() => held = false);
  }

  Future<void> _load() async {
    if (error != null) setState(() => error = null);
    try {
      final opened = await widget.open();
      widget.onReady?.call(opened);
      if (mounted) setState(() => state = opened);
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = state;
    if (ready != null && !held) return GymApp(ready);
    return appFrame(
      home: error == null
          ? BootScreen(tip: tip, onSkip: _skip)
          : StartupErrorPage(error: error!, onRetry: _load),
    );
  }
}

/// Značka uprostřed, pod ní rada; kolečko se objeví, jen když načítání
/// trvá déle.
class BootScreen extends StatefulWidget {
  /// Po jaké době čekání ukázat ukazatel (rychlé načtení ho nezobrazí).
  static const indicatorAfter = Duration(milliseconds: 400);
  final Tip? tip;
  final VoidCallback? onSkip;
  const BootScreen({super.key, this.tip, this.onSkip});

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  bool slow = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(BootScreen.indicatorAfter, () {
      if (mounted) setState(() => slow = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final tip = widget.tip;
    return Scaffold(
      body: Semantics(
        button: widget.onSkip != null,
        label: widget.onSkip != null ? 'Přeskočit' : null,
        onTap: widget.onSkip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onSkip,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stejná velikost a místo jako nativní značka: bez poskoku.
              const AppMark(size: 96),
              if (tip != null)
                Align(
                  alignment: const Alignment(0, 0.62),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: MediaQuery.of(context).disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 500),
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - t)),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Semantics(
                        container: true,
                        liveRegion: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tip.kind.toUpperCase(),
                              style: text.labelMedium?.copyWith(
                                color: p.accent,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tip.text,
                              textAlign: TextAlign.center,
                              style: text.titleMedium?.copyWith(height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: const Alignment(0, 0.3),
                child: AnimatedOpacity(
                  opacity: slow ? 1 : 0,
                  duration: Motion.of(context, Motion.quick),
                  child: Semantics(
                    container: true,
                    label: 'Načítám',
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: p.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Když se nepodaří otevřít úložiště: srozumitelně a s novým pokusem.
class StartupErrorPage extends StatefulWidget {
  final Object error;
  final Future<void> Function() onRetry;
  const StartupErrorPage({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  State<StartupErrorPage> createState() => _StartupErrorPageState();
}

class _StartupErrorPageState extends State<StartupErrorPage> {
  bool retrying = false;

  Future<void> _retry() async {
    setState(() => retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.xxl),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 56,
                          color: p.secondaryLabel,
                        ),
                        const SizedBox(height: Space.xl),
                        Text(
                          'Aplikaci se nepodařilo spustit',
                          style: text.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Space.m),
                        Text(
                          'Zkus to znovu. Když to nepomůže, zavři aplikaci '
                          'úplně a otevři ji znovu. Zálohu ze souboru pak '
                          'obnovíš v Nastavení.',
                          style: text.bodyLarge?.copyWith(
                            color: p.secondaryLabel,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: Space.l),
                        SelectableText(
                          '${widget.error}',
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              PrimaryButton('Zkusit znovu', busy: retrying, onPressed: _retry),
            ],
          ),
        ),
      ),
    );
  }
}
