import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/progression.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/coach/start_weight.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';

const _bench = PlannedExercise('bench_press', sets: 3, repMin: 5, repMax: 8);

Future<AppState> _state(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

void main() {
  test('first time on a barbell starts on the empty bar', () {
    final start = startLoad('bench_press', PlanLevel.beginner)!;
    expect(start.kg, 20);
    expect(start.label, 'prázdné ose (20 kg)');
    expect(startLoad('bench_press', PlanLevel.advanced)!.kg, 30);
    expect(
      startLoad('lateral_raise', PlanLevel.beginner)!.label,
      'jednoručkách 4 kg na ruku',
    );
    expect(startLoad('custom_x', PlanLevel.beginner), isNull);

    final s = suggest(_bench, ExerciseType.weighted, const [], start: start);
    expect(s.weight, 20);
    expect(s.reps, 5);
    // Nápověda sedí s předvyplněním: rozsah, ne jen horní hranice.
    expect(s.reason, contains('5–8 opakování'));
    expect(s.reason, contains('prázdné ose'));

    final bodyweight = suggest(
      _bench,
      ExerciseType.bodyweight,
      const [],
      start: start,
    );
    expect(bodyweight.weight, 0);
  });

  testWidgets('planned first workout is prefilled with start weights', (
    tester,
  ) async {
    final state = await _state(tester);
    final split = splitTemplates.first;
    await tester.runAsync(() async {
      await state.setSplit(split.id);
      await state.startSplitDay(0);
    });
    final weighted = state.active!.exercises.where(
      (e) => state.typeOf(e.exerciseId) == ExerciseType.weighted,
    );
    expect(weighted, isNotEmpty);
    for (final e in weighted) {
      expect(e.sets.first.weight, greaterThan(0), reason: e.exerciseId);
    }
  });

  testWidgets('edited set carries to untouched later sets', (tester) async {
    final state = await _state(tester);
    late WorkoutExercise bench;
    await tester.runAsync(() async {
      await state.startWorkout();
      bench = await state.addExercise('bench_press');
    });
    bench.sets = [
      SetEntry(weight: 20, reps: 5),
      SetEntry(weight: 20, reps: 5),
      SetEntry(weight: 25, reps: 5),
      SetEntry(weight: 20, reps: 5, done: true),
    ];
    final first = bench.sets.first;
    final followers = state.followersOf(bench.sets.first);
    expect(followers, hasLength(1));
    // Mezistav při psaní („2“) nesmí chytit další sérii s dvojkou.
    first.weight = 2;
    bench.sets[2].weight = 2;
    expect(state.carryForward(first, followers), 1);
    first.weight = 30;
    expect(state.carryForward(first, followers), 1);
    expect([for (final s in bench.sets) s.weight], [30, 30, 2, 20]);
    // Beze změny nic nepřepíše.
    expect(state.carryForward(first, followers), 0);
  });

  testWidgets('finish without a confirmed set offers continue or discard', (
    tester,
  ) async {
    final state = await _state(tester);
    await tester.runAsync(() async {
      await state.startWorkout();
      final bench = await state.addExercise('bench_press');
      bench.sets = [
        SetEntry(weight: 20, reps: 5),
        SetEntry(weight: 20, reps: 5),
      ];
      await state.saveActive();
    });
    tester.view
      ..physicalSize = const Size(390, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: WorkoutPage(state),
      ),
    );
    // Potvrzení série je pro čtečku samostatné tlačítko s akcí.
    final semantics = tester.ensureSemantics();
    final confirm = tester.getSemantics(
      find.bySemanticsLabel('Potvrdit sérii').first,
    );
    expect(confirm.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    semantics.dispose();

    // Dvojklik neotevře dva dialogy.
    await tester.tap(find.text('Dokončit'));
    await tester.tap(find.text('Dokončit'));
    await tester.pumpAndSettle();
    expect(find.text('Zatím žádná potvrzená série'), findsOneWidget);
    expect(find.text('Ukládám…'), findsNothing);
    await tester.tap(find.text('Pokračovat'));
    await tester.pumpAndSettle();
    expect(state.active, isNotNull);

    // S jednou potvrzenou sérií ukáže, kolik je hotovo.
    state.active!.exercises.first.sets.first.done = true;
    await tester.tap(find.text('Dokončit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Hotovo 1 z 2 sérií. Nepotvrzené se neuloží.'),
      findsOneWidget,
    );
    expect(find.text('Ukládám…'), findsNothing);
  });
}
