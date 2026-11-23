import 'package:flutter/material.dart';

import '../../core/i18n.dart';
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
      appBar: AppBar(title: Text(tr('Gym zápisník Pro', 'Gym Log Pro'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            tr('Kouč, který za tebou chodí', 'A coach that checks in on you'),
            style: text.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Zápis tréninků, historie, cviky, záloha, export a import zůstávají '
                  'zdarma. Pro přidává kouče, který ti každý den řekne, co dělat.',
              'Workout logging, history, exercises, backup, export and import '
                  'stay free. Pro adds a coach who tells you what to do every day.',
            ),
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
                  Text(tr('Cena', 'Price'), style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Cena bude oznámena před spuštěním.',
                      'Price will be announced at launch.',
                    ),
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
                  ? tr('Zatím zdarma pro testery', 'Free for testers for now')
                  : tr(
                      'Nákup zatím není k dispozici',
                      'Purchases are not available yet',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
