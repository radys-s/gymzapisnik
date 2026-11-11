import 'dart:js_interop';

@JS('appStoragePersisted')
external JSBoolean? get _persisted;

/// Výsledek `navigator.storage.persist()` z `web/index.html`:
/// `true` = prohlížeč data sám nesmaže, `false` = může je smazat při
/// nedostatku místa, `null` = prohlížeč to neumí nebo ještě neodpověděl.
bool? storagePersisted() {
  try {
    return _persisted?.toDart;
  } catch (_) {
    return null;
  }
}
