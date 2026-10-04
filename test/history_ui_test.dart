import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/exercises/exercise_detail_page.dart';
import 'package:gymzapisnik/ui/history/history_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('history lists months and exercise detail shows chart', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      for (final (day, kg) in [(28, 75.0), (2, 80.0), (4, 82.5)]) {
        final at = DateTime(2026, day > 20 ? 9 : 10, day, 17);
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
    });
    Widget app(Widget home) => MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(body: home),
    );

    await tester.pumpWidget(app(HistoryPage(state)));
    expect(find.text('Říjen 2026'), findsOneWidget);
    expect(find.text('Září 2026'), findsOneWidget);
    expect(find.text('1 PR'), findsNWidgets(2));

    await tester.pumpWidget(app(ExerciseDetailPage(state, 'bench_press')));
    await tester.pumpAndSettle();
    expect(find.text('82,5 kg'), findsOneWidget);
    expect(find.text('Odhad 1RM v čase'), findsOneWidget);
    expect(find.textContaining('Lepší než minule'), findsOneWidget);
  });
}
