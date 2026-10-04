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

  test('custom exercise wins over catalog lookup order', () {
    const custom = Exercise(
      id: 'my_row',
      name: 'Můj přítah',
      muscle: 'Záda',
      custom: true,
    );
    expect(findExercise('my_row', [custom])!.name, 'Můj přítah');
    expect(findExercise('bench_press', const [])!.name, 'Bench press');
    expect(findExercise('missing', const []), isNull);
  });
}
