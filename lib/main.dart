import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/diagnostics.dart';
import 'data/store.dart';
import 'data/update_safety.dart';
import 'notify/android_notifier.dart';
import 'notify/notifier.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Nezachycené chyby nesmí tiše zmizet: jdou do Nastavení → Diagnostika.
  final flutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    Diagnostics.record(
      details.exception,
      stack: details.stack,
      where: details.library ?? 'Flutter',
    );
    flutterError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Diagnostics.record(error, stack: stack, where: 'async');
    return true;
  };
  // Kreslit hned; data se načítají za značkou na spouštěcí obrazovce.
  runApp(
    AppLoader(
      open: () async {
        final store = LocalStore();
        final state = AppState(
          store,
          notifier:
              !kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
              ? MobileNotifier(platform: defaultTargetPlatform)
              : const NoopNotifier(),
        );
        try {
          await state.load();
        } catch (_) {
          // Nový pokus otevře úložiště znovu; staré spojení nenechat viset.
          await store.db.close().catchError((Object _) {});
          rethrow;
        }
        return state;
      },
      onReady: (state) => registerUpdateSave(state.saveBeforeUpdate),
    ),
  );
}
