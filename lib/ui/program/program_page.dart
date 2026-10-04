import 'package:flutter/material.dart';

import '../../coach/splits.dart';
import '../../state/app_state.dart';

/// Výběr splitu. Aplikace pak každý den nabídne trénink na řadě.
class ProgramPage extends StatelessWidget {
  final AppState state;
  const ProgramPage(this.state, {super.key});

  Future<void> _choose(BuildContext context, String? id) async {
    await state.setSplit(id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = state.profile.splitId;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: const Text('Vyber split')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Split určuje, co se cvičí který den. Aplikace ti pak nabídne '
            'trénink na řadě s návrhem váhy podle minula.',
            style: TextStyle(color: muted),
          ),
          for (final t in splitTemplates)
            Card(
              margin: const EdgeInsets.only(top: 12),
              shape: t.id == current
                  ? RoundedRectangleBorder(
                      side: BorderSide(color: scheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _choose(context, t.id),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text('${t.perWeek}× týdně'),
                          if (t.id == current) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, color: scheme.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(t.description),
                      const SizedBox(height: 4),
                      Text(
                        t.days.map((d) => d.name).join(' · '),
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _choose(context, null),
            child: const Text('Bez splitu – volné tréninky'),
          ),
        ],
      ),
    );
  }
}
