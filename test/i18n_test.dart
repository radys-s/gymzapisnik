import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/core/i18n.dart';
import 'package:gymzapisnik/domain/stats.dart';
import 'package:gymzapisnik/domain/technique.dart';

void main() {
  tearDown(() => appLang = AppLang.cs);

  test('technique follows a language switch', () {
    appLang = AppLang.cs;
    expect(techniqueOf('bench_press')!.steps.first, startsWith('Lehni'));
    appLang = AppLang.en;
    expect(techniqueOf('bench_press')!.steps.first, startsWith('Lie'));
  });

  test('split descriptions and record labels follow a language switch', () {
    appLang = AppLang.cs;
    final csDescription = findSplit('ppl')!.description;
    final csLabel = RecordKind.maxWeight.label;
    expect(csDescription, contains('Tlaky'));
    expect(csLabel, 'Max váha');

    appLang = AppLang.en;
    final enDescription = findSplit('ppl')!.description;
    final enLabel = RecordKind.maxWeight.label;
    expect(enDescription, isNot(csDescription));
    expect(enDescription, contains('Push'));
    expect(enLabel, isNot(csLabel));
    expect(enLabel, 'Max weight');
  });

  test('retired and unknown codes fall back to Czech', () {
    expect(AppLang.parse('sk'), AppLang.cs);
    expect(AppLang.parse(null), AppLang.cs);
    expect(AppLang.parse('en'), AppLang.en);
  });
}
