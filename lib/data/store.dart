import 'dart:convert';

import 'package:drift/drift.dart';

import 'database.dart';

/// Lokální úložiště JSON dokumentů nad tabulkou `entities`.
///
/// Mazání je měkké (`deleted=1`), aby se později dalo synchronizovat.
/// Každý zápis běží v transakci: na webu se data do IndexedDB uloží
/// (flush) právě po commitu transakce.
class LocalStore {
  final AppDatabase db;
  LocalStore([AppDatabase? database]) : db = database ?? AppDatabase();

  /// Otevře databázi a ověří, že se dá číst.
  Future<void> open() async {
    await db.customSelect('SELECT count(*) AS count FROM entities').get();
  }

  Future<void> put(String kind, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await db.transaction(
      () => db.customStatement(
        '''
      INSERT INTO entities(id,kind,payload,updated_at,dirty,deleted,conflict,remote_revision)
      VALUES(?,?,?,?,1,0,0,0)
      ON CONFLICT(id) DO UPDATE SET kind=excluded.kind,payload=excluded.payload,
        updated_at=excluded.updated_at,dirty=1,deleted=0
    ''',
        [id, kind, jsonEncode(data), _now()],
      ),
    );
  }

  /// Uloží dokončený trénink a smaže rozepsaný v jedné transakci,
  /// takže po pádu nikdy nezůstanou oba ani žádný.
  Future<void> replace({
    required String removeId,
    required String kind,
    required Map<String, dynamic> data,
  }) => db.transaction(() async {
    await db.customStatement(
      '''
      INSERT INTO entities(id,kind,payload,updated_at,dirty,deleted,conflict,remote_revision)
      VALUES(?,?,?,?,1,0,0,0)
      ON CONFLICT(id) DO UPDATE SET kind=excluded.kind,payload=excluded.payload,
        updated_at=excluded.updated_at,dirty=1,deleted=0
    ''',
      [data['id'], kind, jsonEncode(data), _now()],
    );
    await db.customStatement(
      'UPDATE entities SET deleted=1,dirty=1,updated_at=? WHERE id=?',
      [_now(), removeId],
    );
  });

  Future<List<Map<String, dynamic>>> all(String kind) async {
    final rows = await db
        .customSelect(
          'SELECT payload FROM entities WHERE kind=? AND deleted=0 ORDER BY updated_at DESC',
          variables: [Variable.withString(kind)],
        )
        .get();
    return [
      for (final row in rows)
        jsonDecode(row.read<String>('payload')) as Map<String, dynamic>,
    ];
  }

  Future<Map<String, dynamic>?> get(String id) async {
    final row = await raw(id);
    if (row == null || row['deleted'] == 1) return null;
    return jsonDecode(row['payload'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, Object?>?> raw(String id) async {
    final rows = await db
        .customSelect(
          'SELECT * FROM entities WHERE id=?',
          variables: [Variable.withString(id)],
        )
        .get();
    return rows.isEmpty ? null : rows.first.data;
  }

  Future<void> remove(String id) => db.transaction(
    () => db.customStatement(
      'UPDATE entities SET deleted=1,dirty=1,updated_at=? WHERE id=?',
      [_now(), id],
    ),
  );

  Future<String?> meta(String key) async {
    final rows = await db
        .customSelect(
          'SELECT value FROM metadata WHERE key=?',
          variables: [Variable.withString(key)],
        )
        .get();
    return rows.isEmpty ? null : rows.first.read<String>('value');
  }

  Future<void> setMeta(String key, String value) => db.transaction(
    () => db.customStatement(
      'INSERT INTO metadata(key,value) VALUES(?,?) '
      'ON CONFLICT(key) DO UPDATE SET value=excluded.value',
      [key, value],
    ),
  );

  /// Smaže všechna data v zařízení.
  Future<void> wipeLocal() => db.transaction(() async {
    await db.customStatement('DELETE FROM entities');
    await db.customStatement('DELETE FROM metadata');
  });

  static String _now() => DateTime.now().toUtc().toIso8601String();
}
