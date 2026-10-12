import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/ai/photo.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/nutrition.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/nutrition/fridge_page.dart';
import 'package:gymzapisnik/ui/settings/settings_page.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:image/image.dart' as img;

final jpeg = Uint8List.fromList(
  img.encodeJpg(img.Image(width: 16, height: 16)),
);

class FakeCoach implements FridgeCoach {
  @override
  bool enabled = true;
  AiResult<List<PantryItem>> scan = const AiOk([]);
  AiResult<List<MealIdea>> meals = const AiOk([]);
  Completer<AiResult<List<MealIdea>>>? pendingMeals;
  final scans = <Uint8List>[];
  final mealRequests = <(List<PantryItem>, MealContext)>[];

  @override
  Future<AiResult<List<PantryItem>>> scanFridge(Uint8List jpeg) async {
    scans.add(jpeg);
    return scan;
  }

  @override
  Future<AiResult<List<MealIdea>>> suggestMeals(
    List<PantryItem> items,
    MealContext context,
  ) async {
    mealRequests.add((items, context));
    return pendingMeals == null ? meals : await pendingMeals!.future;
  }
}

const idea = MealIdea(
  title: 'Tvaroh s banánem',
  minutes: 5,
  ingredients: [
    PantryItem('tvaroh', amount: 250, unit: 'g'),
    PantryItem('banán', amount: 1, unit: 'ks'),
  ],
  steps: ['Nakrájej banán.', 'Smíchej s tvarohem.'],
  estimate: Nutrition(kcal: 382, protein: 33.6, carbs: 36.4, fat: 11.6),
  source: EstimateSource.table,
);

void main() {
  late FakeCoach coach;

  Future<AppState> pump(
    WidgetTester tester, {
    bool adult = true,
    Widget Function(AppState state)? page,
  }) async {
    coach = FakeCoach();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db), coach: coach);
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: adult, guardianConsent: !adult);
    });
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: page?.call(state) ?? FridgePage(state, picker: (_) async => jpeg),
      ),
    );
    return state;
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> acceptNotice(WidgetTester tester) async {
    expect(find.text('Než použiješ AI'), findsOneWidget);
    await tester.tap(find.text('Rozumím'));
    await settle(tester);
  }

  testWidgets('photo picker pending disables a second scan', (tester) async {
    final picked = Completer<Uint8List?>();
    final state = await pump(
      tester,
      page: (state) => FridgePage(state, picker: (_) => picked.future),
    );
    await tester.runAsync(state.acceptAiNotice);
    await tester.tap(find.text('Vyfotit'));
    await tester.pump();
    await tester.tap(find.text('Z galerie'));
    picked.complete(jpeg);
    await settle(tester);
    expect(coach.scans, hasLength(1));
  });

  testWidgets(
    'unknown unit is visible and editing requires an explicit choice',
    (tester) async {
      final state = await pump(tester);
      await tester.runAsync(
        () async {
          await state.savePantry(const [PantryItem('chléb', amount: 200)]);
          await state.savePantrySelection({pantryKey('chléb')}, 20);
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: FridgePage(state, key: UniqueKey()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('200 (jednotka neznámá)'), findsOneWidget);
      await tester.tap(find.byTooltip('Možnosti: chléb'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upravit množství'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uložit'));
      await tester.pump();
      expect(find.text('Vyber jednotku množství.'), findsOneWidget);
      await tester.tap(find.text('g'));
      await tester.tap(find.text('Uložit'));
      await settle(tester);
      expect(state.pantry.single.unit, 'g');
      expect(find.text('200 g'), findsOneWidget);
      // Změna množství nevrátí vyřazenou potravinu do výběru.
      expect(state.pantryExcluded, {pantryKey('chléb')});
    },
  );

  testWidgets('photo adds recognised items after the one-time notice', (
    tester,
  ) async {
    final state = await pump(tester);
    coach.scan = const AiOk([
      PantryItem('Vejce', amount: 6, unit: 'ks'),
      PantryItem('Tvaroh', amount: 250, unit: 'g'),
    ]);
    await tester.tap(find.text('Vyfotit'));
    await tester.pumpAndSettle();
    await acceptNotice(tester);
    expect(img.decodeJpg(coach.scans.single)!.width, 16);
    expect(find.text('Vejce'), findsOneWidget);
    expect(find.text('6 ks'), findsOneWidget);
    expect(state.pantry, isEmpty);
    await tester.tap(find.text('Potvrdit seznam'));
    await settle(tester);
    expect(state.pantry.map((i) => i.name), ['Vejce', 'Tvaroh']);
    expect(state.profile.aiNoticeAccepted, isTrue);

    // Druhá fotka: bez upozornění, duplicity se nepřidají.
    await tester.tap(find.text('Z galerie'));
    await settle(tester);
    expect(find.text('Než použiješ AI'), findsNothing);
    await tester.tap(find.text('Potvrdit seznam'));
    await settle(tester);
    expect(state.pantry, hasLength(2));
  });

  testWidgets('declining the notice sends nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Vyfotit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zrušit'));
    await settle(tester);
    expect(coach.scans, isEmpty);
  });

  testWidgets(
    'cancelled meal request cannot reopen ideas or persist a late response',
    (tester) async {
      final state = await pump(tester);
      await tester.runAsync(() async {
        await state.acceptAiNotice();
        await state.savePantry(const [PantryItem('tvaroh')]);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: FridgePage(state, key: UniqueKey()),
        ),
      );
      coach.pendingMeals = Completer();
      await tester.tap(find.text('Navrhni jídlo'));
      await tester.pump();
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.text('Zrušit čekání'));
      await tester.pumpAndSettle();
      coach.pendingMeals!.complete(const AiOk([idea]));
      await settle(tester);
      expect(state.savedMealIdeas, isEmpty);
      expect(find.text('Návrhy jídel'), findsNothing);
      expect(find.text('Co mám v ledničce'), findsOneWidget);
    },
  );

  testWidgets('empty photo and quota error are explained', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Vyfotit'));
    await tester.pumpAndSettle();
    await acceptNotice(tester);
    expect(
      find.textContaining('Na fotce AI žádné jídlo nenašla.'),
      findsOneWidget,
    );

    coach.scan = const AiError(
      AiErrorKind.quota,
      'Dnešní limit fotek je vyčerpaný.',
    );
    await tester.tap(find.text('Vyfotit'));
    await settle(tester);
    expect(find.text('Dnešní limit fotek je vyčerpaný.'), findsOneWidget);
  });

  testWidgets('unreadable photo is rejected before upload', (tester) async {
    await pump(
      tester,
      page: (state) => FridgePage(
        state,
        picker: (_) async => Uint8List.fromList([1, 2, 3, 4]),
      ),
    );
    await tester.tap(find.text('Vyfotit'));
    await tester.pumpAndSettle();
    await acceptNotice(tester);
    expect(find.textContaining('neumím přečíst'), findsOneWidget);
    expect(coach.scans, isEmpty);
  });

  testWidgets('manual list, unchecked items and time filter go to meals', (
    tester,
  ) async {
    final state = await pump(tester);
    await tester.runAsync(
      () => state.savePantry(const [
        PantryItem('tvaroh', amount: 250, unit: 'g'),
        PantryItem('banán', amount: 1, unit: 'ks'),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: FridgePage(state, key: UniqueKey(), picker: (_) async => jpeg),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Přidat ručně'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Název'), 'Kečup');
    await tester.tap(find.text('Uložit'));
    await settle(tester);
    expect(state.pantry.map((i) => i.name), contains('Kečup'));

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Kečup'));
    await settle(tester);
    await tester.tap(find.text('10 min'));
    await settle(tester);
    coach.meals = const AiOk([idea]);
    await tester.tap(find.text('Navrhni jídlo'));
    await tester.pumpAndSettle();
    await acceptNotice(tester);

    final (items, context) = coach.mealRequests.single;
    expect(items.map((i) => i.name), ['tvaroh', 'banán']);
    expect(context.maxMinutes, 10);
    expect(context.adult, isTrue);

    expect(find.text('Návrhy jídel'), findsOneWidget);
    expect(find.text('Tvaroh s banánem'), findsOneWidget);
    expect(find.textContaining('5 min · 382 kcal · B 34 g'), findsOneWidget);
    expect(find.text('Odhad podle tabulky potravin'), findsOneWidget);
    expect(find.text('• tvaroh – 250 g'), findsOneWidget);
    expect(find.text('1. Nakrájej banán.'), findsOneWidget);

    await tester.tap(find.text('Zapsat do deníku'));
    await tester.pumpAndSettle();
    expect(find.text('Přidat jídlo'), findsOneWidget);
    await tester.tap(find.text('Uložit'));
    await settle(tester);
    final logged = state.foods.single;
    expect(logged.name, 'Tvaroh s banánem');
    expect(logged.basis, FoodBasis.perServing);
    expect(logged.eaten.kcal, 382);
    expect(logged.eaten.protein, 34);
    expect(find.text('Zapsáno: Tvaroh s banánem'), findsOneWidget);
  });

  testWidgets('meal errors stay on the list page', (tester) async {
    final state = await pump(tester);
    await tester.runAsync(() => state.savePantry(const [PantryItem('rýže')]));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: FridgePage(state, key: UniqueKey(), picker: (_) async => jpeg),
      ),
    );
    await tester.pumpAndSettle();
    coach.meals = const AiError(
      AiErrorKind.offline,
      'AI není dostupná (zkontroluj internet).',
    );
    await tester.tap(find.text('Navrhni jídlo'));
    await tester.pumpAndSettle();
    await acceptNotice(tester);
    expect(
      find.text('AI není dostupná (zkontroluj internet).'),
      findsOneWidget,
    );
    expect(find.text('Návrhy jídel'), findsNothing);

    coach.meals = const AiError(
      AiErrorKind.failed,
      'AI vrátila nečitelnou odpověď. Zkus to znovu.',
    );
    await tester.tap(find.text('Navrhni jídlo'));
    await settle(tester);
    expect(
      find.text('AI vrátila nečitelnou odpověď. Zkus to znovu.'),
      findsOneWidget,
    );
  });

  testWidgets('disabled coach shows info and disables photo buttons', (
    tester,
  ) async {
    late AppState state;
    await pump(
      tester,
      page: (s) {
        state = s;
        coach.enabled = false;
        return FridgePage(s, picker: (_) async => jpeg);
      },
    );
    expect(find.textContaining('zatím není zapnutá'), findsOneWidget);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text('Vyfotit'),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNull);
    expect(state.pantry, isEmpty);
  });

  testWidgets('settings: minors see only the protein target', (tester) async {
    final state = await pump(
      tester,
      adult: false,
      page: (s) => SettingsPage(s),
    );
    expect(find.text('Denní cíl bílkovin'), findsOneWidget);
    expect(find.text('Denní cíl energie'), findsNothing);
    await tester.tap(find.text('Denní cíl bílkovin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Uložit'));
    await tester.pumpAndSettle();
    expect(find.text('Zadej číslo od 20 do 400.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '130');
    await tester.tap(find.text('Uložit'));
    await settle(tester);
    expect(state.profile.proteinTarget, 130);
    expect(find.text('130 g'), findsOneWidget);
  });

  test('photo prep turns large PNG into a small JPEG', () {
    final big = img.Image(width: 2000, height: 1000);
    img.fill(big, color: img.ColorRgb8(200, 100, 50));
    final out = prepareJpeg(Uint8List.fromList(img.encodePng(big)))!;
    expect(out.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 1024);
    expect(decoded.height, 512);
    expect(img.decodeJpg(prepareJpeg(jpeg)!)!.width, 16);
    expect(prepareJpeg(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
