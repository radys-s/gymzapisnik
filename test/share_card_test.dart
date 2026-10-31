import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/summary/share_card.dart';
import 'package:gymzapisnik/ui/summary/summary_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('summary shows workout number, week and share card', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout last;
    await tester.runAsync(() async {
      await state.load();
      for (final day in [12, 14]) {
        final at = DateTime(2026, 10, day, 17);
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: 60.0 + day, reps: 8, done: true)];
        last = (await state.finishActive(
          now: at.add(const Duration(minutes: 55)),
        )).workout!;
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: SummaryPage(state, last, justFinished: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2. trénink'), findsOneWidget);
    expect(find.text('Týden 2/${state.weekGoal}'), findsOneWidget);

    await tester.tap(find.byTooltip('Sdílet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Trénink č. 2'), findsOneWidget);
    expect(find.text('Sdílet obrázek'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ShareCard),
        matching: find.textContaining('Nové osobní rekordy: '),
      ),
      findsOneWidget,
    );
  });
}
