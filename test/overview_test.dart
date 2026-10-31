import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/overview.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/stats/stats_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

ExerciseType _type(String id) => ExerciseType.weighted;

Workout _w(String id, DateTime start, {int minutes = 60, double kg = 100}) =>
    Workout(
        id: id,
        name: id,
        startedAt: start,
        finishedAt: start.add(Duration(minutes: minutes)),
      )
      ..exercises = [
        WorkoutExercise(
          id: id,
          exerciseId: 'squat',
          sets: [
            SetEntry(weight: kg, reps: 10, done: true),
            SetEntry(weight: 40, reps: 10, done: true, warmup: true),
          ],
        ),
      ];

void main() {
  final now = DateTime(2026, 10, 16, 18);

  test('totals skip running and overlong workouts in time', () {
    final t = totalsOf([
      _w('a', DateTime(2026, 10, 1, 18)),
      _w('b', DateTime(2026, 10, 2, 18), minutes: 600),
      Workout(id: 'x', name: 'x', startedAt: now),
    ], _type);
    expect(t.workouts, 2);
    expect(t.sets, 2);
    expect(t.volumeKg, 2000);
    expect(t.time, const Duration(hours: 1));
  });

  test('weekly buckets end with current week; months split', () {
    final list = [
      _w('a', DateTime(2026, 10, 12, 18)),
      _w('b', DateTime(2026, 10, 14, 18)),
      _w('c', DateTime(2026, 9, 30, 18)),
    ];
    final weeks = weeklyBuckets(list, now, _type);
    expect(weeks, hasLength(12));
    expect(weeks.last.monday, DateTime(2026, 10, 12));
    expect(weeks.last.totals.workouts, 2);
    expect(weeks[weeks.length - 3].totals.workouts, 1);
    final oct = totalsOf(
      list,
      _type,
      from: monthStart(now),
      to: monthStart(now, 1),
    );
    expect(oct.workouts, 2);
    expect(monthStart(DateTime(2026, 1, 5), -1), DateTime(2025, 12));
    expect(
      sameTimeLastMonth(DateTime(2026, 3, 31, 9)),
      DateTime(2026, 2, 28, 9),
    );
    expect(sameTimeLastMonth(DateTime(2026, 1, 15)), DateTime(2025, 12, 15));
    expect(dailyCounts(list)[DateTime(2026, 10, 14)], 1);
  });

  testWidgets('stats page renders at 320 px with big text', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout(now: DateTime(2026, 10, 14, 17));
      final e = await state.addExercise('squat');
      e.sets = [SetEntry(weight: 100, reps: 5, done: true)];
      await state.finishActive(now: DateTime(2026, 10, 14, 18));
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: StatsPage(state, now: () => now),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tento měsíc (říjen)'), findsOneWidget);
    expect(
      find.text('Za 16 týdnů 1 trénink, dny s tréninkem: 1'),
      findsOneWidget,
    );
    expect(find.text('Série na partii (30 dní)'), findsOneWidget);
  });
}
