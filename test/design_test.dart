import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  test('every accent builds a light and dark theme with the palette', () {
    for (final accent in Accent.values) {
      for (final b in Brightness.values) {
        final theme = buildTheme(b, accent);
        final p = theme.extension<AppPalette>()!;
        expect(theme.colorScheme.primary, accent.solid(b));
        expect(theme.scaffoldBackgroundColor, p.background);
        expect(p.gradient, hasLength(2));
      }
    }
  });

  test('profile defaults: system theme, lime accent, first tab', () {
    const p = Profile();
    expect(p.theme, 'system');
    expect(p.accent, 'lime');
    expect(p.welcomeSeen, isFalse);
    expect(p.lastTab, 0);
    final next = p.withExtra({
      'accent': 'sunset',
      'theme': 'dark',
      'lastTab': 1,
      'welcomeSeen': true,
    });
    expect(next.accent, 'sunset');
    expect(next.theme, 'dark');
    expect(next.lastTab, 1);
    expect(next.welcomeSeen, isTrue);
    expect(p.withExtra({'accent': 'neon'}).accent, 'lime');
    expect(Accent.parse('lagoon'), Accent.lagoon);
    expect(Accent.parse(null), Accent.lime);
  });

  testWidgets('grouped section, ring and buttons render in both themes', (
    tester,
  ) async {
    for (final b in Brightness.values) {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(b, Accent.sunset),
          home: Scaffold(
            body: ListView(
              children: [
                GroupedSection(
                  header: 'Sekce',
                  children: [
                    GroupedRow(
                      icon: Icons.timer_outlined,
                      title: 'Pauza',
                      value: '2 min',
                      onTap: () => tapped++,
                    ),
                    const GroupedRow(title: 'Bez akce'),
                  ],
                ),
                const ProgressRing(value: 0.5, child: Text('2/4')),
                PrimaryButton('Začít', onPressed: () => tapped++),
                const PrimaryButton('Vypnuto'),
                SecondaryButton('Jiný den', onPressed: () => tapped++),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pauza'));
      await tester.tap(find.text('Začít'));
      await tester.tap(find.text('Vypnuto'));
      await tester.tap(find.text('Jiný den'));
      expect(tapped, 3);
      expect(find.text('2/4'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(
        tester.getSize(find.text('Začít').hitTestable()).height,
        isNonZero,
      );
    }
  });

  testWidgets('confirmAction returns true only on confirm', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await confirmAction(
              context,
              title: 'Nahradit cvik?',
              confirm: 'Nahradit',
              destructive: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zrušit'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nahradit'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
