import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/recovery.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/home/recovery_card.dart';
import 'package:gymzapisnik/ui/theme.dart';
import 'package:gymzapisnik/ui/workout/builder_page.dart';

Workout _w(String id, DateTime end, Map<String, int> sets) =>
    Workout(
        id: id,
        name: id,
        startedAt: end.subtract(const Duration(hours: 1)),
        finishedAt: end,
      )
      ..exercises = [
        for (final MapEntry(key: ex, value: n) in sets.entries)
          WorkoutExercise(
            id: '$id-$ex',
            exerciseId: ex,
            sets: [
              for (var i = 0; i < n; i++)
                SetEntry(weight: 60, reps: 8, done: true),
              SetEntry(weight: 20, reps: 10, done: true, warmup: true),
            ],
          ),
      ];

void main() {
  final now = DateTime(2026, 10, 16, 18);

  test('nothing trained: everything ready', () {
    final r = recoveryByFocus(const [], now);
    expect(r.values.every((f) => f.isReady), isTrue);
    expect(r.length, 9);
  });

  test('heavy chest day: chest and triceps recover, legs ready', () {
    final r = recoveryByFocus([
      _w('a', now.subtract(const Duration(hours: 24)), {'bench_press': 6}),
    ], now);
    final chest = r['chest']!;
    expect(chest.isReady, isFalse);
    // 72 h po plném tréninku, 24 h uběhlo.
    expect(chest.readyAt, now.add(const Duration(hours: 48)));
    expect(chest.ready, closeTo(1 / 3, 0.01));
    // Triceps vedlejší: 3 série = poloviční zátěž, 48 h × 0,5 = 24 h.
    expect(r['triceps']!.isReady, isTrue);
    expect(r['legs']!.isReady, isTrue);
  });

  test('few sets recover sooner; old and running workouts ignored', () {
    final r = recoveryByFocus([
      _w('a', now.subtract(const Duration(hours: 20)), {'lateral_raise': 2}),
      _w('old', now.subtract(const Duration(days: 4)), {'squat': 8}),
      Workout(id: 'run', name: 'run', startedAt: now)
        ..exercises = [
          WorkoutExercise(
            id: 'x',
            exerciseId: 'squat',
            sets: [SetEntry(weight: 100, reps: 5, done: true)],
          ),
        ],
    ], now);
    // 2 série / 6 = 0,34 → 48 h × 0,34 ≈ 16 h, uběhlo 20 h.
    expect(r['shoulders']!.isReady, isTrue);
    expect(r['legs']!.isReady, isTrue);
  });

  test('custom exercise by group; future clock clamped; ratio scaled', () {
    final r = recoveryByFocus(
      [
        _w('a', now.add(const Duration(minutes: 5)), {'my_press': 6}),
        _w('b', now.subtract(const Duration(hours: 12)), {'lateral_raise': 3}),
      ],
      now,
      muscleOf: (id) => id == 'my_press' ? 'Hrudník' : '',
    );
    expect(r['chest']!.isReady, isFalse);
    expect(r['chest']!.readyAt, now.add(const Duration(hours: 72)));
    // Ramena: 3 série = 24 h, z toho 12 h uběhlo.
    expect(r['shoulders']!.ready, closeTo(0.5, 0.01));
  });

  test('never more than two big focuses', () {
    final r = recoveryByFocus([
      for (final ex in [
        'lateral_raise',
        'barbell_curl',
        'triceps_pushdown',
        'calf_raise',
        'ab_crunch',
      ])
        _w(ex, now.subtract(const Duration(hours: 2)), {ex: 6}),
    ], now);
    final picked = suggestFocuses(r, const {});
    expect(
      picked.where((f) => ['chest', 'back', 'legs', 'glutes'].contains(f)),
      hasLength(lessThanOrEqualTo(2)),
    );
  });

  test('suggestion skips tired focuses and prefers low weekly volume', () {
    final recovery = recoveryByFocus([
      _w('a', now.subtract(const Duration(hours: 12)), {
        'bench_press': 6,
        'overhead_press': 4,
      }),
    ], now);
    final picked = suggestFocuses(recovery, {'back': 12, 'legs': 4});
    expect(picked, isNot(contains('chest')));
    expect(picked, isNot(contains('shoulders')));
    // Dvě velké s nejmenším objemem (hýždě 0, nohy 4), pak malá.
    expect(picked, ['glutes', 'legs', 'biceps']);
  });

  testWidgets('panel shows tired focus and builds from rested ones', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    final start = now.subtract(const Duration(hours: 26));
    await tester.runAsync(() async {
      await state.load();
      await state.startWorkout(now: start);
      final e = await state.addExercise('bench_press');
      e.sets = [
        for (var i = 0; i < 6; i++) SetEntry(weight: 60, reps: 8, done: true),
      ];
      await state.finishActive(now: start.add(const Duration(hours: 1)));
    });
    List<String>? built;
    List<String>? avoid;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: RecoveryPanel(
            state: state,
            now: now,
            onBuild: (f, a) {
              built = f;
              avoid = a;
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('Regeneruje: Hrudník za 47 h'), findsOneWidget);
    expect(find.bySemanticsLabel('Záda, odpočaté'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Hrudník, regeneruje, za 47 h'),
      findsOneWidget,
    );
    // Detail partie: unavená nenabízí trénink, odpočatá ano.
    await tester.tap(find.bySemanticsLabel('Hrudník, regeneruje, za 47 h'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ještě regeneruje'), findsOneWidget);
    expect(find.textContaining('6 pracovních sérií'), findsOneWidget);
    expect(find.textContaining('Sestavit trénink:'), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Záda, odpočaté'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sestavit trénink: Záda'));
    await tester.pumpAndSettle();
    expect(built, ['back']);
    expect(avoid, contains('chest'));
    expect(find.textContaining('Návrh: Záda, Nohy'), findsOneWidget);
    await tester.tap(find.text('Sestavit z odpočatých'));
    expect(built, ['back', 'legs', 'shoulders']);
    expect(avoid, contains('chest'));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: WorkoutBuilderPage(state, initialFocuses: built!),
      ),
    );
    await tester.pumpAndSettle();
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Záda'),
    );
    expect(chip.selected, isTrue);
    expect(find.text('Vyber aspoň jednu partii'), findsNothing);

    // Úzký displej a velké písmo: nic nepřeteče, partie z obou stran
    // čtečka hlásí jednou.
    tester.view.physicalSize = const Size(320, 1600);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 1600),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: RecoveryPanel(state: state, now: now, onBuild: (_, _) {}),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Nohy, odpočaté'), findsOneWidget);
  });
}
