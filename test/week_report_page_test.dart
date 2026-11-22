import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/progress/week_report_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

Workout _w(String id, DateTime end, double kg, int sets) => Workout(
  id: id,
  name: id,
  startedAt: end.subtract(const Duration(minutes: 55)),
  finishedAt: end,
  exercises: [
    WorkoutExercise(
      id: '$id-bench',
      exerciseId: 'bench_press',
      sets: [
        for (var i = 0; i < sets; i++)
          SetEntry(weight: kg, reps: 5, done: true),
      ],
    ),
  ],
);

void main() {
  testWidgets('shows the week, records and goes back a week', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    // Čtvrtek 19. 11. 2026; pondělí týdne je 16. 11.
    final now = DateTime(2026, 11, 19, 20);
    await tester.runAsync(() async {
      await state.restoreWorkout(_w('old', DateTime(2026, 11, 10, 18), 80, 3));
      await state.restoreWorkout(_w('new', DateTime(2026, 11, 17, 18), 85, 4));
    });
    tester.view
      ..physicalSize = const Size(390, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: WeekReportPage(state, now: () => now),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tento týden'), findsOneWidget);
    expect(find.text('16.–22. 11.'), findsOneWidget);
    expect(find.text('1\u00a0700 kg'), findsOneWidget);
    // 1 700 proti 1 200 kg minulý týden.
    expect(find.text('42 %'), findsOneWidget);
    expect(find.text('85 kg'), findsOneWidget);
    expect(find.text('Cvik týdne'), findsOneWidget);

    // Dopředu do budoucnosti to nejde.
    final forward = find.byTooltip('Další týden');
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: forward, matching: find.byType(IconButton)).first,
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Předchozí týden'));
    await tester.pumpAndSettle();
    expect(find.text('9.–15. 11.'), findsOneWidget);
    expect(find.text('1\u00a0200 kg'), findsOneWidget);
    expect(find.text('Rekordy týdne'), findsOneWidget);
    // První týden historie: dál zpátky to nepustí.
    await tester.tap(find.byTooltip('Předchozí týden'));
    await tester.pumpAndSettle();
    expect(find.text('9.–15. 11.'), findsOneWidget);
  });
}
