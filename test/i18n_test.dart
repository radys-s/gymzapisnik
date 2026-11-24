import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/core/i18n.dart';
import 'package:gymzapisnik/domain/technique.dart';

void main() {
  tearDown(() => appLang = AppLang.cs);

  test('technique follows a language switch', () {
    appLang = AppLang.cs;
    expect(techniqueOf('bench_press')!.steps.first, startsWith('Lehni'));
    appLang = AppLang.en;
    expect(techniqueOf('bench_press')!.steps.first, startsWith('Lie'));
  });

  test('retired and unknown codes fall back to Czech', () {
    expect(AppLang.parse('sk'), AppLang.cs);
    expect(AppLang.parse(null), AppLang.cs);
    expect(AppLang.parse('en'), AppLang.en);
  });
}
