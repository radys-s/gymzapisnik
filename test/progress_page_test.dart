import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/missions.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/dashboard.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/progress/progress_page.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/widgets/labels.dart';

Future<AppState> _state(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> _show(WidgetTester tester, Widget page) async {
  tester.view
    ..physicalSize = const Size(390, 1600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.dark),
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('mission copy speaks about the last workout', () {
    const m = Mission(
      kind: MissionKind.trainToday,
      done: 1,
      goal: 3,
      remaining: 2,
      daysLeft: 4,
    );
    expect(MissionCopy.title(m), 'Tento týden 1 z 3');
    expect(MissionCopy.subtitle(m), startsWith('První trénink'));
    expect(MissionCopy.subtitle(m, daysSince: 1), startsWith('Minule včera'));
    expect(
      MissionCopy.subtitle(m, daysSince: 3),
      'Minule před 3 dny, máš odpočinuto.',
    );
    expect(MissionCopy.subtitle(m, daysSince: 10), contains('přes týden'));
    expect(MissionCopy.subtitle(m, daysSince: 0), contains('Dnes už'));
  });

  test('workout length estimate and greeting', () {
    expect(workoutMinutes(16), 45);
    expect(workoutMinutes(0), 5);
    expect(greeting(DateTime(2026, 1, 1, 7)), 'Dobré ráno');
    expect(greeting(DateTime(2026, 1, 1, 14)), 'Dobré odpoledne');
    expect(greeting(DateTime(2026, 1, 1, 20)), 'Dobrý večer');
    expect(greeting(DateTime(2026, 1, 1, 2)), 'Dobrý večer');
    expect(greeting(DateTime(2026, 1, 1, 5)), 'Dobré ráno');
    expect(greeting(DateTime(2026, 1, 1, 9)), 'Dobré dopoledne');
    expect(greeting(DateTime(2026, 1, 1, 12)), 'Dobré odpoledne');
    expect(greeting(DateTime(2026, 1, 1, 18)), 'Dobrý večer');
  });

  testWidgets('progress tab: empty state before the first workout', (
    tester,
  ) async {
    final state = await _state(tester);
    await _show(tester, ProgressPage(state));
    expect(find.text('Pokrok začne prvním tréninkem'), findsOneWidget);
    expect(find.text('Statistiky'), findsOneWidget);
    expect(find.text('Tělesná váha'), findsOneWidget);
    expect(find.text('Rady pro růst svalů'), findsOneWidget);
  });

  testWidgets('progress tab: curve, records and totals after workouts', (
    tester,
  ) async {
    final state = await _state(tester);
    final now = DateTime.now();
    await tester.runAsync(() async {
      for (final (daysAgo, kg) in [(30, 75.0), (20, 80.0), (10, 82.5)]) {
        final at = now.subtract(Duration(days: daysAgo));
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
    });
    await _show(tester, ProgressPage(state));
    expect(find.text('Pokrok začne prvním tréninkem'), findsNothing);
    expect(find.text('Bench press'), findsWidgets); // křivka i rekordy
    expect(find.textContaining('Odhad 1RM'), findsOneWidget);
    expect(find.textContaining('Rekord: Bench press 82,5 kg'), findsOneWidget);
    // Souhrn: 3 tréninky a 3 série, v přehledu historie taky 3.
    expect(find.text('tréninky'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(3));
  });

  testWidgets('home: one "Jiný trénink" button opens both options', (
    tester,
  ) async {
    final state = await _state(tester);
    await tester.runAsync(() => state.setSplit('full_body_3'));
    await _show(tester, HomePage(state));
    expect(find.text('Volný trénink'), findsNothing);
    expect(find.text('Sestavit trénink'), findsNothing);
    expect(find.textContaining('cviků · ~'), findsOneWidget); // světla
    await tester.tap(find.text('Jiný trénink'));
    await tester.pumpAndSettle();
    expect(find.text('Volný trénink'), findsOneWidget);
    expect(find.text('Sestavit podle partií'), findsOneWidget);
  });

  testWidgets('home on a planned rest day points to the next one', (
    tester,
  ) async {
    final state = await _state(tester);
    await tester.runAsync(() async {
      await state.setSplit('full_body_3');
      await state.setFrequency(days: [1, 3, 5]);
    });
    // Sobota 31. 10. 2026: v plánu volno, další trénink v pondělí.
    await _show(tester, HomePage(state, now: () => DateTime(2026, 10, 31, 15)));
    expect(find.textContaining('Příště · pondělí'), findsOneWidget);
    expect(find.text('Začít i dnes'), findsOneWidget);
    expect(find.text('Dnes volno podle plánu'), findsOneWidget);
    // Ve středu se trénuje: zase „Dnes“.
    await _show(tester, HomePage(state, now: () => DateTime(2026, 10, 28, 15)));
    expect(find.textContaining('Dnes · Full body'), findsOneWidget);
  });
}
