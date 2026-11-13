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
  test('workout search folds diacritics and needs every word', () {
    final w = Workout(
      id: 'w',
      name: 'Nohy',
      startedAt: DateTime(2026, 10, 1),
      note: 'Těžký den',
    )..exercises.add(WorkoutExercise(id: 'e', exerciseId: 'squat'));
    String name(String _) => 'Dřep s činkou';
    expect(matchesWorkout(w, '', name), isTrue);
    expect(matchesWorkout(w, 'drep', name), isTrue);
    expect(matchesWorkout(w, 'tezky nohy', name), isTrue);
    expect(matchesWorkout(w, 'drep bench', name), isFalse);
  });

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
      theme: buildTheme(),
      home: Scaffold(body: home),
    );

    await tester.pumpWidget(app(HistoryPage(state)));
    expect(find.text('Říjen 2026'), findsOneWidget);
    expect(find.text('Září 2026'), findsOneWidget);
    expect(find.text('Rekord'), findsNWidgets(2));

    // Hledání bez diakritiky: „bench“ najde všechny, nesmysl nic.
    await tester.enterText(find.byType(TextField), 'xyz');
    await tester.pump();
    expect(find.text('Nic nenalezeno'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('Září 2026'), findsOneWidget);

    tester.view
      ..physicalSize = const Size(390, 3600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(ExerciseDetailPage(state, 'bench_press')));
    await tester.pumpAndSettle();
    // Rekord a v kalkulačce 1RM zase 82,5 kg na 8 opakování (82,5 × 8).
    expect(find.text('82,5 kg'), findsNWidgets(2));
    expect(find.text('Kalkulačka 1RM'), findsOneWidget);
    // Úroveň síly čeká na tělesnou váhu.
    expect(find.text('Úroveň síly'), findsOneWidget);
    expect(find.textContaining('Zapiš si tělesnou váhu'), findsOneWidget);
    // 82,5 × (1 + 8/30) = 104,5; na 3 opakování 104,5 / 1,1 = 95.
    expect(find.text('95 kg'), findsOneWidget);
    expect(find.text('Odhad 1RM v čase'), findsOneWidget);
    expect(find.textContaining('Lepší než minule'), findsOneWidget);
    expect(find.text('Historie'), findsOneWidget);
    await tester.tap(find.text('4. 10. 2026').last);
    await tester.pumpAndSettle();
    expect(find.text('Zopakovat trénink'), findsOneWidget);
  });
}
