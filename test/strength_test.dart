import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/strength.dart';

void main() {
  test('level follows bodyweight multiples', () {
    // 100 kg bench při 80 kg = 1,25× → mezi 1,0 a 1,5 = Pokročilý.
    final l = strengthLevel('bench_press', 100, 80, StrengthStandard.men)!;
    expect(l.label, 'Pokročilý');
    expect(l.nextLabel, 'Velmi pokročilý');
    expect(l.toNext, closeTo(20, 1e-9)); // 1,5 × 80 = 120
    expect(l.progress, closeTo(0.5, 1e-9));
  });

  test('women table is lower and top level has no next', () {
    final w = strengthLevel('bench_press', 60, 60, StrengthStandard.women)!;
    expect(w.label, 'Velmi pokročilý');
    final top = strengthLevel('squat', 300, 100, StrengthStandard.men)!;
    expect(top.label, 'Elita');
    expect(top.toNext, isNull);
    expect(top.progress, 1);
  });

  test('below first threshold, unknown exercise, missing data', () {
    expect(
      strengthLevel('deadlift', 50, 80, StrengthStandard.men)!.label,
      'Začínáš',
    );
    expect(strengthLevel('leg_press', 200, 80, StrengthStandard.men), isNull);
    expect(strengthLevel('squat', 100, 0, StrengthStandard.men), isNull);
    expect(StrengthStandard.parse('women'), StrengthStandard.women);
    expect(StrengthStandard.parse('x'), isNull);
  });
}
