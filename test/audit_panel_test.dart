import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/data/database.dart';
import 'package:gymzapisnik/data/store.dart';
import 'package:gymzapisnik/state/app_state.dart';
import 'package:gymzapisnik/ui/program/audit_panel.dart';
import 'package:gymzapisnik/ui/program/program_editor_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('editor audit finds a missing short head and Přidat fixes it', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final state = AppState(LocalStore(db));
    await tester.runAsync(state.load);
    tester.view
      ..physicalSize = const Size(390, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const routine = SplitTemplate(
      id: 'arms',
      name: 'Ruce',
      description: '',
      perWeek: 1,
      days: [
        SplitDay('Ruce', [PlannedExercise('hammer_curl', sets: 3)]),
      ],
      custom: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        home: ProgramEditorPage(state, initial: routine),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuditPanel), findsOneWidget);
    expect(find.text('Biceps: chybí krátká hlava'), findsOneWidget);

    final row = find.ancestor(
      of: find.text('Biceps: chybí krátká hlava'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.text('Přidat')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biceps: chybí krátká hlava'), findsNothing);
  });
}
