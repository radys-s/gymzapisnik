import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class HomePage extends StatelessWidget {
  final AppState state;
  const HomePage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Domů', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Text('Zápis tréninku přibude v další verzi.'),
    ],
  );
}
