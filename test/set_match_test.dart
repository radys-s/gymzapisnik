import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/set_match.dart';

SetEntry w(double kg, int reps) => SetEntry(weight: kg, reps: reps);
SetEntry r(double kg, int reps) =>
    SetEntry(weight: kg, reps: reps, warmup: true);

void main() {
  group('previousSets', () {
    test('warm-up never shows working weight and does not shift sets', () {
      final last = [r(40, 10), w(80, 8), w(80, 7)];
      // Dnes bez rozcvičky: pracovní série 1 ukazuje pracovní 80×8.
      final prev = previousSets([w(80, 8), w(80, 8)], last);
      expect([for (final s in prev) s?.weight], [80, 80]);
      expect(prev.first?.reps, 8);
      expect(prev.last?.reps, 7);
    });

    test('extra warm-up today matches nothing past last warm-ups', () {
      final last = [w(80, 8)];
      final prev = previousSets([r(40, 10), r(60, 5), w(80, 8)], last);
      expect(prev[0], isNull);
      expect(prev[1], isNull);
      expect(prev[2]?.weight, 80);
    });

    test('more sets than last time get no previous value', () {
      final prev = previousSets([w(80, 8), w(80, 8)], [w(80, 8)]);
      expect(prev.last, isNull);
    });
  });

  group('nextWorkingSet', () {
    test('takes last time value at the same working position', () {
      final last = [r(40, 10), w(80, 8), w(82.5, 6)];
      final next = nextWorkingSet([r(40, 10), w(80, 8)], last);
      expect(
        (next.weight, next.reps, next.warmup, next.done),
        (82.5, 6, false, false),
      );
    });

    test('copies the last working set when last time had fewer sets', () {
      final current = [w(90, 5)..done = true, r(40, 10)];
      final next = nextWorkingSet(current, [w(80, 8)]);
      expect(
        (next.weight, next.reps, next.warmup, next.done),
        (90, 5, false, false),
      );
    });

    test('copies a warm-up as working when nothing else exists', () {
      final next = nextWorkingSet([r(40, 10)], const []);
      expect((next.weight, next.reps, next.warmup), (40, 10, false));
    });

    test('empty exercise gives an empty set', () {
      final next = nextWorkingSet(const [], const []);
      expect((next.weight, next.reps), (0, 0));
    });
  });
}
