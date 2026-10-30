import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/dashboard.dart';
import 'package:gymzapisnik/domain/history.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

final monday = DateTime(2026, 10, 5, 12);

Future<AppState> newState(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> show(WidgetTester tester, AppState state) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(body: HomePage(state, now: () => monday)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new user sees a train-today mission with default goal', (
    tester,
  ) async {
    final state = await newState(tester);
    await show(tester, state);
    expect(state.weekGoal, 3);
    expect(find.text('Tento týden 0 z 3'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget); // kruh týdne
  });

  testWidgets('trained today: mission done, weekly goal follows settings', (
    tester,
  ) async {
    final state = await newState(tester);
    await tester.runAsync(() async {
      final now = monday;
      await state.startWorkout(now: now.subtract(const Duration(minutes: 30)));
      final e = await state.addExercise('bench_press');
      e.sets = [SetEntry(weight: 80, reps: 8, done: true)];
      await state.finishActive(now: now);
      await state.setWeekGoal(1);
    });
    await show(tester, state);
    expect(find.text('Týdenní cíl splněn'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('1 týden'), findsOneWidget); // streak chip

    await tester.runAsync(() => state.setWeekGoal(null));
    await tester.pumpAndSettle();
    expect(find.text('Dnes máš hotovo'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  test('week goal follows split until set manually', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();
    await state.setSplit('upper_lower');
    expect(state.weekGoal, 4);
    await state.setWeekGoal(2);
    expect(state.weekGoal, 2);
    await state.setWeekGoal(null);
    expect(state.weekGoal, 4);
  });

  test('recap lines compare volume with last week and count records', () {
    const cur = WeekSummary(2, 20, 1120);
    const prev = WeekSummary(3, 30, 1000);
    expect(recapLines(cur, prev, 0), ['Objem +12 % oproti minulému týdnu.']);
    expect(recapLines(const WeekSummary(1, 5, 500), prev, 1), [
      'Objem −50 % oproti minulému týdnu.',
      'Nový rekord u 1 cviku.',
    ]);
    expect(recapLines(cur, const WeekSummary(0, 0, 0), 3), [
      'Nové rekordy u 3 cviků.',
    ]);
    expect(recapLines(cur, cur, 0), ['Objem stejný jako minulý týden.']);
  });
}
