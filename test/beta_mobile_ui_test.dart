import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/ui/home/home_page.dart';
import 'package:gymzapisnik/ui/nutrition/fridge_page.dart';
import 'package:gymzapisnik/ui/nutrition/nutrition_page.dart';
import 'package:gymzapisnik/ui/workout/workout_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  for (final scale in [1.0, 1.7]) {
    testWidgets('mobile pages fit 375 pixels with text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final state = AppState(LocalStore(db));
      await tester.runAsync(() async {
        await state.load();
        await state.savePantry(const [
          PantryItem('Celozrnný chléb', amount: 250, unit: 'g'),
        ]);
        await state.startWorkout();
        await state.addExercise('bench_press');
      });
      for (final page in <Widget>[
        HomePage(state),
        NutritionPage(state),
        FridgePage(state),
        WorkoutPage(state),
      ]) {
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          debugPrint(details.toString());
          previous?.call(details);
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: page),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        FlutterError.onError = previous;
        expect(
          tester.takeException(),
          isNull,
          reason: '${page.runtimeType}, scale $scale',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
