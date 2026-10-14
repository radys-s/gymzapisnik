import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/tips.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/coach/growth_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

WorkoutExercise _ex(String id, int done, {int warmup = 0, int open = 0}) =>
    WorkoutExercise(
      id: id,
      exerciseId: id,
      sets: [
        for (var i = 0; i < done; i++)
          SetEntry(weight: 50, reps: 8, done: true),
        for (var i = 0; i < warmup; i++)
          SetEntry(weight: 20, reps: 10, done: true, warmup: true),
        for (var i = 0; i < open; i++) SetEntry(weight: 50, reps: 8),
      ],
    );

void main() {
  test('tips cycle through advice and motivation', () {
    expect(tipAt(0).kind, 'Rada');
    expect(tipAt(0).text, trainingTips.first);
    expect(tipAt(trainingTips.length).kind, 'Motivace');
    final total = trainingTips.length + motivationLines.length;
    expect(tipAt(total).text, tipAt(0).text);
    expect(tipAt(-1).text, isNotEmpty);
    // Dávkování bílkovin jen pro dospělé.
    final all = trainingTips.length + motivationLines.length;
    final minor = {for (var i = 0; i < all; i++) tipAt(i).text};
    expect(minor.intersection(adultTips.toSet()), isEmpty);
    final adult = {
      for (var i = 0; i < all + adultTips.length; i++)
        tipAt(i, adult: true).text,
    };
    expect(adult, containsAll(adultTips));
  });

  test('weekly hard sets count working sets per group, last 7 days', () {
    final now = DateTime(2026, 10, 14, 18);
    final recent =
        Workout(
            id: 'a',
            name: 'A',
            startedAt: now.subtract(const Duration(days: 2)),
            finishedAt: now.subtract(const Duration(days: 2)),
          )
          ..exercises = [
            _ex('bench_press', 3, warmup: 2, open: 1),
            _ex('lateral_raise', 4),
            _ex('deadlift', 2), // bedra, hýždě, hamstringy
            _ex('mine', 2),
          ];
    final old = Workout(
      id: 'b',
      name: 'B',
      startedAt: now.subtract(const Duration(days: 9)),
      finishedAt: now.subtract(const Duration(days: 9)),
    )..exercises = [_ex('bench_press', 5)];
    final running = Workout(id: 'c', name: 'C', startedAt: now)
      ..exercises = [_ex('bench_press', 5)];
    final sets = weeklyHardSets(
      [recent, old, running],
      now,
      (id) => id == 'mine' ? 'Ramena' : '',
    );
    expect(sets, {
      'chest': 3,
      'shoulders': 6,
      'back': 2, // mrtvý tah jen jednou, ne i hýždě a nohy
    });
  });

  testWidgets('growth page shows volume and age-appropriate food advice', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: false, guardianConsent: true);
    });
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.light), home: GrowthPage(state)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tvůj týden'), findsOneWidget);
    expect(find.text('Hrudník'), findsOneWidget);
    expect(find.textContaining('nehubni'), findsOneWidget);
    expect(find.textContaining('přebytek'), findsNothing);
  });
}
