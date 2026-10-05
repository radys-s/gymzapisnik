import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/settings/legal_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  test('backup reminder after 10 new workouts, cleared by a backup', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    expect(state.backupDue, isFalse);

    for (var i = 0; i < 10; i++) {
      final at = DateTime(2026, 9, 1 + i);
      await state.startWorkout(now: at);
      final e = await state.addExercise('bench_press');
      e.sets = [
        for (var j = 0; j < 1; j++)
          (await state.addSet(e))
            ..reps = 5
            ..done = true,
      ];
      await state.finishActive(now: at.add(const Duration(hours: 1)));
    }
    expect(state.workouts, hasLength(10));
    expect(state.backupDue, isTrue);

    await state.markBackedUp();
    expect(state.backupDue, isFalse);

    // záloha není součástí nastavení v souboru
    expect(state.exportBackup(), isNot(contains('backupCount')));

    final again = AppState(LocalStore(db));
    await again.load();
    expect(again.backupDue, isFalse);
  });

  testWidgets('legal page shows privacy sections', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.dark), home: const LegalPage()),
    );
    expect(find.text('Jaká data a kde'), findsOneWidget);
    expect(find.textContaining('jen v tomto zařízení'), findsOneWidget);
  });
}
