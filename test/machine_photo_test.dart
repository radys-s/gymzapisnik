import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ai/fridge_coach.dart';
import 'package:gymzapisnik/ai/trainer.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/exercise_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;

final jpeg = Uint8List.fromList(
  img.encodeJpg(img.Image(width: 64, height: 48)),
);

class FakeTrainer implements TrainerAi {
  @override
  bool enabled = true;
  AiResult<MachineResult> machine = const AiOk(MachineResult(null, []));
  final photos = <(Uint8List, List<Exercise>)>[];
  Completer<AiResult<MachineResult>>? pending;

  @override
  Future<AiResult<MachineResult>> recognizeMachine(
    Uint8List jpeg,
    List<Exercise> catalog,
  ) async {
    photos.add((jpeg, catalog));
    return pending == null ? machine : await pending!.future;
  }

  @override
  Future<AiResult<String>> ask(
    List<ChatMessage> messages,
    Map<String, dynamic> context, {
    required bool adult,
  }) async => const AiOk('');
}

void main() {
  test('machine result keeps only known ids, best first, at most 3', () {
    final r = parseMachine(
      {
        'machine': ' Leg press ',
        'matches': [
          {'id': 'hack_squat', 'confidence': 0.4},
          {'id': 'made_up', 'confidence': 0.99},
          {'id': 'leg_press', 'confidence': 0.9},
          {'id': 'leg_press', 'confidence': 0.1},
          {'id': 'squat', 'confidence': 'x'},
          {'id': 'lunge', 'confidence': 0.2},
        ],
      },
      {'leg_press', 'hack_squat', 'squat', 'lunge'},
    );
    expect(r.machine, 'Leg press');
    expect(r.matches.map((m) => m.id), ['leg_press', 'squat', 'hack_squat']);
    expect(r.matches[1].confidence, 0.5);
    expect(() => parseMachine({'x': 1}, {}), throwsFormatException);
  });

  test('client sends catalog and drops ids it did not send', () async {
    Map<String, dynamic>? body;
    final coach = HttpFridgeCoach(
      baseUrl: 'https://example.test/',
      installId: () async => 'id',
      client: MockClient((req) async {
        expect(req.url.path, '/v1/machine');
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          '{"machine":null,"matches":[{"id":"leg_press","confidence":0.8},'
          '{"id":"bench_press","confidence":0.9}]}',
          200,
        );
      }),
    );
    final catalog = builtInExercises.where((e) => e.id == 'leg_press').toList();
    final r = await coach.recognizeMachine(jpeg, catalog);
    expect((r as AiOk<MachineResult>).value.matches.single.id, 'leg_press');
    expect(body!['exercises'], [
      {'id': 'leg_press', 'name': catalog.single.name},
    ]);
    expect(base64Decode(body!['image'] as String), jpeg);
  });

  test('chat sends the last 12 messages and returns the reply', () async {
    Map<String, dynamic>? body;
    final coach = HttpFridgeCoach(
      baseUrl: 'https://example.test',
      installId: () async => 'id',
      client: MockClient((req) async {
        expect(req.url.path, '/v1/coach');
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'reply': ' Dnes nohy. '}), 200);
      }),
    );
    final now = DateTime(2026, 10, 22);
    final messages = [
      for (var i = 0; i < 15; i++)
        ChatMessage(
          i.isEven ? ChatRole.user : ChatRole.assistant,
          'zpráva $i ${'x' * (i == 14 ? 1200 : 0)}',
          now,
        ),
    ];
    final r = await coach.ask(messages, {'split': 'ppl'}, adult: false);
    expect((r as AiOk<String>).value, 'Dnes nohy.');
    final sent = body!['messages'] as List;
    expect(sent, hasLength(12));
    expect((sent.first as Map)['content'], startsWith('zpráva 3'));
    expect(((sent.last as Map)['content'] as String).length, 1000);
    expect(body!['adult'], false);
    expect(body!['context'], {'split': 'ppl'});

    final empty = HttpFridgeCoach(
      baseUrl: 'https://example.test',
      installId: () async => 'id',
      client: MockClient((_) async => http.Response('{"reply":" "}', 200)),
    );
    expect(await empty.ask(messages, {}, adult: true), isA<AiError>());
  });

  test('chat message survives JSON and rejects junk', () {
    final m = ChatMessage(ChatRole.assistant, 'Ahoj', DateTime(2026, 1, 2));
    final back = ChatMessage.tryParse(m.toJson())!;
    expect(back.role, ChatRole.assistant);
    expect(back.content, 'Ahoj');
    expect(back.at, DateTime(2026, 1, 2));
    expect(ChatMessage.tryParse({'role': 'system', 'content': 'x'}), isNull);
    expect(ChatMessage.tryParse({'role': 'user', 'content': ' '}), isNull);
  });

  group('picker photo', () {
    late FakeTrainer trainer;
    late List<String>? popped;

    Future<void> pump(WidgetTester tester, {bool multiple = true}) async {
      trainer = FakeTrainer();
      popped = null;
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final state = AppState(LocalStore(db), trainer: trainer);
      await tester.runAsync(() async {
        await state.load();
        await state.acceptConsent(adult: true, guardianConsent: false);
      });
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped = await Navigator.push<List<String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExercisePickerPage(
                        state,
                        multiple: multiple,
                        picker: (_) async => jpeg,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> snap(WidgetTester tester) async {
      await tester.tap(find.text('Vyfotit stroj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vyfotit'));
      await tester.pumpAndSettle();
      if (find.text('Než použiješ AI').evaluate().isNotEmpty) {
        await tester.tap(find.text('Rozumím'));
      }
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('match is selected and added, catalog is built-in', (
      tester,
    ) async {
      await pump(tester);
      trainer.machine = const AiOk(
        MachineResult('Leg press', [
          MachineMatch('leg_press', 0.9),
          MachineMatch('hack_squat', 0.3),
        ]),
      );
      await snap(tester);
      expect(trainer.photos, hasLength(1));
      expect(trainer.photos.single.$2, builtInExercises);
      expect(find.text('Na fotce: Leg press'), findsOneWidget);
      expect(find.text('Nejspíš tohle'), findsOneWidget);
      expect(find.text('Spíš ne, ale podobné'), findsOneWidget);
      final name = builtInExercises.firstWhere((e) => e.id == 'leg_press').name;
      await tester.tap(find.text('Nejspíš tohle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Přidat cvik'));
      await tester.pumpAndSettle();
      expect(popped, ['leg_press']);
      expect(name, isNotEmpty);
    });

    testWidgets('single mode returns the match right away', (tester) async {
      await pump(tester, multiple: false);
      trainer.machine = const AiOk(
        MachineResult(null, [MachineMatch('lat_pulldown', 0.5)]),
      );
      await snap(tester);
      expect(find.text('Návrhy podle fotky'), findsOneWidget);
      await tester.tap(find.text('Možná'));
      await tester.pumpAndSettle();
      expect(popped, ['lat_pulldown']);
    });

    testWidgets('errors and no match fall back to the list', (tester) async {
      await pump(tester);
      trainer.machine = const AiError(
        AiErrorKind.offline,
        'K AI se nepodařilo připojit.',
      );
      await snap(tester);
      expect(
        find.text('K AI se nepodařilo připojit. Cvik zatím najdi v seznamu.'),
        findsOneWidget,
      );
      expect(find.text('Hledat cvik'), findsOneWidget);

      trainer.machine = const AiOk(MachineResult('Lavice', []));
      await snap(tester);
      expect(find.textContaining('stroj nepoznal'), findsOneWidget);
      expect(popped, isNull);
    });

    testWidgets('cancel drops a late answer', (tester) async {
      await pump(tester);
      trainer.pending = Completer();
      await tester.tap(find.text('Vyfotit stroj'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vyfotit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rozumím'));
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(find.text('Hledám cvik podle fotky…'), findsOneWidget);
      await tester.tap(find.text('Hledám cvik podle fotky…'));
      await tester.pump();
      expect(find.text('Vyfotit stroj'), findsOneWidget);
      trainer.pending!.complete(
        const AiOk(MachineResult(null, [MachineMatch('leg_press', 0.9)])),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nejspíš tohle'), findsNothing);
      expect(popped, isNull);
    });

    testWidgets('row is hidden when AI is off', (tester) async {
      await pump(tester);
      expect(find.text('Vyfotit stroj'), findsOneWidget);
      trainer.enabled = false;
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Vyfotit stroj'), findsNothing);
    });
  });
}
