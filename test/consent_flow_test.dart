import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';

void main() {
  testWidgets('minor needs guardian consent before entering the app', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    await tester.pumpWidget(GymApp(state));

    FilledButton button() =>
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button().onPressed, isNull);

    await tester.tap(find.text('Souhlasím s podmínkami používání'));
    await tester.tap(find.text('Je mi méně než 18 let'));
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.tap(find.text('Mám souhlas rodiče nebo zákonného zástupce'));
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.runAsync(() async {
      await tester.tap(find.text('Pokračovat'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    expect(find.text('Cvičení'), findsWidgets);
    expect(state.profile.adult, isFalse);
    expect(state.profile.restrictWeightLoss, isTrue);

    final reloaded = AppState(LocalStore(db));
    await tester.runAsync(reloaded.load);
    expect(reloaded.profile.hasValidConsent, isTrue);
  });
}
