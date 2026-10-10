import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/home/home_page.dart';
import 'ui/nutrition/nutrition_page.dart';
import 'ui/onboarding/consent_page.dart';
import 'ui/theme.dart';

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
          : ConsentPage(state),
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
          nav.pop();
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

/// Zobrazí se, když se nepodaří otevřít úložiště.
class StartupErrorApp extends StatelessWidget {
  final Object error;
  const StartupErrorApp(this.error, {super.key});

  @override
  Widget build(BuildContext context) => appFrame(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aplikaci se nepodařilo spustit.\n\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
