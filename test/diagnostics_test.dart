import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/core/diagnostics.dart';
import 'package:gymzapisnik/ui/settings/diagnostics_page.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  setUp(Diagnostics.clear);

  test('keeps only the last 20 errors, newest first', () {
    for (var i = 0; i < 25; i++) {
      Diagnostics.record('chyba $i', where: 'test');
    }
    final entries = Diagnostics.entries;
    expect(entries, hasLength(Diagnostics.max));
    expect(entries.first.message, 'chyba 24');
    expect(entries.last.message, 'chyba 5');
    final report = Diagnostics.report(version: '1.0.0');
    expect(report, startsWith('Gym zápisník 1.0.0'));
    expect(report, contains('[test] chyba 24'));
  });

  test('repeated error is counted, not appended, and never throws', () {
    Diagnostics.record('stejná', where: 'kreslení');
    Diagnostics.record('stejná', where: 'kreslení');
    Diagnostics.record('x' * 1000, where: 'kreslení');
    expect(Diagnostics.entries, hasLength(2));
    expect(Diagnostics.entries.last.count, 2);
    expect(
      Diagnostics.entries.first.message.length,
      Diagnostics.maxMessage + 1,
    );
    expect(() => Diagnostics.record(_Broken()), returnsNormally);
    expect(Diagnostics.entries.first.message, '_Broken');
  });

  testWidgets('Diagnostika lists errors and clears them', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(theme: buildTheme(), home: const DiagnosticsPage()),
    );
    expect(find.text('Žádné chyby'), findsOneWidget);

    Diagnostics.record(StateError('rozbitý zápis'), where: 'zápis');
    await tester.pumpAndSettle();
    expect(find.text('Chyby od spuštění (1)'), findsOneWidget);
    expect(find.textContaining('rozbitý zápis'), findsOneWidget);

    await tester.tap(find.text('Vymazat'));
    await tester.pumpAndSettle();
    expect(find.text('Žádné chyby'), findsOneWidget);
  });
}

class _Broken {
  @override
  String toString() => throw StateError('rozbité toString');
}
