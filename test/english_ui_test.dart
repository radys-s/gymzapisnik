import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';

Future<AppState> _fresh(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> _tapAndSave(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, AppState state) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GymApp(state));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('english UI shows translated onboarding flow', (tester) async {
    final state = await _fresh(tester);
    await _open(tester, state);

    await _tapAndSave(tester, find.text('English'));

    expect(find.text('Gym Log'), findsWidgets);
    expect(find.text('Know what to train every day'), findsOneWidget);
    await _tapAndSave(tester, find.text('Start'));

    await tester.tap(find.text('I agree to the terms of use'));
    await tester.tap(find.text('I am 18 or older'));
    await tester.pump();
    await _tapAndSave(tester, find.text('Continue').hitTestable());

    expect(find.text('How do you want to train?'), findsOneWidget);
  });
}
