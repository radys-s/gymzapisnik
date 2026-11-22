// Renders the main screens to PNG files for design review, with the real
// fonts. Nothing is asserted; the output is for eyes.
//
//   SCREENS_OUT=/tmp/screens flutter test tool/screens_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/program/program_editor_page.dart';
import 'package:gymzapisnik/ui/welcome/whats_new.dart';

const _phone = Size(390, 844);
final _out = Directory(Platform.environment['SCREENS_OUT'] ?? 'build/screens');
final _root = GlobalKey();
var _n = 0;

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File(f).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Flutter's artifact cache: the test runner binary lives three levels in.
String get _artifacts =>
    File(Platform.resolvedExecutable).parent.parent.parent.path;

Future<void> _fonts() async {
  final material = '$_artifacts/material_fonts';
  await _font('Roboto', [
    for (final w in ['Regular', 'Medium', 'Bold', 'Black'])
      '$material/Roboto-$w.ttf',
  ]);
  await _font('MaterialIcons', ['$material/MaterialIcons-Regular.otf']);
  await _font('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/Inter-$w.ttf',
  ]);
  await _font('Barlow Condensed', [
    for (final w in ['SemiBold', 'Bold', 'ExtraBold'])
      'assets/fonts/BarlowCondensed-$w.ttf',
  ]);
}

Future<void> _shot(WidgetTester tester, String name) async {
  final boundary =
      _root.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File(
      '${_out.path}/${(++_n).toString().padLeft(2, '0')}-$name.png',
    );
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    debugPrint('MISS $f');
    return;
  }
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pumpAndSettle();
}

/// A tap that writes to the database, which needs real time to finish.
Future<void> _save(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    debugPrint('MISS $f');
    return;
  }
  await tester.runAsync(() async {
    await tester.tap(f.first, warnIfMissed: false);
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// A single-answer card: it highlights, then moves on by itself.
Future<void> _pick(WidgetTester tester, Finder f) async {
  await _tap(tester, f);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

Future<AppState> _state(WidgetTester tester) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final state = AppState(LocalStore(db));
  await tester.runAsync(state.load);
  return state;
}

Future<void> _pump(WidgetTester tester, AppState state, {Widget? home}) async {
  tester.view
    ..physicalSize = _phone * 2
    ..devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _root,
      child: home == null ? GymApp(state) : appFrame(home: home),
    ),
  );
  await tester.pumpAndSettle();
}

/// A test that draws real shadows. Tests paint them as solid shapes by
/// default, and the binding checks the flag is back before the test ends.
void _screens(String name, Future<void> Function(WidgetTester tester) body) {
  testWidgets(name, (tester) async {
    debugDisableShadows = false;
    try {
      await body(tester);
    } finally {
      debugDisableShadows = true;
    }
  });
}

void main() {
  setUpAll(() async {
    _out.createSync(recursive: true);
    await _fonts();
  });

  _screens('first run', (tester) async {
    final state = await _state(tester);
    await _pump(tester, state);
    await _shot(tester, 'welcome');
    await _tap(tester, find.text('Začít'));
    await _shot(tester, 'consent');
    await _tap(tester, find.text('Souhlasím s podmínkami používání'));
    await _tap(tester, find.text('Je mi 18 let nebo víc'));
    await _shot(tester, 'consent-filled');
    await _save(tester, find.text('Pokračovat'));
    await _shot(tester, 'goal');
    await _pick(tester, find.text('Svaly'));
    await _shot(tester, 'experience');
    await _pick(tester, find.text('Půl roku'));
    await _tap(tester, find.text('4×'));
    await _shot(tester, 'schedule');
    await _tap(tester, find.text('Pokračovat'));
    await _shot(tester, 'gym');
    await _pick(tester, find.text('Velké fitko'));
    await _tap(tester, find.text('Kolena'));
    await _shot(tester, 'pain');
    await _save(tester, find.text('Pokračovat'));
    await _shot(tester, 'plan');
  });

  _screens('own program', (tester) async {
    final state = await _state(tester);
    await tester.runAsync(() => state.applyPlan(const PlanAnswers()));
    await _pump(tester, state, home: ProgramEditorPage(state));
    await _shot(tester, 'editor-empty');
    await _tap(tester, find.text('Přidat den'));
    await _shot(tester, 'add-day');
    await _tap(tester, find.byKey(const ValueKey('muscle-chest')));
    await _tap(tester, find.byKey(const ValueKey('muscle-triceps')));
    await _shot(tester, 'add-day-picked');
    await _tap(tester, find.text('Vyberu sám'));
    await _shot(tester, 'add-day-own');
  });

  _screens('tabs', (tester) async {
    final state = await _state(tester);
    final now = DateTime.now();
    await tester.runAsync(() async {
      await state.applyPlan(const PlanAnswers());
      await state.acceptConsent(
        adult: true,
        guardianConsent: false,
        welcomeVersion: whatsNewRelease,
        aiNotice: true,
      );
      await state.addBodyweight(78);
      for (final (daysAgo, kg) in [(9, 75.0), (5, 80.0), (2, 82.5)]) {
        final at = now.subtract(Duration(days: daysAgo));
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [SetEntry(weight: kg, reps: 8, done: true)];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
    });
    await _pump(tester, state);
    await _shot(tester, 'home');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await tester.pumpAndSettle();
    await _shot(tester, 'home-2');
    await _tap(tester, find.text('Trénink'));
    await _shot(tester, 'training');
    await _tap(tester, find.text('Strava'));
    await _shot(tester, 'food');
    await _tap(tester, find.text('Pokrok'));
    await _shot(tester, 'progress');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    await _shot(tester, 'progress-2');
  });

  _screens('workout', (tester) async {
    final state = await _state(tester);
    final now = DateTime.now();
    await tester.runAsync(() async {
      await state.applyPlan(const PlanAnswers());
      await state.acceptConsent(
        adult: true,
        guardianConsent: false,
        welcomeVersion: whatsNewRelease,
        aiNotice: true,
      );
      await state.addBodyweight(78);
      for (final (daysAgo, kg) in [(9, 75.0), (5, 80.0), (2, 82.5)]) {
        final at = now.subtract(Duration(days: daysAgo));
        await state.startWorkout(now: at);
        final e = await state.addExercise('bench_press');
        e.sets = [
          SetEntry(weight: kg, reps: 8, done: true),
          SetEntry(weight: kg, reps: 7, done: true),
        ];
        await state.finishActive(now: at.add(const Duration(hours: 1)));
      }
    });
    await _pump(tester, state);
    await _tap(tester, find.textContaining('Začít').first);
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, 'workout');
    final checks = find.bySemanticsLabel('Potvrdit sérii');
    if (checks.evaluate().isNotEmpty) {
      await tester.tap(checks.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(checks.at(1), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 600));
    }
    await _shot(tester, 'workout-rest');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(tester, 'workout-2');
    final finish = find.text('Dokončit');
    if (finish.evaluate().isNotEmpty) {
      await tester.tap(finish.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));
      await _shot(tester, 'finish-dialog');
      final confirm = find.text('Dokončit');
      if (confirm.evaluate().length > 1) {
        await tester.runAsync(() async {
          await tester.tap(confirm.last, warnIfMissed: false);
          await Future<void>.delayed(const Duration(milliseconds: 400));
        });
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await _shot(tester, 'summary');
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await _shot(tester, 'summary-2');
      }
    }
  });
}
