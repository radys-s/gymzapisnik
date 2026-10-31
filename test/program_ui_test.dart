import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/program/program_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Future<AppState> _state(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> _pump(WidgetTester tester, AppState state) async {
  tester.view
    ..physicalSize = const Size(390, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: buildTheme(Brightness.light), home: ProgramPage(state)),
  );
  await tester.pumpAndSettle();
}

/// Klepnutí, které zapisuje do databáze (v reálném čase).
Future<void> _write(WidgetTester tester, Finder finder) async {
  await tester.runAsync(() async {
    await tester.tap(finder);
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('build a shoulders + triceps day and start using it', (
    tester,
  ) async {
    final state = await _state(tester);
    await _pump(tester, state);

    await tester.tap(find.text('Vytvořit vlastní program').first);
    await tester.pumpAndSettle();
    expect(find.text('Nový program'), findsWidgets);

    await tester.enterText(
      find.widgetWithText(TextField, 'Název programu'),
      'Moje ruce',
    );
    await tester.tap(find.text('Přidat den'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Ramena'));
    await tester.tap(find.widgetWithText(FilterChip, 'Triceps'));
    await tester.pumpAndSettle();
    expect(find.text('Ramena a triceps'), findsOneWidget);
    await tester.tap(find.text('Přidat den · 6 cviků'));
    await tester.pumpAndSettle();

    // Série × opakování přes předvolbu.
    await tester.tap(find.text('Barbell overhead press'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Síla 4×5–8'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(195, 20)); // zavřít list
    await tester.pumpAndSettle();
    expect(find.text('4× 5–8'), findsOneWidget);

    await _write(tester, find.text('Uložit a používat'));
    final program = state.split!;
    expect(program.custom, isTrue);
    expect(program.name, 'Moje ruce');
    expect(program.days.single.name, 'Ramena a triceps');
    expect(program.days.single.exercises.first.sets, 4);
    expect(find.text('Moje ruce'), findsWidgets);
    expect(find.text('Na řadě: Ramena a triceps'), findsOneWidget);
  });

  testWidgets('leaving the editor with changes asks first', (tester) async {
    final state = await _state(tester);
    await _pump(tester, state);
    await tester.tap(find.text('Vytvořit vlastní program').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Název programu'),
      'Něco',
    );
    await tester.pump();

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Zahodit změny?'), findsOneWidget);
    await tester.tap(find.text('Pokračovat v úpravách'));
    await tester.pumpAndSettle();
    expect(find.text('Nový program'), findsWidgets);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zahodit'));
    await tester.pumpAndSettle();
    expect(find.text('Nový program'), findsNothing);
    expect(state.customPrograms, isEmpty);
  });

  testWidgets('ready program becomes an editable copy', (tester) async {
    final state = await _state(tester);
    await _pump(tester, state);
    final ppl = splitTemplates.firstWhere((t) => t.id == 'ppl');

    await tester.tap(find.text(ppl.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upravit jako vlastní'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, '${ppl.name} (vlastní)'),
      findsOneWidget,
    );
    await _write(tester, find.text('Uložit a používat'));

    expect(state.customPrograms.single.days, hasLength(ppl.days.length));
    expect(state.split?.id, state.customPrograms.single.id);
    // Detail ukazuje rovnou kopii.
    expect(find.text('Tento program používáš'), findsOneWidget);
  });

  testWidgets('copy of another program does not switch the active one', (
    tester,
  ) async {
    final state = await _state(tester);
    await tester.runAsync(() => state.setSplit('ppl'));
    await _pump(tester, state);
    final other = splitTemplates.firstWhere((t) => t.id != 'ppl');

    // Poslední výskyt je řádek v Hotových programech (první je doporučení).
    await tester.ensureVisible(find.text(other.name).last);
    await tester.tap(find.text(other.name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upravit jako vlastní'));
    await tester.pumpAndSettle();
    await _write(tester, find.text('Uložit kopii'));

    expect(state.customPrograms, hasLength(1));
    expect(state.split?.id, 'ppl');
    expect(find.text('Používat tento program'), findsOneWidget);
  });

  testWidgets('weekdays set the frequency', (tester) async {
    final state = await _state(tester);
    await _pump(tester, state);

    await _write(tester, find.text('Po'));
    await _write(tester, find.text('St'));
    await _write(tester, find.text('Pá'));
    expect(state.profile.trainingDays, [1, 3, 5]);
    expect(state.weekGoal, 3);
    expect(find.byTooltip('Víc: Tréninků týdně'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.add_rounded).first,
          )
          .onPressed,
      isNull,
    );

    for (final d in ['Po', 'St', 'Pá']) {
      await _write(tester, find.text(d));
    }
    expect(state.profile.trainingDays, isNull);
    expect(state.weekGoal, 3);

    await _write(tester, find.byTooltip('Víc: Tréninků týdně'));
    expect(state.weekGoal, 4);
  });
}
