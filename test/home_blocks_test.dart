import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/routine_audit.dart';
import 'package:gymzapisnik/core/ids.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/nutrition.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/settings/file_io.dart';
import 'package:gymzapisnik/ui/theme.dart';

class _FakeFiles implements FileIo {
  final saved = <String>[];

  @override
  Future<bool> saveText(String name, String content, String mimeType) async {
    saved.add(name);
    return true;
  }

  @override
  Future<String?> pickText(List<String> extensions) async => null;
}

Workout _workout(DateTime at, String exerciseId, int sets) => Workout(
  id: newId(),
  name: 'T',
  startedAt: at,
  finishedAt: at.add(const Duration(hours: 1)),
  exercises: [
    WorkoutExercise(
      id: newId(),
      exerciseId: exerciseId,
      sets: [
        for (var i = 0; i < sets; i++)
          SetEntry(weight: 60, reps: 8, done: true),
      ],
    ),
  ],
);

void main() {
  test('week coverage counts this week only, secondary at half', () {
    final now = DateTime(2026, 11, 11, 18); // středa
    final sets = weekCoverage([
      _workout(DateTime(2026, 11, 10, 17), 'bench_press', 4),
      // Minulý týden se nepočítá.
      _workout(DateTime(2026, 11, 8, 17), 'bench_press', 10),
    ], now);
    expect(sets['chest'], 4);
    // Tlak na lavici bere triceps jako vedlejší sval.
    expect(sets['triceps'], 2);
    expect(sets.containsKey('back'), isFalse);
  });

  Future<(AppState, _FakeFiles)> home(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    final files = _FakeFiles();
    final now = DateTime.now();
    await tester.runAsync(() async {
      await state.load();
      for (var i = 0; i < AppState.backupEvery; i++) {
        final at = now.subtract(Duration(days: 40 - i));
        await state.startWorkout(now: at);
        (await state.addExercise('bench_press')).sets = [
          SetEntry(weight: 60, reps: 8, done: true),
        ];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
      final yesterday = now.subtract(const Duration(days: 1));
      await state.saveFood(
        FoodEntry(
          id: newId(),
          day: dayKey(yesterday),
          loggedAt: yesterday,
          name: 'Skyr',
          basis: FoodBasis.per100,
          amount: 150,
          values: const Nutrition(kcal: 60, protein: 11, carbs: 4, fat: 0),
        ),
      );
    });
    await tester.binding.setSurfaceSize(const Size(400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(body: HomePage(state, files: files)),
      ),
    );
    await tester.pumpAndSettle();
    return (state, files);
  }

  testWidgets('home: food block re-adds a recent food in one tap', (
    tester,
  ) async {
    final (state, _) = await home(tester);
    final today = dayKey(DateTime.now());
    expect(find.text('Jídlo dnes'), findsOneWidget);
    expect(find.text('Partie tento týden'), findsNothing);
    expect(state.foodsOn(today), isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.text('Skyr'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(state.foodsOn(today).single.name, 'Skyr');
  });

  testWidgets('home: backup reminder saves in one tap and goes away', (
    tester,
  ) async {
    final (state, files) = await home(tester);
    expect(find.text('Ulož si zálohu'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Ulož si zálohu'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(files.saved.single, startsWith('gymzapisnik-zaloha-'));
    expect(state.backupDue, isFalse);
    expect(find.text('Ulož si zálohu'), findsNothing);
  });
}
