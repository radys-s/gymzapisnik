import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/achievements.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/coach/achievements_page.dart';
import 'package:gymzapisnik/ui/summary/summary_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

ExerciseType _type(String id) =>
    id == 'pull_up' ? ExerciseType.bodyweight : ExerciseType.weighted;

Workout _w(
  String id,
  DateTime start, {
  int minutes = 45,
  List<(String, double, int)> sets = const [('bench_press', 60, 8)],
}) =>
    Workout(
        id: id,
        name: id,
        startedAt: start,
        finishedAt: start.add(Duration(minutes: minutes)),
      )
      ..exercises = [
        for (final (ex, kg, reps) in sets)
          WorkoutExercise(
            id: '$id-$ex-$kg-$reps',
            exerciseId: ex,
            sets: [
              SetEntry(weight: kg, reps: reps, done: true),
              SetEntry(weight: 20, reps: 10, done: true, warmup: true),
            ],
          ),
      ];

BadgeState _get(List<BadgeState> all, String id) =>
    all.firstWhere((b) => b.badge.id == id);

void main() {
  test('ids are unique and targets positive', () {
    expect(achievements.map((a) => a.id).toSet().length, achievements.length);
    expect(achievements.every((a) => a.target > 0), isTrue);
  });

  test('empty history unlocks nothing', () {
    final all = computeBadges(const [], _type);
    expect(all.where((b) => b.unlocked), isEmpty);
    expect(_get(all, 'w10').progress, 0);
  });

  test('first workout, records, week run and habits', () {
    // Pondělí 5. 10. 2026.
    final mon = DateTime(2026, 10, 5, 18);
    final history = [
      _w('a', DateTime(2026, 10, 5, 6, 30)), // ranní
      _w(
        'b',
        mon.add(const Duration(days: 2)),
        minutes: 75,
        sets: [('bench_press', 62.5, 8), ('pull_up', 0, 10)],
      ),
      _w(
        'c',
        mon.add(const Duration(days: 4)),
        sets: [('bench_press', 62.5, 8), ('pull_up', 0, 12)],
      ),
      // Další týden, pozdě večer.
      _w('d', DateTime(2026, 10, 12, 21, 15)),
      // Rozepsaný trénink se nepočítá.
      Workout(id: 'x', name: 'x', startedAt: DateTime(2026, 10, 13)),
    ];
    final all = computeBadges(history, _type);
    expect(_get(all, 'w1').workoutId, 'a');
    expect(_get(all, 'w1').value, 4);
    expect(_get(all, 'early').workoutId, 'a');
    expect(_get(all, 'long').workoutId, 'b');
    expect(_get(all, 'ww3').workoutId, 'c');
    expect(_get(all, 'r2').workoutId, 'd');
    expect(_get(all, 'late').workoutId, 'd');
    // Bench 62,5 v „b“: max váha + 1RM = 2 rekordy; shyby poprvé nic.
    // „c“: shyby 12 > 10 = 1 rekord; bench stejně = nic.
    expect(_get(all, 'p1').workoutId, 'b');
    expect(_get(all, 'p10').value, 3);
    expect(_get(all, 's100').value, 6);
    expect(_get(all, 'w10').unlocked, isFalse);
    expect(_get(all, 'w10').progress, closeTo(0.4, 1e-9));
  });

  test('week run breaks after an empty week; volume in tons', () {
    final history = [
      _w('a', DateTime(2026, 9, 7, 18), sets: [('squat', 100, 10)]),
      _w('b', DateTime(2026, 9, 14, 18), sets: [('squat', 100, 10)]),
      // Týden 21. 9. vynechaný.
      _w('c', DateTime(2026, 9, 28, 18), sets: [('squat', 100, 10)]),
    ];
    final all = computeBadges(history, _type);
    expect(_get(all, 'r2').value, 2);
    expect(_get(all, 'r4').unlocked, isFalse);
    // 3 × 1000 kg = 3 t (rozcvička se nepočítá).
    expect(_get(all, 'v10').value, 3);
  });

  test('first time at 0 kg makes no record; week run over new year', () {
    final all = computeBadges([
      _w('a', DateTime(2026, 12, 28, 18), sets: [('bench_press', 0, 10)]),
      _w('b', DateTime(2027, 1, 4, 18), sets: [('bench_press', 20, 10)]),
      _w('c', DateTime(2027, 1, 11, 18), sets: [('bench_press', 22.5, 10)]),
    ], _type);
    // „b“ je první nenulový výkon, rekordy až v „c“ (váha + 1RM).
    expect(_get(all, 'p1').workoutId, 'c');
    expect(_get(all, 'p10').value, 2);
    expect(_get(all, 'r2').workoutId, 'b');
    expect(_get(all, 'r2').value, 3);
  });

  test('overnight workout does not count as long', () {
    final all = computeBadges([
      _w('a', DateTime(2026, 10, 5, 18), minutes: 600),
    ], _type);
    expect(_get(all, 'long').unlocked, isFalse);
  });

  testWidgets('page lists badges and summary shows new ones', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout saved;
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.startWorkout(now: DateTime(2026, 10, 5, 6));
      final entry = await state.addExercise('bench_press');
      entry.sets.single
        ..weight = 60
        ..reps = 8;
      await state.toggleDone(entry.sets.single);
      saved = (await state.finishActive(now: DateTime(2026, 10, 5, 6, 50)))
          .workout!;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: AchievementsPage(state),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2 z ${achievements.length}'), findsOneWidget);
    expect(find.text('Pravidelnost'), findsOneWidget);
    await tester.tap(find.text('První krok'));
    await tester.pumpAndSettle();
    expect(find.text('Odemčeno 5. 10. 2026'), findsOneWidget);
    // Odemčený odznak jde sdílet jako obrázek (náhled karty v listu).
    await tester.tap(find.text('Sdílet odznak'));
    await tester.pumpAndSettle();
    expect(find.byType(BadgeShareCard), findsOneWidget);
    expect(find.text('ODZNAK ODEMČEN'), findsOneWidget);
    expect(find.text('Sdílet odznak'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(BadgeShareCard))).pop();
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: SummaryPage(state, saved, justFinished: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nové odznaky (2)'), findsOneWidget);
    expect(find.text('Ranní ptáče'), findsOneWidget);
  });
}
