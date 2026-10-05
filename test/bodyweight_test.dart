import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/bodyweight.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/bodyweight/bodyweight_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

AppState newState() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return AppState(LocalStore(db));
}

BodyWeight w(int daysAgo, double kg) => BodyWeight(
  id: 'w$daysAgo',
  date: DateTime(2026, 10, 5).subtract(Duration(days: daysAgo)),
  kg: kg,
);

void main() {
  test('changeOver compares with the entry about a month back', () {
    expect(changeOver([]), isNull);
    expect(changeOver([w(0, 80)]), isNull);
    // jen novější záznamy: porovná s nejstarším
    expect(changeOver([w(0, 80), w(10, 81)]), -1.0);
    // starší než 30 dní: použije nejbližší na hranici
    expect(changeOver([w(0, 80), w(20, 79), w(35, 78), w(90, 70)]), 2.0);
  });

  test('validBodyWeight rejects typos', () {
    expect(validBodyWeight(77.5), isTrue);
    expect(validBodyWeight(7), isFalse);
    expect(validBodyWeight(775), isFalse);
  });

  test('add, persist, remove and back up body weight', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await state.load();

    expect(await state.addBodyweight(5), isFalse);
    expect(
      await state.addBodyweight(80.04, now: DateTime(2026, 10, 1)),
      isTrue,
    );
    expect(await state.addBodyweight(79.5, now: DateTime(2026, 10, 5)), isTrue);
    expect(state.bodyweights.map((b) => b.kg), [79.5, 80.0]);

    final again = AppState(LocalStore(db));
    await again.load();
    expect(again.bodyweights.map((b) => b.kg), [79.5, 80.0]);

    final backup = state.exportBackup();
    await state.removeBodyweight(state.bodyweights.first.id);
    expect(state.bodyweights, hasLength(1));
    await state.restoreBackup(backup);
    expect(state.bodyweights.map((b) => b.kg), [79.5, 80.0]);
    // opakovaná obnova nic nezdvojí
    await state.restoreBackup(backup);
    expect(state.bodyweights, hasLength(2));

    await state.wipeAll();
    expect(state.bodyweights, isEmpty);
  });

  testWidgets('card adds a weight and shows it', (tester) async {
    final state = newState();
    await tester.runAsync(state.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(body: BodyweightCard(state)),
      ),
    );
    expect(find.text('Zapiš si váhu a sleduj vývoj'), findsOneWidget);

    await tester.tap(find.byTooltip('Zapsat váhu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '81,5');
    await tester.tap(find.text('Uložit'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();
    expect(find.text('81,5 kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Zapsat váhu'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Uložit'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zadej váhu mezi 20 a 400 kg.'), findsOneWidget);
  });
}
