import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('home shows week ring, recent history and the records row', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    final now = DateTime.now();
    await tester.runAsync(() async {
      await state.load();
      for (final (daysAgo, kg) in [(30, 75.0), (20, 80.0), (10, 82.5)]) {
        final at = now.subtract(Duration(days: daysAgo));
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
    });
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(body: HomePage(state)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tento týden'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget); // tréninky vůči cíli
    expect(find.text('0'), findsOneWidget); // série
    expect(find.text('Historie'), findsOneWidget);
    expect(find.text('Vše'), findsOneWidget);
    expect(find.textContaining('Rekord: Bench press 82,5 kg'), findsOneWidget);
    expect(find.text('Program'), findsOneWidget);
    expect(find.text('Tělesná váha'), findsOneWidget);

    await tester.tap(find.text('Vše'));
    await tester.pumpAndSettle();
    expect(find.text('Historie'), findsWidgets);
    expect(find.text('Rekord'), findsNWidgets(2)); // první trénink není rekord
  });

  testWidgets('empty home: one start action, no history section', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: HomePage(state))));
    expect(find.text('Začít trénink'), findsOneWidget);
    expect(find.text('Vybrat program'), findsOneWidget);
    expect(find.text('Historie'), findsNothing);
    expect(find.text('0/3'), findsOneWidget);
  });
}
