import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/app.dart';
import 'package:gymzapisnik/domain/profile.dart';
import 'package:gymzapisnik/ui/design/components.dart';
import 'package:gymzapisnik/ui/theme.dart';

void main() {
  test('one dark gym look: black, green action, beveled cards', () {
    final theme = buildTheme();
    final p = theme.extension<AppPalette>()!;
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, p.accent);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(p.cta, AppPalette.green);
    expect(p.label, AppPalette.gymGrey);
    expect(p.gradient, AppPalette.training);
    expect(p.cardShape(), isA<BeveledRectangleBorder>());
    expect(appFrame(home: const SizedBox()).themeMode, ThemeMode.dark);
  });

  test('profile defaults: rest, weight step and first tab', () {
    const p = Profile();
    expect(p.weightStep, 2.5);
    expect(p.withExtra({'weightStep': 1.25}).weightStep, 1.25);
    expect(p.withExtra({'weightStep': 3}).weightStep, 2.5);
    expect(p.welcomeSeen, isFalse);
    expect(p.lastTab, 0);
    final next = p.withExtra({'lastTab': 1, 'welcomeSeen': true});
    // Dvě záložky ze starší verze: 1 byla Strava, teď 2.
    expect(next.lastTab, 2);
    expect(p.withExtra({'tab': 1}).lastTab, 1);
    expect(p.withExtra({'tab': 2, 'lastTab': 1}).lastTab, 2);
    expect(next.welcomeSeen, isTrue);
  });

  test('skew border is a parallelogram inside its rect', () {
    const r = Rect.fromLTWH(0, 0, 200, 50);
    final path = const SkewBorder().getOuterPath(r);
    expect(path.getBounds(), r);
    expect(path.contains(const Offset(2, 2)), isFalse);
    expect(path.contains(const Offset(100, 25)), isTrue);
    expect(path.contains(const Offset(198, 48)), isFalse);
  });

  testWidgets('start shows one green segment per exercise, lit at once '
      'with reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
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
              (c.decoration! as BoxDecoration).color == AppPalette.green,
        );
    expect(lit.length, 4);
    expect(find.text('4 cviky · ~40 min'), findsOneWidget);
  });

  testWidgets('grouped section, ring and buttons render', (tester) async {
    {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
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
        theme: buildTheme(),
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
