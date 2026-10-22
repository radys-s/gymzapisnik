import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/off_client.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/nutrition.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/nutrition/nutrition_page.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeLookup implements ProductLookup {
  LookupResult result;
  final calls = <String>[];
  FakeLookup(this.result);

  @override
  Future<LookupResult> byBarcode(String barcode) async {
    calls.add(barcode);
    return result;
  }
}

AppState newState({ProductLookup? lookup}) {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return AppState(LocalStore(db), lookup: lookup);
}

FoodEntry food(
  String id, {
  String day = '2026-10-05',
  FoodBasis basis = FoodBasis.per100,
  double amount = 150,
  Nutrition values = const Nutrition(kcal: 200, protein: 10, carbs: 20, fat: 5),
  String name = 'Jogurt',
}) => FoodEntry(
  id: id,
  day: day,
  loggedAt: DateTime(2026, 10, 5, 12),
  name: name,
  basis: basis,
  amount: amount,
  values: values,
);

const nutella = {
  'code': '3017620422003',
  'status': 'success',
  'product': {
    'product_name': 'Nutella',
    'brands': 'Nutella, Ferrero',
    'serving_size': '15 g',
    'serving_quantity': 15,
    'nutriments': {
      'energy-kcal_100g': 539,
      'proteins_100g': 6.3,
      'carbohydrates_100g': 57.5,
      'fat_100g': 30.9,
    },
  },
};

void main() {
  group('domain', () {
    test('per 100 g scales by amount, per serving by count', () {
      final a = food('a');
      expect(a.eaten.kcal, 300);
      expect(a.eaten.protein, 15);
      final b = food('b', basis: FoodBasis.perServing, amount: 2);
      expect(b.eaten.kcal, 400);
    });

    test('missing value stays missing, zero stays zero', () {
      final e = food(
        'a',
        values: const Nutrition(kcal: 100, protein: 0),
        amount: 200,
      );
      expect(e.eaten.protein, 0);
      expect(e.eaten.carbs, isNull);
      final t = totalsOf([e, food('b')]);
      expect(t.kcal, 500);
      expect(t.carbsMissing, isTrue);
      expect(t.proteinMissing, isFalse);
      expect(totalsOf([food('c')]).fatMissing, isFalse);
    });

    test('json round trip keeps nulls', () {
      final e = food('a', values: const Nutrition(kcal: 0, fat: 3));
      final back = FoodEntry.fromJson(
        jsonDecode(jsonEncode(e.toJson())) as Map<String, dynamic>,
      );
      expect(back.values.kcal, 0);
      expect(back.values.protein, isNull);
      expect(back.values.fat, 3);
      expect(back.basis, FoodBasis.per100);
    });

    test('dayKey and parseDayKey', () {
      expect(dayKey(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(parseDayKey('2026-02-30'), isNull);
      expect(parseDayKey('abc'), isNull);
      expect(parseDayKey('2026-10-06'), DateTime(2026, 10, 6));
    });

    test('validation', () {
      String? v({
        String name = 'x',
        double? amount = 100,
        FoodBasis basis = FoodBasis.per100,
        Nutrition values = const Nutrition(kcal: 10),
      }) => validateFood(
        name: name,
        amount: amount,
        basis: basis,
        values: values,
      );
      expect(v(), isNull);
      expect(v(name: ' '), isNotNull);
      expect(v(amount: 0), isNotNull);
      expect(v(amount: null), isNotNull);
      expect(v(values: const Nutrition()), isNotNull);
      expect(v(values: const Nutrition(kcal: 0)), isNull);
      expect(
        v(values: const Nutrition(protein: 60, carbs: 60)),
        isNotNull,
        reason: 'víc než 100 g živin na 100 g',
      );
      expect(
        v(
          basis: FoodBasis.perServing,
          values: const Nutrition(protein: 60, carbs: 60),
        ),
        isNull,
      );
    });

    test('barcode checksum', () {
      expect(validBarcode('3017620422003'), isTrue);
      expect(validBarcode('3017620422004'), isFalse);
      expect(validBarcode('12345670'), isTrue);
      expect(validBarcode('0123'), isFalse);
      expect(validBarcode('30176204220a3'), isFalse);
    });
  });

  group('Open Food Facts', () {
    test('parses per-100 values, serving and czech name preference', () {
      final r = parseLookupResponse('3017620422003', 200, jsonEncode(nutella));
      final p = (r as LookupFound).product;
      expect(p.name, 'Nutella');
      expect(p.brand, 'Nutella');
      expect(p.per100!.kcal, 539);
      expect(p.per100!.protein, 6.3);
      expect(p.perServing, isNull);
      expect(p.servingAmount, 15);
      expect(p.servingLabel, '15 g');
    });

    test('zero is kept, absent stays null, kJ converts to kcal', () {
      final p = parseOffProduct('1', {
        'product_name': 'Voda',
        'nutriments': {'energy-kj_100g': 418.4, 'fat_100g': 0},
      })!;
      expect(p.per100!.kcal, closeTo(100, 0.01));
      expect(p.per100!.fat, 0);
      expect(p.per100!.protein, isNull);
    });

    test('serving only product', () {
      final p = parseOffProduct('1', {
        'product_name': 'Tyčinka',
        'nutriments': {'energy-kcal_serving': 180, 'proteins_serving': 20},
      })!;
      expect(p.per100, isNull);
      expect(p.perServing!.kcal, 180);
    });

    test('not found, garbage and outage', () {
      expect(
        parseLookupResponse('1', 404, '{"result":{"id":"product_not_found"}}'),
        isA<LookupNotFound>(),
      );
      expect(
        parseLookupResponse('1', 200, '{"status":"success","product":{}}'),
        isA<LookupNotFound>(),
      );
      expect(parseLookupResponse('1', 500, 'oops'), isA<LookupFailed>());
      expect(parseLookupResponse('1', 200, '<html>'), isA<LookupFailed>());
    });

    test('client sends identifying headers, v3 path and fields', () async {
      late http.Request seen;
      final client = OffClient(
        client: MockClient((request) async {
          seen = request;
          return http.Response(jsonEncode(nutella), 200);
        }),
      );
      final r = await client.byBarcode('3017620422003');
      expect(r, isA<LookupFound>());
      expect(seen.url.host, 'world.openfoodfacts.org');
      expect(seen.url.path, '/api/v3/product/3017620422003');
      expect(seen.url.queryParameters['fields'], contains('nutriments'));
      expect(seen.headers['User-Agent'], startsWith('GymZapisnik/'));
      expect(seen.headers['X-User-Agent'], seen.headers['User-Agent']);
    });

    test(
      'client reports outage, timeout, bad code and local rate limit',
      () async {
        final down = OffClient(
          client: MockClient((_) async => throw http.ClientException('x')),
        );
        expect(await down.byBarcode('3017620422003'), isA<LookupFailed>());

        final slow = OffClient(
          timeout: const Duration(milliseconds: 10),
          client: MockClient((_) => Completer<http.Response>().future),
        );
        final r = await slow.byBarcode('3017620422003');
        expect((r as LookupFailed).message, contains('včas'));

        expect(await down.byBarcode('123'), isA<LookupFailed>());

        var calls = 0;
        final limited = OffClient(
          client: MockClient((_) async {
            calls++;
            return http.Response('{"status":"failure","product":null}', 404);
          }),
        );
        for (var i = 0; i < 12; i++) {
          await limited.byBarcode('3017620422003');
        }
        expect(calls, 10);
      },
    );
  });

  group('state', () {
    test('save, edit, remove, persist and days', () async {
      final state = newState();
      await state.load();
      expect(await state.saveFood(food('a')), isNull);
      expect(await state.saveFood(food('b', day: '2026-10-04')), isNull);
      expect(await state.saveFood(food('c', name: ' ')), 'Zadej název jídla.');
      expect(state.foodsOn('2026-10-05').map((f) => f.id), ['a']);

      await state.saveFood(food('a', amount: 300));
      expect(state.foodsOn('2026-10-05').single.amount, 300);

      final again = AppState(state.store);
      await again.load();
      expect(again.foods.map((f) => f.id), ['a', 'b']);

      await state.removeFood('a');
      expect(state.foods.map((f) => f.id), ['b']);
      final third = AppState(state.store);
      await third.load();
      expect(third.foods.map((f) => f.id), ['b']);
    });

    test('backup round trip, old backups, idempotent restore, wipe', () async {
      final state = newState();
      await state.load();
      await state.saveFood(food('a'));
      await state.saveFood(
        food(
          'b',
          basis: FoodBasis.perServing,
          amount: 2,
          values: const Nutrition(kcal: 0, protein: 5),
        ),
      );
      final json = state.exportBackup();
      expect(jsonDecode(json)['version'], backupVersion);
      expect((jsonDecode(json)['foods'] as List), hasLength(2));

      await state.removeFood('a');
      await state.restoreBackup(json);
      await state.restoreBackup(json);
      expect(state.foods.map((f) => f.id).toSet(), {'a', 'b'});
      final b = state.foods.firstWhere((f) => f.id == 'b');
      expect(b.values.kcal, 0);
      expect(b.values.carbs, isNull);

      final old = jsonDecode(json) as Map<String, dynamic>..remove('foods');
      expect(decodeBackup(jsonEncode(old)).foods, isEmpty);

      await state.wipeAll();
      expect(state.foods, isEmpty);
    });

    test('backup rejects damaged food entries', () {
      Map<String, dynamic> base() => {
        'format': backupFormat,
        'version': backupVersion,
        'foods': [food('a').toJson()],
      };
      expect(() => decodeBackup(jsonEncode(base())), returnsNormally);
      final badDay = base();
      (badDay['foods'] as List)[0]['day'] = '2026-13-45';
      expect(() => decodeBackup(jsonEncode(badDay)), throwsFormatException);
      final badAmount = base();
      (badAmount['foods'] as List)[0]['amount'] = -3;
      expect(() => decodeBackup(jsonEncode(badAmount)), throwsFormatException);
      final dup = base();
      (dup['foods'] as List).add(food('a').toJson());
      expect(() => decodeBackup(jsonEncode(dup)), throwsFormatException);
    });

    test('recentFoods dedupes by name', () async {
      final state = newState();
      await state.load();
      await state.saveFood(food('a'));
      await state.saveFood(food('b', name: 'jogurt'));
      await state.saveFood(food('c', name: 'Chleba'));
      expect(state.recentFoods, hasLength(2));
    });
  });

  group('UI', () {
    Future<AppState> pump(
      WidgetTester tester, {
      ProductLookup? lookup,
      DateTime? day,
    }) async {
      final state = newState(lookup: lookup);
      await tester.runAsync(state.load);
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: NutritionPage(state, initialDay: day),
        ),
      );
      return state;
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('manual entry shows in day overview and can be deleted', (
      tester,
    ) async {
      final state = await pump(tester);
      expect(find.text('Tento den nic nezapsáno.'), findsOneWidget);

      await tester.tap(find.text('Přidat jídlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zadat ručně'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Název jídla'),
        'Ovesná kaše',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Množství (g)'),
        '200',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Energie (kcal) na 100 g'),
        '150',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Bílkoviny (g)'),
        '5',
      );
      await tester.pump();
      expect(find.textContaining('Snědeno: 300 kcal'), findsOneWidget);
      await tester.tap(find.text('Uložit'));
      await settle(tester);

      expect(find.widgetWithText(GroupedRow, 'Ovesná kaše'), findsOneWidget);
      expect(find.textContaining(' · 300 kcal'), findsWidgets);
      // chybějící sacharidy a tuky: součet je jen dolní odhad
      expect(find.textContaining('Sacharidy ≥ –'), findsNothing);
      expect(find.textContaining('≥ 300 kcal'), findsNothing);
      expect(find.text('≥ 0 g'), findsNWidgets(2));
      expect(
        find.textContaining('Oběd ·').evaluate().length +
            find.textContaining('Snídaně ·').evaluate().length +
            find.textContaining('Svačina ·').evaluate().length +
            find.textContaining('Večeře ·').evaluate().length,
        1,
      );
      expect(state.foods, hasLength(1));

      await tester.tap(find.byTooltip('Smazat záznam'));
      await settle(tester);
      expect(state.foods, isEmpty);
      await tester.tap(find.text('Vrátit'));
      await settle(tester);
      expect(state.foods, hasLength(1));
    });

    testWidgets('validation message instead of saving', (tester) async {
      final state = await pump(tester);
      await tester.tap(find.text('Přidat jídlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zadat ručně'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uložit'));
      await tester.pumpAndSettle();
      expect(find.text('Zadej název jídla.'), findsOneWidget);
      expect(state.foods, isEmpty);
    });

    testWidgets('barcode lookup prefills a confirm form', (tester) async {
      final lookup = FakeLookup(
        LookupFound(
          parseOffProduct(
            '3017620422003',
            Map<String, dynamic>.from(nutella['product'] as Map),
          )!,
        ),
      );
      final state = await pump(tester, lookup: lookup);
      await tester.tap(find.text('Přidat jídlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Najít podle čárového kódu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3017620422003');
      await tester.tap(find.text('Najít'));
      await tester.pumpAndSettle();

      expect(lookup.calls, ['3017620422003']);
      expect(find.textContaining('Údaje z Open Food Facts'), findsOneWidget);
      expect(state.foods, isEmpty, reason: 'nic se neuloží bez potvrzení');
      // porce 15 g z obalu je předvyplněné množství
      expect(find.text('15'), findsOneWidget);
      await tester.tap(find.text('Uložit'));
      await settle(tester);
      final saved = state.foods.single;
      expect(saved.barcode, '3017620422003');
      expect(saved.values.kcal, 539);
      expect(saved.amount, 15);
      expect(saved.eaten.kcal, closeTo(80.85, 0.01));
    });

    testWidgets('not found and outage offer manual entry', (tester) async {
      final lookup = FakeLookup(const LookupNotFound());
      final state = await pump(tester, lookup: lookup);
      await tester.tap(find.text('Přidat jídlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Najít podle čárového kódu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3017620422003');
      await tester.tap(find.text('Najít'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Produkt v databázi není'), findsOneWidget);

      lookup.result = const LookupFailed('Databáze není dostupná.');
      await tester.tap(find.text('Najít'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Databáze není dostupná.'), findsOneWidget);

      await tester.tap(find.text('Zadat ručně'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3017620422003 nemáme'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Název jídla'),
        'Neznámé',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Energie (kcal) na 100 g'),
        '0',
      );
      await tester.tap(find.text('Uložit'));
      await settle(tester);
      expect(state.foods.single.barcode, '3017620422003');
      expect(state.foods.single.values.kcal, 0);
    });

    testWidgets('invalid checksum is rejected before any request', (
      tester,
    ) async {
      final lookup = FakeLookup(const LookupNotFound());
      await pump(tester, lookup: lookup);
      await tester.tap(find.text('Přidat jídlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Najít podle čárového kódu'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '3017620422004');
      await tester.tap(find.text('Najít'));
      await tester.pumpAndSettle();
      expect(lookup.calls, isEmpty);
      expect(find.textContaining('kontrolní číslicí'), findsOneWidget);
    });

    testWidgets('past day opens and edit keeps the entry id', (tester) async {
      final state = await pump(tester, day: DateTime(2026, 10, 3));
      await tester.runAsync(
        () => state.saveFood(food('p', day: '2026-10-03', name: 'Rýže')),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(GroupedRow, 'Rýže'), findsOneWidget);
      await tester.tap(find.widgetWithText(GroupedRow, 'Rýže'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Množství (g)'),
        '250',
      );
      await tester.tap(find.text('Uložit změny'));
      await settle(tester);
      expect(state.foods, hasLength(1));
      expect(state.foods.single.id, 'p');
      expect(state.foods.single.amount, 250);
      expect(state.foods.single.day, '2026-10-03');
    });
  });

  test('logged time keeps the chosen day', () {
    final now = DateTime(2026, 10, 7, 21, 15);
    expect(loggedAtFor('2026-10-07', now), now);
    expect(loggedAtFor('2026-10-05', now), DateTime(2026, 10, 5, 21, 15));
    expect(
      loggedAtFor('2026-10-05', now, timeOf: DateTime(2026, 9, 1, 8)),
      DateTime(2026, 10, 5, 8),
    );
  });

  test('meal slot by time of day', () {
    expect(mealOf(DateTime(2026, 1, 1, 7)), 'Snídaně');
    expect(mealOf(DateTime(2026, 1, 1, 10, 29)), 'Snídaně');
    expect(mealOf(DateTime(2026, 1, 1, 10, 30)), 'Oběd');
    expect(mealOf(DateTime(2026, 1, 1, 15)), 'Svačina');
    expect(mealOf(DateTime(2026, 1, 1, 17, 30)), 'Večeře');
    expect(mealOf(DateTime(2026, 1, 1, 23)), 'Večeře');
  });

  testWidgets('day groups by meal, rings for targets, quick add with undo', (
    tester,
  ) async {
    final state = newState();
    await tester.runAsync(() async {
      await state.load();
      await state.setNutritionTargets(protein: 100);
      await state.saveFood(food('a', day: '2026-10-05', name: 'Rýže'));
    });
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1600),
            textScaler: TextScaler.linear(1.5),
          ),
          child: NutritionPage(state, initialDay: DateTime(2026, 10, 5)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oběd · 300 kcal'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^Bílkoviny 15 z 100 g')),
      findsOneWidget,
    );
    expect(find.text('Rychle přidat'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Rýže'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(state.foodsOn('2026-10-05'), hasLength(2));
    // Minulý den: stejný den a stejná část dne jako původní jídlo.
    final added = state.foodsOn('2026-10-05').firstWhere((f) => f.id != 'a');
    expect(dayKey(added.loggedAt), '2026-10-05');
    expect(mealOf(added.loggedAt), 'Oběd');
    expect(find.textContaining('Přidáno: Rýže'), findsOneWidget);
    await tester.tap(find.text('Vrátit'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pumpAndSettle();
    expect(state.foodsOn('2026-10-05'), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
