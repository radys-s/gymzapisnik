import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/anatomy.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';

void main() {
  test('every built-in exercise has anatomy with known heads', () {
    for (final e in builtInExercises) {
      final a = anatomyOf(e.id);
      expect(a, isNotNull, reason: e.id);
      for (final h in [...a!.primary, ...a.secondary]) {
        expect(headById(h), isNotNull, reason: '${e.id}: $h');
      }
      // Hlavní hlava patří do partie cviku.
      expect(headById(a.primary.first)!.group, e.muscle, reason: e.id);
    }
    expect(exerciseAnatomy.keys.toSet(), {
      for (final e in builtInExercises) e.id,
    });
  });

  test('every head has at least two exercises to choose from', () {
    for (final h in muscleHeads) {
      final n = builtInExercises
          .where((e) => anatomyOf(e.id)!.primary.contains(h.id))
          .length;
      // Šikmý sval lýtka má v posilovně jen sedavý výpon.
      expect(
        n,
        greaterThanOrEqualTo(h.id == 'calves_soleus' ? 1 : 2),
        reason: h.id,
      );
    }
  });

  test('alternatives start with the same head, then other heads', () {
    final s = alternativesFor('lateral_raise', builtInExercises);
    expect(s.first.title, 'Stejná hlava: Boční delt');
    expect(s.first.exercises.map((e) => e.id), ['cable_lateral_raise']);
    final titles = s.map((x) => x.title).toList();
    expect(titles, containsAll(['Přední delt', 'Zadní delt']));
    final ids = [for (final x in s) ...x.exercises.map((e) => e.id)];
    expect(ids, isNot(contains('lateral_raise')));
    expect(ids.toSet().length, ids.length); // žádný cvik dvakrát
  });

  test('alternatives prefer the same kind of exercise', () {
    final same = alternativesFor('bench_press', builtInExercises).first;
    // Vícekloubové před izolovanými.
    final kinds = same.exercises.map((e) => anatomyOf(e.id)!.compound);
    expect(kinds.first, isTrue);
    expect(kinds.last, isFalse);
  });

  test('custom exercise gets alternatives from its muscle group', () {
    const custom = Exercise(
      id: 'c1',
      name: 'Můj tlak',
      muscle: 'Hrudník',
      custom: true,
    );
    final s = alternativesFor('c1', [custom, ...builtInExercises]);
    expect(s.map((x) => x.title), contains('Horní hrudník'));
    expect(
      [for (final x in s) ...x.exercises].every((e) => e.muscle == 'Hrudník'),
      isTrue,
    );
  });

  test('built day has the asked count, compound first, varied heads', () {
    final day = buildDay(['shoulders'], 3);
    expect(day.name, 'Ramena');
    final ids = day.exercises.map((p) => p.exerciseId).toList();
    expect(ids, hasLength(3));
    expect(anatomyOf(ids.first)!.compound, isTrue);
    final heads = {for (final id in ids) anatomyOf(id)!.primary.first};
    expect(heads, {'delt_front', 'delt_side', 'delt_rear'});
  });

  test('built day splits exercises between groups', () {
    final day = buildDay(['chest', 'triceps'], 5);
    expect(day.name, 'Hrudník a triceps');
    final ids = day.exercises.map((p) => p.exerciseId).toList();
    expect(ids, hasLength(5));
    expect(ids.toSet().length, 5);
    final chest = ids.where((id) => findExercise(id, [])!.muscle == 'Hrudník');
    expect(chest.length, 3);
    final heads = {for (final id in chest) anatomyOf(id)!.primary.first};
    expect(heads, containsAll(['chest_upper', 'chest_mid']));
    // Vícekloubové cviky jsou na začátku.
    final firstIso = ids.indexWhere((id) => !anatomyOf(id)!.compound);
    expect(ids.skip(firstIso).every((id) => !anatomyOf(id)!.compound), isTrue);
  });

  test('buildDay skips exercises loading tired focuses', () {
    final ids = buildDay(
      ['back'],
      4,
      avoidFocuses: ['glutes', 'legs'],
    ).exercises.map((e) => e.exerciseId);
    expect(ids, isNotEmpty);
    expect(ids, isNot(contains('deadlift')));
    // Partie, kterou uživatel sám vybral, se nevynechává.
    final picked = buildDay(
      ['back', 'glutes'],
      6,
      avoidFocuses: ['glutes'],
    ).exercises.map((e) => e.exerciseId);
    expect(
      picked.any((id) => anatomyOf(id)!.primary.contains('glutes')),
      isTrue,
    );
  });

  test('built day handles limits', () {
    expect(buildDay([], 4).exercises, isEmpty);
    expect(buildDay(['chest'], 0).exercises, isEmpty);
    expect(buildDay(['core'], 9).exercises, hasLength(4)); // víc jich není
    expect(
      buildDay(focusHeads.keys, 50).exercises,
      hasLength(maxBuiltExercises),
    );
    // Méně cviků než partií: první partie dostanou po jednom.
    final two = buildDay(['chest', 'back', 'legs'], 2);
    expect(two.exercises, hasLength(2));
    // Název jen z partií, které cviky opravdu dostaly.
    expect(two.name, 'Hrudník a záda');
    // Partii dojdou cviky: zbytek dostane ta druhá.
    final calvesCore = buildDay(['calves', 'core'], 8);
    final core = buildDay(['core'], 10).exercises.length;
    final calves = buildDay(['calves'], 10).exercises.length;
    expect(calvesCore.exercises, hasLength((core + calves).clamp(0, 8)));
  });
}
