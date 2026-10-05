import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/store.dart';
import 'data/update_safety.dart';
import 'notify/android_notifier.dart';
import 'notify/notifier.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final state = AppState(
      LocalStore(),
      notifier: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? AndroidNotifier()
          : const NoopNotifier(),
    );
    await state.load();
    registerUpdateSave(state.saveBeforeUpdate);
    runApp(GymApp(state));
  } catch (error) {
    runApp(StartupErrorApp(error));
  }
}
