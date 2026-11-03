import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/push.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/coach/push_widgets.dart';
import 'package:gymzapisnik/ui/summary/summary_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('summary saves the rating', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout today;
    await tester.runAsync(() async {
      await state.load();
      final at = DateTime(2026, 10, 3, 17);
      await state.startWorkout(now: at);
      final e = await state.addExercise('bench_press');
      e.sets = [SetEntry(weight: 80, reps: 8, done: true)];
      today = (await state.finishActive(
        now: at.add(const Duration(minutes: 50)),
      )).workout!;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: SummaryPage(state, today, justFinished: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jak to šlo?'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Lehký'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(ratingOf(state.workouts.first), WorkoutRating.easy);
    expect(find.text(WorkoutRating.easy.hint), findsOneWidget);
  });

  testWidgets('week focus card sets a goal from the sheet', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime(2026, 11, 4, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: ListenableBuilder(
            listenable: state,
            builder: (_, _) => WeekFocusCard(state: state, now: now),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nastav si cíl týdne'));
    await tester.pumpAndSettle();
    expect(find.text('Cíl na tento týden'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Pravidelnost'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(state.weekFocus(now)?.kind, FocusKind.consistency);
    expect(find.text('Cíl týdne'), findsOneWidget);
    expect(find.textContaining('Zbývá'), findsOneWidget);
  });
}
