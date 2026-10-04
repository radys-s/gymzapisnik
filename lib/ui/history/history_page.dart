import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class HistoryPage extends StatelessWidget {
  final AppState state;
  const HistoryPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Historie', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      const Text('Tady uvidíš dokončené tréninky.'),
    ],
  );
}
