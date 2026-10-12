import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/store.dart';
import 'data/update_safety.dart';
import 'notify/android_notifier.dart';
import 'notify/notifier.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
