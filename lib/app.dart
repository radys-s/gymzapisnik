import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/home/home_page.dart';
import 'ui/nutrition/nutrition_page.dart';
import 'ui/design/components.dart';
import 'ui/onboarding/onboarding_page.dart';
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
  String theme = 'system',
}) => MaterialApp(
  title: 'Gym zápisník',
  debugShowCheckedModeBanner: false,
  theme: buildTheme(Brightness.light, accent),
  darkTheme: buildTheme(Brightness.dark, accent),
  themeMode: switch (theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  },
  locale: _czech,
  supportedLocales: const [_czech],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: home,
);

/// Hlavní navigace: Cvičení / Strava. Každá záložka má vlastní navigaci,
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
    GlobalKey<NavigatorState>(debugLabel: 'Cvičení'),
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
            _tab(1, NutritionPage(widget.state, root: true)),
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
                label: 'Cvičení',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_outlined),
                selectedIcon: Icon(Icons.restaurant),
                label: 'Strava',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Spuštění: značka hned (navazuje na nativní spouštěcí obrazovku),
/// ukazatel načítání jen když opravdu čekáme. Žádné umělé zdržení.
class AppLoader extends StatefulWidget {
  final Future<AppState> Function() open;
  final void Function(AppState state)? onReady;
  const AppLoader({super.key, required this.open, this.onReady});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  AppState? state;
  Object? error;

  @override
  void initState() {
    super.initState();
    _load();
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
    if (ready != null) return GymApp(ready);
    return appFrame(
      home: error == null
          ? const BootScreen()
          : StartupErrorPage(error: error!, onRetry: _load),
    );
  }
}

/// Značka uprostřed; kolečko se objeví, jen když načítání trvá déle.
class BootScreen extends StatefulWidget {
  /// Po jaké době čekání ukázat ukazatel (rychlé načtení ho nezobrazí).
  static const indicatorAfter = Duration(milliseconds: 400);
  const BootScreen({super.key});

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
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Stejná velikost a místo jako nativní značka: bez poskoku.
          const AppMark(size: 96),
          Align(
            alignment: const Alignment(0, 0.3),
            child: AnimatedOpacity(
              opacity: slow ? 1 : 0,
              duration: const Duration(milliseconds: 250),
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
