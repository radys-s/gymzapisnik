import 'package:flutter/material.dart';

import '../../premium/entitlements.dart';
import '../../state/app_state.dart';
import 'premium_page.dart';

/// Ukáže [child], pokud je funkce odemčená, jinak zamčenou kartu
/// vedoucí na přehled Pro.
class ProGate extends StatelessWidget {
  final AppState state;
  final ProFeature feature;
  final Widget child;
  const ProGate(this.state, this.feature, {required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (state.has(feature)) return child;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_outline),
        title: Text(feature.title),
        subtitle: const Text('Součást Gym zápisník Pro'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PremiumPage(state)),
        ),
      ),
    );
  }
}
