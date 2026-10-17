import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/ui/ideas/ideas_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  testWidgets('ideas page lists every group without overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(Brightness.dark), home: const IdeasPage()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Supersety a drop sety'), findsOneWidget);
    expect(ideaGroups.expand((g) => g.$3).length, greaterThan(15));
  });
}
