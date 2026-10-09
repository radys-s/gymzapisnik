import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/data/backup.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/food_table.dart';
import 'package:gymzapisnik/domain/nutrition.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<AppState> loadedState() async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await state.load();
  return state;
}

HttpFridgeCoach coachWith(
  Future<http.Response> Function(http.Request) handler, {
  String url = 'https://ai.example/',
}) => HttpFridgeCoach(
  baseUrl: url,
  installId: () async => '0b9f5c2e-6f1a-4c3d-9e8b-1a2b3c4d5e6f',
  client: MockClient(handler),
);

/// Odpověď v UTF-8 (výchozí `http.Response` kóduje latin1).
http.Response utf8Json(Object body, int status) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

final meal = {
  'title': 'Vejce s chlebem',
  'minutes': 10,
  'ingredients': [
    {'name': 'vejce', 'amount': 3, 'unit': 'ks'},
    {'name': 'chléb', 'amount': 100, 'unit': 'g'},
    {'name': 'sůl', 'amount': null, 'unit': null},
  ],
  'steps': ['Usmaž vejce.', 'Podávej s chlebem.'],
  'estimate': {'kcal': 999, 'protein': 1, 'carbs': 1, 'fat': 1},
};

const context = MealContext(
  trainingToday: true,
  maxMinutes: 20,
  adult: false,
  eatenKcal: 1500,
  eatenProtein: 50,
  proteinLeft: 70,
);

void main() {
  group('food table', () {
    test('finds foods by Czech names and inflections', () {
      expect(findFood('Vajíčka')?.name, 'vejce');
      expect(findFood('Kuřecí prsní řízky')?.name, 'kuřecí prsa');
      expect(findFood('Řecký jogurt bílý')?.name, 'řecký jogurt');
      expect(findFood('bílý jogurt')?.name, 'bílý jogurt');
      expect(findFood('Olivový olej')?.name, 'olej');
      expect(findFood('Tavený sýr')?.name, 'tavený sýr');
      expect(findFood('Arašídové máslo')?.name, 'arašídové máslo');
      expect(findFood('vařená rýže')?.name, 'rýže vařená');
      expect(findFood('hořká čokoláda')?.name, 'hořká čokoláda');
      expect(findFood('neznámá věc'), isNull);
    });

    test('stem must start a word', () {
      // „med“ nesmí trefit konec jiného slova.
      expect(findFood('zmed'), isNull);
    });

    test('estimates by grams and pieces, skips spices', () {
      final n = tableEstimate([
        (name: 'vejce', amount: 2, unit: 'ks'),
        (name: 'chléb', amount: 50, unit: 'g'),
        (name: 'sůl', amount: null, unit: null),
      ])!;
      // 100 g vajec + 50 g chleba
      expect(n.kcal, closeTo(143 + 120, 0.01));
      expect(n.protein, closeTo(12.6 + 4, 0.01));
    });

    test(
      'explicit pieces use approximate edible weights (bread slices, legs)',
      () {
        final n = tableEstimate([
          (name: 'chléb', amount: 2, unit: 'ks'),
          (name: 'kuřecí stehno', amount: 1, unit: 'ks'),
        ])!;
        // 2 krajíce po 45 g + 150 g masa ze stehna
        expect(n.kcal, closeTo(240 * 0.9 + 121 * 1.5, 0.01));
        expect(n.protein, closeTo(8 * 0.9 + 19.7 * 1.5, 0.01));
      },
    );

    test('unknown food or missing amount means no table estimate', () {
      expect(
        tableEstimate([(name: 'dračí ovoce', amount: 100, unit: 'g')]),
        isNull,
      );
      expect(
        tableEstimate([(name: 'vejce', amount: null, unit: null)]),
        isNull,
      );
      expect(
        tableEstimate([(name: 'brokolice', amount: 1, unit: 'ks')]),
        isNull,
      );
      expect(tableEstimate([]), isNull);
    });

    test('every row is sane', () {
      for (final f in foodTable) {
        expect(f.stems, isNotEmpty, reason: f.name);
        if (f.trivial) continue;
        expect(f.kcal, inInclusiveRange(1, 900), reason: f.name);
        expect(
          f.protein + f.carbs + f.fat,
          lessThanOrEqualTo(100.5),
          reason: f.name,
        );
        // Energie zhruba sedí s makry (4/4/9 kcal na gram).
        final fromMacros = 4 * f.protein + 4 * f.carbs + 9 * f.fat;
        expect(
          (fromMacros - f.kcal).abs(),
          lessThan(f.kcal * 0.2 + 15),
          reason: f.name,
        );
      }
    });
  });

  group('parsing', () {
    test('meals prefer the local table over the AI estimate', () {
      final meals = parseMeals({
        'meals': [
          meal,
          {
            ...meal,
            'title': 'Exotika',
            'ingredients': [
              {'name': 'dračí ovoce', 'amount': 100, 'unit': 'g'},
            ],
          },
        ],
      });
      expect(meals, hasLength(2));
      expect(meals[0].source, EstimateSource.table);
      expect(meals[0].estimate.kcal, closeTo(150 * 1.43 + 240, 0.01));
      expect(meals[1].source, EstimateSource.ai);
      expect(meals[1].estimate.kcal, 999);
    });

    test('items reject missing names and keep unknown units unknown', () {
      expect(
        () => parseItems({
          'items': [
            {'name': ''},
          ],
        }),
        throwsFormatException,
      );
      final items = parseItems({
        'items': [
          {'name': ' Mléko ', 'amount': 1000, 'unit': 'ml'},
          {'name': 'Sýr', 'amount': -1, 'unit': 'kg'},
        ],
      });
      expect(items.map((i) => i.name), ['Mléko', 'Sýr']);
      expect(items[1].amount, isNull);
      expect(items[1].unit, isNull);
    });

    test('minor context never sends kcal', () {
      final json = context.toJson();
      expect((json['eatenToday'] as Map)['kcal'], isNull);
      expect((json['eatenToday'] as Map)['protein'], 50);
      expect(json['adult'], false);
    });
  });

  group('http client', () {
    test('scan sends base64 JPEG and install id', () async {
      late http.Request sent;
      final coach = coachWith((r) async {
        sent = r;
        return http.Response(
          jsonEncode({
            'items': [
              {'name': 'Vejce', 'amount': 6, 'unit': 'ks', 'confidence': 0.9},
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final result = await coach.scanFridge(
        Uint8List.fromList([255, 216, 255]),
      );
      expect(result, isA<AiOk<List<PantryItem>>>());
      expect((result as AiOk<List<PantryItem>>).value.single.name, 'Vejce');
      expect(sent.url.toString(), 'https://ai.example/v1/fridge');
      expect(sent.headers['X-Install-Id'], hasLength(36));
      expect(jsonDecode(sent.body)['image'], '/9j/');
    });

    test('meals request carries items and context', () async {
      late Map<String, dynamic> body;
      final coach = coachWith((r) async {
        body = jsonDecode(r.body) as Map<String, dynamic>;
        return utf8Json({
          'meals': [meal],
        }, 200);
      });
      final result = await coach.suggestMeals(const [
        PantryItem('vejce', amount: 6, unit: 'ks'),
      ], context);
      expect(result, isA<AiOk<List<MealIdea>>>());
      expect(body['items'], [
        {'name': 'vejce', 'amount': 6.0, 'unit': 'ks'},
      ]);
      expect(body['context']['maxMinutes'], 20);
    });

    test('429 maps to quota with the proxy message', () async {
      final coach = coachWith(
        (_) async => utf8Json({
          'error': {'code': 'quota_install', 'message': 'Dnešní limit.'},
        }, 429),
      );
      final result = await coach.scanFridge(Uint8List(3));
      expect(result, isA<AiError<List<PantryItem>>>());
      final error = result as AiError<List<PantryItem>>;
      expect(error.kind, AiErrorKind.quota);
      expect(error.message, 'Dnešní limit.');
    });

    test('502 without body gives a generic Czech message', () async {
      final coach = coachWith((_) async => http.Response('', 502));
      final result = await coach.scanFridge(Uint8List(3));
      final error = result as AiError<List<PantryItem>>;
      expect(error.kind, AiErrorKind.failed);
      expect(error.message, contains('502'));
    });

    test('network failure, invalid JSON and empty meals', () async {
      final offline = coachWith((_) async => throw http.ClientException('x'));
      expect(
        ((await offline.scanFridge(Uint8List(3))) as AiError).kind,
        AiErrorKind.offline,
      );
      final garbage = coachWith((_) async => http.Response('<html>', 200));
      expect(
        ((await garbage.scanFridge(Uint8List(3))) as AiError).kind,
        AiErrorKind.failed,
      );
      final empty = coachWith(
        (_) async => http.Response(jsonEncode({'meals': []}), 200),
      );
      expect(
        await empty.suggestMeals(const [PantryItem('x')], context),
        isA<AiError<List<MealIdea>>>(),
      );
    });

    test('timeout is reported as offline', () async {
      final coach = HttpFridgeCoach(
        baseUrl: 'https://ai.example',
        installId: () async => 'id',
        timeout: const Duration(milliseconds: 10),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      final result = await coach.scanFridge(Uint8List(3));
      expect((result as AiError).kind, AiErrorKind.offline);
    });

    test('no URL means disabled, nothing is sent', () async {
      var calls = 0;
      final coach = coachWith((_) async {
        calls++;
        return http.Response('{}', 200);
      }, url: '');
      expect(coach.enabled, isFalse);
      final result = await coach.scanFridge(Uint8List(3));
      expect((result as AiError).kind, AiErrorKind.disabled);
      expect(calls, 0);
    });
  });

  group('state', () {
    test('install id is created once and kept', () async {
      final state = await loadedState();
      final a = await state.installId();
      final b = await state.installId();
      expect(a, hasLength(36));
      expect(b, a);
      expect(state.exportBackup(), isNot(contains(a)));
    });

    test('pantry does not silently discard items after sixty', () async {
      final state = await loadedState();
      final items = List.generate(61, (i) => PantryItem('potravina $i'));
      await state.savePantry(items);
      expect(state.pantry.map((i) => i.name), items.map((i) => i.name));
      await state.load();
      expect(state.pantry, hasLength(61));
    });

    test('pantry survives backup and restore', () async {
      final state = await loadedState();
      await state.savePantry(const [
        PantryItem('vejce', amount: 6, unit: 'ks'),
        PantryItem('tvaroh'),
      ]);
      final backup = state.exportBackup();
      final other = await loadedState();
      await other.restoreBackup(backup);
      expect(other.pantry.map((i) => i.name), ['vejce', 'tvaroh']);
      expect(other.pantry.first.amount, 6);
      await other.savePantry(const []);
      expect(other.pantry, isEmpty);
    });

    test('targets: minors never get a kcal target', () async {
      final state = await loadedState();
      await state.acceptConsent(adult: false, guardianConsent: true);
      await state.setNutritionTargets(protein: 120, kcal: 2500);
      expect(state.profile.proteinTarget, 120);
      expect(state.profile.kcalTarget, isNull);
      expect(state.profile.extra.containsKey('kcalTarget'), isFalse);

      final adult = await loadedState();
      await adult.acceptConsent(adult: true, guardianConsent: false);
      await adult.setNutritionTargets(protein: 5, kcal: 2500);
      expect(adult.profile.proteinTarget, 20);
      expect(adult.profile.kcalTarget, 2500);
      await adult.setNutritionTargets();
      expect(adult.profile.proteinTarget, isNull);
    });

    test('meal context uses today totals and protein left', () async {
      final state = await loadedState();
      await state.acceptConsent(adult: true, guardianConsent: false);
      await state.setNutritionTargets(protein: 100);
      final now = DateTime(2026, 10, 7, 12);
      await state.saveFood(
        FoodEntry(
          id: 'f1',
          day: '2026-10-07',
          loggedAt: now,
          name: 'Tvaroh',
          basis: FoodBasis.per100,
          amount: 250,
          values: const Nutrition(kcal: 110, protein: 13),
        ),
      );
      final c = state.mealContext(maxMinutes: 20, now: now);
      expect(c.eatenProtein, closeTo(32.5, 0.01));
      expect(c.proteinLeft, closeTo(67.5, 0.01));
      expect(c.eatenKcal, closeTo(275, 0.01));
      expect(c.adult, isTrue);
      expect(state.proteinLeft(DateTime(2026, 10, 8)), 100);
    });

    test('backup keeps targets and pantry keys only', () {
      expect(
        backupSettingsKeys,
        containsAll(['proteinTarget', 'kcalTarget', 'pantry']),
      );
      expect(backupSettingsKeys, isNot(contains('installId')));
      expect(backupSettingsKeys, isNot(contains('aiNotice')));
    });
  });
}
