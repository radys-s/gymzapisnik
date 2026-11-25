import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';

void main() {
  test('catalog ids are unique and muscles are known', () {
    final ids = builtInExercises.map((e) => e.id).toSet();
    expect(ids.length, builtInExercises.length);
    for (final e in builtInExercises) {
      expect(muscleGroups, contains(e.muscle), reason: e.id);
    }
  });

  test('visible exercise names are unique and Title Case', () {
    const connectors = {'to', 'of', 'and', 'with', 'on', 'in', 'the'};
    final wordPattern = RegExp(r"[A-Za-z]+(?:'[A-Za-z]+)?");
    final seen = <String>{};
    for (final e in builtInExercises) {
      if (e.extra['hidden'] == true) continue;
      expect(seen.add(e.name.toLowerCase()), isTrue, reason: e.name);
      expect(
        e.name.contains('\u2018') || e.name.contains('\u2019'),
        isFalse,
        reason: e.id,
      );
      for (final match in wordPattern.allMatches(e.name)) {
        final word = match.group(0)!;
        if (connectors.contains(word.toLowerCase())) continue;
        expect(word[0], word[0].toUpperCase(), reason: '${e.id}: $word');
      }
    }
  });

  test('custom exercise wins over catalog lookup order', () {
    const custom = Exercise(
      id: 'my_row',
      name: 'Můj přítah',
      muscle: 'Záda',
      custom: true,
    );
    expect(findExercise('my_row', [custom])!.name, 'Můj přítah');
    expect(findExercise('bench_press', const [])!.name, 'Barbell Bench Press');
    expect(findExercise('missing', const []), isNull);
  });
}
