import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/measurement.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/bodyweight/bodyweight_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Measurement m(int daysAgo, BodyPart part, double cm) => Measurement(
  id: 'm-${part.name}-$daysAgo',
  date: DateTime(2026, 10, 5).subtract(Duration(days: daysAgo)),
  part: part,
  cm: cm,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('JSON round trip keeps the UTC date and body part', () {
    final entry = m(0, BodyPart.waist, 82.5);
    final json = entry.toJson();
    expect(json['part'], 'waist');
    expect(DateTime.tryParse(json['date'] as String), entry.date.toUtc());

    final parsed = Measurement.fromJson(json);
    expect(parsed.id, entry.id);
    expect(parsed.date.toLocal(), entry.date);
    expect(parsed.part, BodyPart.waist);
    expect(parsed.cm, 82.5);
  });

  test('invalid body part is skipped on load', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = LocalStore(db);
    await store.open();
    await store.put(Kinds.measurement, {
      ...m(0, BodyPart.waist, 90).toJson(),
      'part': 'unknown',
    });
    await store.put(Kinds.measurement, m(1, BodyPart.arm, 32).toJson());

    final state = AppState(store);
    await state.load();
    expect(state.measurements.map((v) => v.part), [BodyPart.arm]);
  });

  test('validMeasurement rejects typos', () {
    expect(validMeasurement(82.5), isTrue);
    expect(validMeasurement(10), isTrue);
    expect(validMeasurement(250), isTrue);
    expect(validMeasurement(9.9), isFalse);
    expect(validMeasurement(250.1), isFalse);
  });

  test('measurementChange compares only the selected part', () {
    expect(measurementChange([], BodyPart.waist), isNull);
    expect(
      measurementChange([m(0, BodyPart.waist, 84)], BodyPart.waist),
      isNull,
    );
    expect(
      measurementChange([
        m(0, BodyPart.waist, 84),
        m(10, BodyPart.chest, 100),
      ], BodyPart.waist),
      isNull,
    );
    expect(
      measurementChange([
        m(0, BodyPart.waist, 84),
        m(10, BodyPart.waist, 85),
      ], BodyPart.waist),
      -1.0,
    );
    expect(
      measurementChange([
        m(0, BodyPart.waist, 84),
        m(35, BodyPart.waist, 86),
        m(90, BodyPart.waist, 90),
      ], BodyPart.waist),
      -2.0,
    );
  });

  test('addMeasurement persists, reloads, deletes and restores', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();

    expect(await state.addMeasurement(BodyPart.waist, 5), isFalse);
    expect(
      await state.addMeasurement(
        BodyPart.waist,
        82.54,
        now: DateTime(2026, 10, 1),
      ),
      isTrue,
    );
    expect(
      await state.addMeasurement(
        BodyPart.arm,
        32.5,
        now: DateTime(2026, 10, 5),
      ),
      isTrue,
    );
    expect(state.measurements.map((v) => v.cm), [32.5, 82.5]);

    final again = AppState(LocalStore(db));
    await again.load();
    expect(again.measurements.map((v) => v.cm), [32.5, 82.5]);
    expect(again.measurements.map((v) => v.part), [
      BodyPart.arm,
      BodyPart.waist,
    ]);

    final entry = state.measurements.first;
    await state.removeMeasurement(entry.id);
    expect(state.measurements, hasLength(1));
    await state.restoreMeasurement(entry);
    await state.restoreMeasurement(entry);
    expect(state.measurements.map((v) => v.id), [
      entry.id,
      state.measurements.last.id,
    ]);
  });

  test('backup restores measurements once; old backups still import', () async {
    final sourceDb = AppDatabase(NativeDatabase.memory());
    addTearDown(sourceDb.close);
    final source = AppState(LocalStore(sourceDb));
    await source.load();
    await source.addMeasurement(
      BodyPart.waist,
      82.5,
      now: DateTime(2026, 10, 1),
    );
    await source.addMeasurement(BodyPart.chest, 98, now: DateTime(2026, 10, 5));
    final backup = source.exportBackup();

    final targetDb = AppDatabase(NativeDatabase.memory());
    addTearDown(targetDb.close);
    final target = AppState(LocalStore(targetDb));
    await target.load();
    expect(target.measurements, isEmpty);

    await target.restoreBackup(backup);
    expect(target.measurements.map((v) => v.part), [
      BodyPart.chest,
      BodyPart.waist,
    ]);
    final reloaded = AppState(LocalStore(targetDb));
    await reloaded.load();
    expect(reloaded.measurements.map((v) => v.cm), [98.0, 82.5]);

    await target.restoreBackup(backup);
    expect(target.measurements, hasLength(2));

    final old = decodeBackup(
      '{"format":"$backupFormat","version":1,"settings":{},"workouts":[]}',
    );
    expect(old.measurements, isEmpty);

    await target.wipeAll();
    expect(target.measurements, isEmpty);
  });

  testWidgets('the page adds a circumference and shows it', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: BodyweightPage(state)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Přidat míru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '82,5');
    await tester.tap(find.text('Uložit'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pas'), findsOneWidget);
    expect(find.text('82,5 cm'), findsOneWidget);
    expect(state.measurements.single.cm, 82.5);
  });
}
