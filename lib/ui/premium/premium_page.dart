import 'package:flutter/material.dart';

import '../../premium/entitlements.dart';
import '../../state/app_state.dart';

/// Přehled Pro. Platba zatím není: testeři mají všechno odemčené.
class PremiumPage extends StatelessWidget {
  final AppState state;
  const PremiumPage(this.state, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final unlocked = !state.paywall || state.profile.isPro;
    return Scaffold(
      appBar: AppBar(title: const Text('Gym zápisník Pro')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Kouč, který za tebou chodí', style: text.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Zápis tréninků, historie, cviky, záloha, export a import zůstávají '
            'zdarma. Pro přidává kouče, který ti každý den řekne, co dělat.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          for (final f in ProFeature.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle, color: scheme.primary),
              title: Text(f.title),
              subtitle: Text(f.description),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cena', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Cena bude oznámena před spuštěním.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: unlocked ? () => Navigator.pop(context) : null,
            child: Text(
              unlocked
                  ? 'Zatím zdarma pro testery'
                  : 'Nákup zatím není k dispozici',
            ),
          ),
        ],
      ),
    );
  }
}
