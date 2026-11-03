import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/last_delta.dart';
import 'package:gymzapisnik/domain/models.dart';

SetEntry s(double w, int r, {bool done = true, bool warmup = false}) =>
    SetEntry(weight: w, reps: r, done: done, warmup: warmup);

void main() {
  test('bez minulých sérií se nic nesrovnává', () {
    expect(compareToLast([s(60, 5)], []), isNull);
    expect(compareToLast([s(60, 5)], [s(60, 5, done: false)]), isNull);
  });

  test('nejtěžší série a objem ignorují rozcvičku a nepotvrzené', () {
    final d = compareToLast(
      [s(40, 10, warmup: true), s(62.5, 5), s(62.5, 4, done: false)],
      [s(40, 10, warmup: true), s(60, 5), s(60, 6)],
    )!;
    expect(d.lastTop.weight, 60);
    expect(d.lastTop.reps, 6);
    expect(d.lastVolume, 660);
    expect(d.nowTop!.weight, 62.5);
    expect(d.nowVolume, 312.5);
  });

  test('dnes ještě nic potvrzeno', () {
    final d = compareToLast([s(60, 5, done: false)], [s(60, 5)])!;
    expect(d.nowTop, isNull);
    expect(d.nowVolume, 0);
  });

  test('počítá započítané série dnes a minule', () {
    final d = compareToLast([s(50, 5)], [s(60, 5), s(60, 5)])!;
    expect(d.nowSets, 1);
    expect(d.lastSets, 2);
  });
}
