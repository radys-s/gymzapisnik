import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/ai/trainer.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/coach/trainer_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

class ChatTrainer implements TrainerAi {
  @override
  bool enabled = true;
  final asked = <(List<ChatMessage>, Map<String, dynamic>, bool)>[];
  final replies = <AiResult<String>>[];
  Completer<AiResult<String>>? pending;

  @override
  Future<AiResult<String>> ask(
    List<ChatMessage> messages,
    Map<String, dynamic> context, {
    required bool adult,
  }) async {
    asked.add((messages, context, adult));
    if (pending != null) return pending!.future;
    return replies.isEmpty ? const AiOk('Dnes nohy.') : replies.removeAt(0);
  }

  @override
  Future<AiResult<MachineResult>> recognizeMachine(
    Uint8List jpeg,
    List<Exercise> catalog,
  ) async => const AiOk(MachineResult(null, []));
}

void main() {
  late ChatTrainer trainer;

  Future<AppState> pump(
    WidgetTester tester, {
    bool adult = true,
    bool enabled = true,
  }) async {
    trainer = ChatTrainer()..enabled = enabled;
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db), trainer: trainer);
    await tester.runAsync(() async {
      await state.load();
      await state.acceptConsent(adult: adult, guardianConsent: !adult);
    });
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: TrainerPage(state, now: () => DateTime(2026, 10, 22, 18)),
      ),
    );
    return state;
  }

  Future<void> tapChip(WidgetTester tester, String q) async {
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(q),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(q));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('suggested question asks, answers and is saved', (tester) async {
    final state = await pump(tester, adult: false);
    await tapChip(tester, trainerSuggestions[3]);
    await tester.pumpAndSettle();
    expect(find.text('Než použiješ AI'), findsOneWidget);
    await tester.tap(find.text('Rozumím'));
    await settle(tester);
    expect(find.text('Dnes nohy.'), findsOneWidget);
    expect(trainer.asked.single.$3, isFalse);
    expect(trainer.asked.single.$2['adult'], isFalse);
    expect(state.coachChat.map((m) => m.content), [
      trainerSuggestions[3],
      'Dnes nohy.',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed question, error, retry', (tester) async {
    final state = await pump(tester);
    await tester.runAsync(state.acceptAiNotice);
    trainer.replies.add(const AiError(AiErrorKind.busy, 'AI je přetížená.'));
    await tester.enterText(find.byType(TextField), '  Jak dýchat?  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Odeslat'));
    await settle(tester);
    expect(find.text('Jak dýchat?'), findsOneWidget);
    expect(find.text('AI je přetížená.'), findsOneWidget);
    await tester.tap(find.text('Zkusit znovu'));
    await settle(tester);
    expect(find.text('Dnes nohy.'), findsOneWidget);
    expect(trainer.asked, hasLength(2));
    expect(state.coachChat, hasLength(2));
  });

  testWidgets('quota error has no retry, reopen offers it again', (
    tester,
  ) async {
    final state = await pump(tester);
    await tester.runAsync(state.acceptAiNotice);
    trainer.replies.add(
      const AiError(AiErrorKind.quota, 'Dnešní limit AI je vyčerpaný.'),
    );
    await tester.enterText(find.byType(TextField), 'Jak dýchat?');
    await tester.pump();
    await tester.tap(find.byTooltip('Odeslat'));
    await settle(tester);
    expect(find.text('Dnešní limit AI je vyčerpaný.'), findsOneWidget);
    expect(find.text('Zkusit znovu'), findsNothing);

    // Druhý den: otázka bez odpovědi zůstala, jde ji poslat znovu.
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: TrainerPage(
          state,
          key: UniqueKey(),
          now: () => DateTime(2026, 10, 23, 8),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jak dýchat?'), findsOneWidget);
    await tester.tap(find.text('Zkusit znovu'));
    await settle(tester);
    expect(find.text('Dnes nohy.'), findsOneWidget);
    expect(state.coachChat, hasLength(2));
  });

  testWidgets('clear removes chat, a late answer is dropped', (tester) async {
    final state = await pump(tester);
    await tester.runAsync(state.acceptAiNotice);
    trainer.pending = Completer();
    await tester.enterText(find.byType(TextField), 'Ahoj');
    await tester.pump();
    await tester.tap(find.byTooltip('Odeslat'));
    await settle(tester);
    expect(find.text('Trenér píše…'), findsOneWidget);
    await tester.tap(find.byTooltip('Smazat chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smazat'));
    await settle(tester);
    trainer.pending!.complete(const AiOk('Pozdě.'));
    await settle(tester);
    expect(find.text('Pozdě.'), findsNothing);
    expect(state.coachChat, isEmpty);
    expect(find.text(trainerSuggestions.first), findsOneWidget);
  });

  testWidgets('disabled trainer answers from local data', (tester) async {
    await pump(tester, enabled: false);
    await tester.pumpAndSettle();
    expect(find.textContaining('AI v této verzi není zapnutá'), findsOneWidget);
    await tapChip(tester, trainerSuggestions.first);
    await settle(tester);
    expect(trainer.asked, isEmpty);
    expect(find.textContaining('nemáš zvolený program'), findsWidgets);
  });

  testWidgets('today question is answered instantly without AI', (
    tester,
  ) async {
    final state = await pump(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Týden: 0 z'), findsOneWidget);
    await tapChip(tester, trainerSuggestions.first);
    await settle(tester);
    expect(find.text('Než použiješ AI'), findsNothing);
    expect(trainer.asked, isEmpty);
    expect(state.coachChat, hasLength(2));
  });

  testWidgets('AI error falls back to a local answer', (tester) async {
    final state = await pump(tester);
    await tester.runAsync(state.acceptAiNotice);
    trainer.replies.add(const AiError(AiErrorKind.busy, 'AI je přetížená.'));
    await tapChip(tester, trainerSuggestions[3]);
    await settle(tester);
    expect(find.textContaining('jen z tvých dat'), findsOneWidget);
    expect(find.text('Zkusit znovu'), findsNothing);
    expect(state.coachChat.last.content, contains('Za posledních 7 dní'));
  });

  testWidgets('AI reply loses markdown', (tester) async {
    final state = await pump(tester);
    await tester.runAsync(state.acceptAiNotice);
    trainer.replies.add(const AiOk('**Tip:**\n- spi 8 h'));
    await tester.enterText(find.byType(TextField), 'Jak dýchat?');
    await tester.pump();
    await tester.tap(find.byTooltip('Odeslat'));
    await settle(tester);
    expect(state.coachChat.last.content, 'Tip:\n• spi 8 h');
  });
}
