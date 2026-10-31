import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'coach/tips.dart';
import 'state/app_state.dart';
import 'ui/home/home_page.dart';
import 'ui/nutrition/nutrition_page.dart';
import 'ui/design/components.dart';
import 'ui/onboarding/onboarding_page.dart';
import 'ui/design/motion.dart';
import 'ui/progress/progress_page.dart';
import 'ui/theme.dart';
import 'ui/welcome/whats_new.dart';

const _czech = Locale('cs');

class GymApp extends StatelessWidget {
  final AppState state;
  const GymApp(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => appFrame(
      accent: Accent.parse(state.profile.accent),
      look: Look.parse(state.profile.look),
      theme: state.profile.theme,
      home: state.profile.hasValidConsent
          ? AppShell(state)
          : OnboardingPage(state),
    ),
  );
}

/// Společný rámec: vzhled, motiv a čeština i pro systémové dialogy.
MaterialApp appFrame({
  required Widget home,
  Accent accent = Accent.lime,
  Look look = Look.auto,
  String theme = 'dark',
}) => MaterialApp(
  title: 'Gym zápisník',
  debugShowCheckedModeBanner: false,
  theme: buildTheme(Brightness.light, accent, look),
  darkTheme: buildTheme(Brightness.dark, accent, look),
  // Tensor a Závod jsou jen tmavé, volba světlý / tmavý na ně nepůsobí.
  themeMode: switch (theme) {
    _ when look.fixed => ThemeMode.dark,
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  },
  locale: _czech,
  supportedLocales: const [_czech],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

/// Hlavní navigace: Trénink / Pokrok / Strava. Každá záložka má vlastní navigaci,
/// takže přepnutí neztratí rozpracovanou stránku, hledání ani posun.
class AppShell extends StatefulWidget {
  final AppState state;
  const AppShell(this.state, {super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int tab = widget.state.profile.lastTab;

  @override
  void initState() {
    super.initState();
    // Po aktualizaci jednou ukáže novinky (nové instalace je mají za sebou).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showWhatsNewOnce(context, widget.state);
    });
  }

  final _navigators = [
    GlobalKey<NavigatorState>(debugLabel: 'Trénink'),
    GlobalKey<NavigatorState>(debugLabel: 'Pokrok'),
    GlobalKey<NavigatorState>(debugLabel: 'Strava'),
  ];

  void _select(int i) {
    if (i == tab) {
      // Druhé klepnutí na záložku vrátí na její začátek (jako v iOS).
      _navigators[i].currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() => tab = i);
    widget.state.setLastTab(i);
  }

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
          // Kořen první záložky: zavřít aplikaci. maybePop by se vrátil
          // sem do PopScope a zacyklil se.
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: tab,
          children: [
            _tab(0, HomePage(widget.state)),
            _tab(1, ProgressPage(widget.state)),
            _tab(2, NutritionPage(widget.state, root: true)),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: p.separator, width: 0.5)),
          ),
          child: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: _select,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.fitness_center_outlined),
                selectedIcon: Icon(Icons.fitness_center),
                label: 'Trénink',
                // Popisek je vidět pořád; tooltip na webu visel.
                tooltip: '',
              ),
              NavigationDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: 'Pokrok',
                tooltip: '',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Strava',
                tooltip: '',
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
