import 'package:flutter/material.dart';

import 'state/app_state.dart';
import 'ui/exercises/exercises_page.dart';
import 'ui/history/history_page.dart';
import 'ui/home/home_page.dart';
import 'ui/onboarding/consent_page.dart';
import 'ui/theme.dart';

class GymApp extends StatelessWidget {
  final AppState state;
  const GymApp(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => _app(Accent.parse(state.profile.accent)),
  );

  Widget _app(Accent accent) => MaterialApp(
    title: 'Gym zápisník',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light, accent),
    darkTheme: buildTheme(Brightness.dark, accent),
    themeMode: switch (state.profile.theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    },
    home: state.profile.hasValidConsent ? AppShell(state) : ConsentPage(state),
  );
}

/// Hlavní navigace: Domů / Historie / Cviky.
class AppShell extends StatefulWidget {
  final AppState state;
  const AppShell(this.state, {super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(widget.state),
      HistoryPage(widget.state),
      ExercisesPage(widget.state),
    ];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Domů'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historie'),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Cviky',
          ),
        ],
      ),
    );
  }
}

/// Zobrazí se, když se nepodaří otevřít úložiště.
class StartupErrorApp extends StatelessWidget {
  final Object error;
  const StartupErrorApp(this.error, {super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.dark,
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
