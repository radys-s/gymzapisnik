import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../summary/summary_page.dart';
import '../workout/workout_page.dart';

class HomePage extends StatelessWidget {
  final AppState state;
  const HomePage(this.state, {super.key});

  Future<void> _open(BuildContext context) async {
    await state.startWorkout();
    if (!context.mounted) return;
    final finished = await Navigator.push<Workout>(
      context,
      MaterialPageRoute(builder: (_) => WorkoutPage(state)),
    );
    if (finished != null && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryPage(state, finished, justFinished: true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final active = state.active;
      final last = state.workouts.firstOrNull;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Domů', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _open(context),
            icon: Icon(
              active == null ? Icons.play_arrow : Icons.fitness_center,
            ),
            label: Text(
              active == null ? 'Začít trénink' : 'Pokračovat v tréninku',
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                title: const Text('Poslední trénink'),
                subtitle: Text('${last.name}\n${formatDateTime(last.date)}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SummaryPage(state, last)),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
