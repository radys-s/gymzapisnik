import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/nutrition.dart';
import 'package:gymzapisnik/state/app_state.dart';

Future<AppState> newState() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  await state.acceptConsent(adult: true, guardianConsent: false);
  return state;
}

FoodEntry food(String id, String name, {double amount = 150}) => FoodEntry(
  id: id,
  day: '2026-10-27',
  loggedAt: DateTime(2026, 10, 27, 8),
  name: name,
  basis: FoodBasis.per100,
  amount: amount,
  values: const Nutrition(kcal: 70, protein: 10),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('favorite foods pin first, toggle off and survive reload', () async {
    final state = await newState();
    await state.saveFood(food('a', 'Skyr'));
    await state.saveFood(food('b', 'Ovesné vločky'));
    expect(state.quickFoods.map((f) => f.name), ['Ovesné vločky', 'Skyr']);

    expect(await state.toggleFavoriteFood(state.foods.last), isTrue);
    expect(state.isFavoriteFood(food('x', ' skyr ')), isTrue);
    // Oblíbené první a bez duplicity z nedávných.
    expect(state.quickFoods.map((f) => f.name), ['Skyr', 'Ovesné vločky']);

    final reloaded = AppState(state.store);
    await reloaded.load();
    expect(reloaded.favoriteFoods.single.amount, 150);

    expect(await state.toggleFavoriteFood(food('y', 'Skyr')), isFalse);
    expect(state.favoriteFoods, isEmpty);
  });

  test('favorites are capped and the oldest pin drops out', () async {
    final state = await newState();
    for (var i = 0; i < maxFavoriteFoods + 2; i++) {
      await state.toggleFavoriteFood(food('f$i', 'Jídlo $i'));
    }
    final names = state.favoriteFoods.map((f) => f.name).toList();
    expect(names, hasLength(maxFavoriteFoods));
    expect(names.first, 'Jídlo ${maxFavoriteFoods + 1}');
    expect(names, isNot(contains('Jídlo 0')));
  });

  test(
    'favorites round trip through backup, broken ones are rejected',
    () async {
      final source = await newState();
      await source.toggleFavoriteFood(food('a', 'Skyr', amount: 200));
      final json = source.exportBackup();
      final target = await newState();
      await target.restoreBackup(json);
      expect(target.favoriteFoods.single.name, 'Skyr');
      expect(target.favoriteFoods.single.amount, 200);

      final broken = json.replaceFirst(
        RegExp(r'"amount":\s*200(\.0)?'),
        '"amount": -5',
      );
      expect(broken, isNot(json));
      final other = await newState();
      await expectLater(other.restoreBackup(broken), throwsFormatException);
      expect(validFavoriteFood({'name': 'x'}), isFalse);
    },
  );
}
