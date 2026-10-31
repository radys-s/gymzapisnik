import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'settings_page.dart';

/// Ikona nastavení vpravo nahoře na obou záložkách.
class SettingsButton extends StatelessWidget {
  final AppState state;
  const SettingsButton(this.state, {super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Nastavení',
    icon: Badge(
      isLabelVisible: state.backupDue,
      smallSize: 8,
      child: const Icon(Icons.settings_outlined),
    ),
    onPressed: () => Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => SettingsPage(state))),
  );
}
