import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

/// Skutečné písmo místo testovacího Ahem (to má každý znak čtverec), ať
/// šířky tlačítek odpovídají telefonu.
Future<void> _realFonts() async {
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
  final loader = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('$artifacts/material_fonts/Roboto-$w.ttf')
        .readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
  final barlow = FontLoader('Barlow Condensed');
  for (final w in ['SemiBold', 'Bold', 'ExtraBold']) {
    final bytes = File('assets/fonts/BarlowCondensed-$w.ttf').readAsBytesSync();
    barlow.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await barlow.load();
}

void main() {
  setUpAll(_realFonts);

  // Tlačítka pauzy se mačkají mezi každou sérií: ani na úzkém telefonu
  // nesmí být menší než 44 px.
  testWidgets('rest bar buttons keep 44 px on a 360 px phone', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 780)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout();
      final entry = await state.addExercise('bench_press');
      entry.sets = [
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 80, reps: 8),
      ];
      await state.toggleDone(entry.sets.first);
    });
    expect(state.restEndsAt, isNotNull);

    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: WorkoutPage(state)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    for (final label in ['−15', '+15', 'Přeskočit']) {
      final button = find.ancestor(
        of: find.text(label),
        matching: find.byType(TextButton),
      );
      // getRect počítá i se zmenšením přes FittedBox.
      final rect = tester.getRect(button);
      expect(rect.height, greaterThanOrEqualTo(minTap), reason: label);
      expect(rect.width, greaterThanOrEqualTo(minTap), reason: label);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}
