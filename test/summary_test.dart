import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/stats.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/summary/summary_page.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/widgets/labels.dart';

void main() {
  test('labels', () {
    expect(
      setLabel(ExerciseType.weighted, SetEntry(weight: 77.5, reps: 8)),
      '77,5×8',
    );
    expect(setLabel(ExerciseType.bodyweight, SetEntry(reps: 12)), '12 opak.');
    expect(
      setLabel(ExerciseType.bodyweight, SetEntry(weight: 10, reps: 6)),
      '+10 kg × 6',
    );
    expect(recordLabel(RecordKind.bestE1rm, 101.333), '101,3 kg');
    expect(recordLabel(RecordKind.maxReps, 15), '15 opak.');
    expect(durationLabel(const Duration(minutes: 52)), '52 min');
    expect(durationLabel(const Duration(minutes: 65)), '1 h 05 min');
  });

  testWidgets('summary compares with last time and shows new record', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    late Workout today;
    await tester.runAsync(() async {
      await state.load();
      Future<Workout> log(DateTime at, double kg) async {
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        return (await state.finishActive(
          now: at.add(const Duration(minutes: 50)),
        )).workout!;
      }

      await log(DateTime(2026, 10, 1, 17), 80);
      today = await log(DateTime(2026, 10, 3, 17), 82.5);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: SummaryPage(state, today, justFinished: true),
      ),
    );
    expect(find.text('50 min'), findsOneWidget);
    expect(find.textContaining('Lepší než minule'), findsOneWidget);
    expect(find.text('minule 80×8'), findsOneWidget);
    expect(find.textContaining('Nové osobní rekordy'), findsOneWidget);
    expect(find.textContaining('Max váha: 82,5 kg'), findsOneWidget);
    expect(find.textContaining('(+20 kg)'), findsOneWidget);
  });
}
