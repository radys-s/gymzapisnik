import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/rpe.dart';
import 'package:gymzapisnik/domain/superset.dart';

WorkoutExercise ex(String id, {String? group, int pending = 1}) =>
    WorkoutExercise(
      id: id,
      exerciseId: id,
      sets: [for (var i = 0; i < pending; i++) SetEntry(weight: 20, reps: 8)],
      extra: group == null ? null : {supersetKey: group},
    );

void main() {
  test('slots group only adjacent exercises with the same id', () {
    final list = [
      ex('a', group: 'x'),
      ex('b', group: 'x'),
      ex('c'),
      ex('d', group: 'x'),
      ex('e', group: 'y'),
      ex('f', group: 'y'),
    ];
    final slots = supersetSlots(list);
    expect(slots, [
      const SupersetSlot(0, 0, 2),
      const SupersetSlot(0, 1, 2),
      null,
      null, // osamocený cvik se starým ID supersérií není
      const SupersetSlot(1, 0, 2),
      const SupersetSlot(1, 1, 2),
    ]);
    expect(slots[4]!.letter, 'B');
  });

  test('rest waits until the last exercise of the round', () {
    final a = ex('a', group: 'x');
    final b = ex('b', group: 'x');
    final list = [a, b];
    expect(restsAfter(list, a), isFalse);
    expect(nextInSuperset(list, a), same(b));
    expect(restsAfter(list, b), isTrue);
    // Když už má B vše potvrzené, odpočívá se i po A.
    b.sets.single.done = true;
    expect(restsAfter(list, a), isTrue);
    expect(nextInSuperset(list, a), isNull);
  });

  test('link joins the next exercise and merges its group', () {
    final list = [ex('a'), ex('b', group: 'y'), ex('c', group: 'y')];
    expect(linkWithNext(list, list[0], newId: 'n'), isTrue);
    expect(supersetSlots(list).every((s) => s?.size == 3), isTrue);
    expect(linkWithNext(list, list[2], newId: 'n'), isFalse);
  });

  test('unlinking from the middle splits or dissolves the group', () {
    final list = [for (final id in 'abcde'.split('')) ex(id, group: 'x')];
    unlink(list, list[2], newId: 'z');
    final slots = supersetSlots(list);
    expect(slots[2], isNull);
    expect(slots[0], const SupersetSlot(0, 0, 2));
    expect(slots[3], const SupersetSlot(1, 0, 2));

    final pair = [ex('a', group: 'x'), ex('b', group: 'x')];
    unlink(pair, pair[0], newId: 'z');
    expect(pair.every((e) => supersetId(e) == null), isTrue);
  });

  test('RPE labels', () {
    expect(formatRpe(8), '8');
    expect(formatRpe(7.5), '7,5');
    expect(rpeHint(10), contains('maximum'));
    expect(rpeHint(8), '2 opakování v zásobě');
    expect(rpeHint(8.5), '1–2 opakování v zásobě');
    expect(rpeHint(6), contains('Lehké'));
  });
}
