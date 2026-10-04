import 'package:flutter/material.dart';

import 'app.dart';
import 'data/store.dart';
import 'data/update_safety.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final state = AppState(LocalStore());
    await state.load();
    registerUpdateSave(state.saveBeforeUpdate);
    runApp(GymApp(state));
  } catch (error) {
    runApp(StartupErrorApp(error));
  }
}
