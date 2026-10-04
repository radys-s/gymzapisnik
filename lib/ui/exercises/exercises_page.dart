import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class ExercisesPage extends StatelessWidget {
  final AppState state;
  const ExercisesPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Cviky', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Text('Tady bude seznam cviků a jejich progres.'),
    ],
  );
}
