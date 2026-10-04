import 'package:drift/drift.dart';

import 'connection.dart';

part 'database.g.dart';

/// Každá entita (trénink, cvik, profil…) je jeden JSON dokument.
/// Sloupce dirty/deleted/conflict/remote_revision slouží pozdější synchronizaci.
class Entities extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  TextColumn get updatedAt => text().named('updated_at')();
  IntColumn get dirty => integer().withDefault(const Constant(1))();
  IntColumn get deleted => integer().withDefault(const Constant(0))();
  IntColumn get conflict => integer().withDefault(const Constant(0))();
  IntColumn get remoteRevision =>
      integer().named('remote_revision').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Metadata extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Entities, Metadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? openDatabaseConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS entities_kind ON entities(kind)',
      );
    },
  );
}
