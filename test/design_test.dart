import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  test('every accent and look builds a light and dark theme', () {
    for (final accent in Accent.values) {
      for (final b in Brightness.values) {
        for (final look in Look.values) {
          final theme = buildTheme(b, accent, look);
          final p = theme.extension<AppPalette>()!;
          expect(theme.colorScheme.primary, p.accent);
          expect(theme.scaffoldBackgroundColor, p.background);
          expect(p.gradient, hasLength(3));
          expect(p.look, look.resolve(b));
        }
      }
    }
    // Automaticky: ve dne Aurora, v noci Studio.
    expect(Look.auto.resolve(Brightness.light), Look.aurora);
    expect(Look.auto.resolve(Brightness.dark), Look.studio);
  });

  test('profile defaults: dark theme, lime accent, first tab', () {
    const p = Profile();
    expect(p.theme, 'dark');
    expect(p.withExtra({'theme': 'system'}).theme, 'system');
    expect(p.weightStep, 2.5);
    expect(p.withExtra({'weightStep': 1.25}).weightStep, 1.25);
    expect(p.withExtra({'weightStep': 3}).weightStep, 2.5);
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
    // Dvě záložky ze starší verze: 1 byla Strava, teď 2.
    expect(next.lastTab, 2);
    expect(p.withExtra({'tab': 1}).lastTab, 1);
    expect(p.withExtra({'tab': 2, 'lastTab': 1}).lastTab, 2);
    expect(next.welcomeSeen, isTrue);
    expect(p.withExtra({'accent': 'bogus'}).accent, 'lime');
    expect(p.look, 'tensor');
    expect(p.withExtra({'look': 'pitwall'}).look, 'pitwall');
    expect(p.withExtra({'look': 'auto'}).look, 'auto');
    expect(p.withExtra({'look': 'studio'}).look, 'studio');
    expect(p.withExtra({'look': 'bogus'}).look, 'tensor');
    expect(Look.parse(null), Look.tensor);
    expect(Accent.parse('lagoon'), Accent.lagoon);
    expect(Accent.parse(null), Accent.lime);
  });

  test('race look is always dark with fixed race red', () {
    for (final accent in Accent.values) {
      for (final b in Brightness.values) {
        final p = buildTheme(b, accent, Look.pitwall).extension<AppPalette>()!;
        expect(p.pitwall, isTrue);
        expect(p.background, const Color(0xFF15151E));
        expect(p.cta, AppPalette.raceRed);
      }
    }
  });

  test('tensor is the default: always dark, fixed green, beveled cards', () {
    expect(Look.values.first, Look.tensor);
    expect(Look.tensor.fixed, isTrue);
    expect(Look.aurora.fixed, isFalse);
    for (final accent in Accent.values) {
      for (final b in Brightness.values) {
        final p = buildTheme(b, accent, Look.tensor).extension<AppPalette>()!;
        expect(p.tensor && p.telemetry, isTrue);
        expect(p.background, Colors.black);
        expect(p.cta, AppPalette.tensorGreen);
        expect(p.cardShape(), isA<BeveledRectangleBorder>());
      }
    }
    expect(
      appFrame(
        home: const SizedBox(),
        look: Look.tensor,
        theme: 'light',
      ).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('tensor shows one green segment per exercise, lit at once '
      'with reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.dark, Accent.lime, Look.tensor),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: StartLights(count: 4, caption: '4 cviky · ~40 min'),
          ),
        ),
      ),
    );
    final lit = tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.decoration is BoxDecoration &&
              (c.decoration! as BoxDecoration).color == AppPalette.tensorGreen,
        );
    expect(lit.length, 4);
    expect(find.text('4 cviky · ~40 min'), findsOneWidget);
  });

  testWidgets(
    'start lights light up in sequence, at once with reduced motion',
    (tester) async {
      int lit() => tester
          .widgetList<Container>(find.byType(Container))
          .where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color ==
                    const Color(0xFFFF1801),
          )
          .length;
      Widget app({required bool reduced}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const Scaffold(body: Center(child: StartLights())),
        ),
      );
      await tester.pumpWidget(app(reduced: false));
      expect(lit(), 0);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(lit(), inInclusiveRange(1, 4));
      await tester.pumpAndSettle();
      expect(lit(), 5);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app(reduced: true));
      expect(lit(), 5);
    },
  );

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
