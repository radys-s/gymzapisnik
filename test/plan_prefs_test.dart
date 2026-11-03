import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/nutrition_target.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/catalog.dart';

List<SplitDay> _days(PlanAnswers a, [String split = 'ppl']) => [
  for (final d in findSplit(split)!.days) personalizeDay(d, a),
];

Iterable<String> _ids(List<SplitDay> days) => [
  for (final d in days) ...d.exercises.map((e) => e.exerciseId),
];

void main() {
  test('answers survive JSON and old level maps to experience', () {
    const a = PlanAnswers(
      experience: Experience.half,
      place: TrainingPlace.home,
      focus: {'chest', 'glutes'},
      avoid: {Joint.knees},
      favorites: {'pull_up'},
      sex: Sex.female,
      heightCm: 168,
      birthYear: 2000,
      weightGoal: WeightGoal.lose,
    );
    final back = PlanAnswers.tryParse(a.toJson())!;
    expect(back.experience, Experience.half);
    expect(back.level, PlanLevel.beginner);
    expect(back.place, TrainingPlace.home);
    expect(back.focus, {'chest', 'glutes'});
    expect(back.avoid, {Joint.knees});
    expect(back.favorites, {'pull_up'});
    expect(back.sex, Sex.female);
    expect(back.heightCm, 168);
    expect(back.birthYear, 2000);
    expect(back.weightGoal, WeightGoal.lose);

    final old = PlanAnswers.tryParse({
      'days': 4,
      'minutes': 60,
      'level': 'advanced',
      'heightCm': 900,
      'focus': ['chest', 'nonsense'],
    })!;
    expect(old.experience, Experience.two);
    expect(old.level, PlanLevel.advanced);
    expect(old.heightCm, isNull);
    expect(old.focus, {'chest'});
  });

  test('favorite ids exist in the catalog', () {
    for (final id in favoriteChoices) {
      expect(findExercise(id, const []), isNotNull, reason: id);
    }
  });

  test('home and bodyweight plans use only available equipment', () {
    for (final place in [TrainingPlace.home, TrainingPlace.bodyweight]) {
      for (final split in ['ppl', 'full_body_3', 'upper_lower']) {
        final days = _days(PlanAnswers(place: place), split);
        for (final id in _ids(days)) {
          final e = findExercise(id, const [])!;
          expect(place.allows(e.equipment), isTrue, reason: '$place $id');
        }
        // Každý den má pořád co cvičit.
        for (final d in days) {
          expect(d.exercises, isNotEmpty, reason: '$place ${d.name}');
        }
      }
    }
  });

  test('spared joints swap out the exercises that load them', () {
    final days = _days(
      const PlanAnswers(avoid: {Joint.knees, Joint.lowerBack, Joint.shoulders}),
    );
    for (final id in _ids(days)) {
      final e = findExercise(id, const [])!;
      for (final j in Joint.values) {
        expect(j.stresses(e), isFalse, reason: '$j $id');
      }
    }
    expect(_ids(days), isNot(contains('squat')));
  });

  test('favorites replace an exercise for the same muscle', () {
    final plain = _ids(_days(const PlanAnswers()));
    expect(plain, contains('lat_pulldown'));
    final days = _days(const PlanAnswers(favorites: {'pull_up', 'deadlift'}));
    expect(_ids(days), contains('pull_up'));
    expect(_ids(days), contains('deadlift'));
    for (final d in days) {
      final ids = d.exercises.map((e) => e.exerciseId).toList();
      expect(ids.toSet().length, ids.length, reason: d.name);
    }
  });

  test('focus adds a set and a fresh beginner trains lighter', () {
    final base = findSplit('ppl')!.days.first;
    final boosted = personalizeDay(base, const PlanAnswers(focus: {'chest'}));
    expect(boosted.exercises.first.sets, base.exercises.first.sets + 1);
    expect(
      [for (final e in boosted.exercises.skip(1)) e.sets],
      [for (final e in base.exercises.skip(1)) e.sets],
    );

    final fresh = personalizeDay(
      base,
      const PlanAnswers(experience: Experience.fresh),
    );
    for (final e in fresh.exercises) {
      expect(e.sets, lessThanOrEqualTo(3));
      expect(e.repMin, greaterThanOrEqualTo(10));
      expect(e.repMax, greaterThan(e.repMin));
    }
  });

  test('calories use Mifflin-St Jeor when the body is known', () {
    final now = DateTime(2026, 6);
    final t = suggestTargets(
      kg: 80,
      goal: PlanGoal.muscle,
      adult: true,
      now: now,
      plan: const PlanAnswers(
        sex: Sex.male,
        heightCm: 180,
        birthYear: 2001,
        weightGoal: WeightGoal.keep,
      ),
    );
    // 10·80 + 6,25·180 − 5·25 + 5 = 1805; × 1,45 = 2617 → 2600.
    expect(t.kcal, 2600);
    expect(t.protein, 160);

    final cut = suggestTargets(
      kg: 80,
      goal: PlanGoal.fitness,
      adult: true,
      now: now,
      plan: const PlanAnswers(weightGoal: WeightGoal.lose),
    );
    // Bez výšky odhad 33 kcal/kg: 2640 − 400 = 2240 → 2250.
    expect(cut.kcal, 2250);
    // Při hubnutí aspoň 2 g/kg.
    expect(cut.protein, 160);

    final minor = suggestTargets(
      kg: 60,
      goal: PlanGoal.muscle,
      adult: false,
      plan: const PlanAnswers(weightGoal: WeightGoal.lose),
    );
    expect(minor.kcal, isNull);
    // Mladším cíl hubnutí nemění ani bílkoviny.
    final minorPlain = suggestTargets(
      kg: 60,
      goal: PlanGoal.muscle,
      adult: false,
    );
    expect(minor.protein, minorPlain.protein);
  });

  test('a favorite takes only a slot doing the same work', () {
    final plain = _ids(_days(const PlanAnswers()));
    final withPress = _ids(_days(const PlanAnswers(favorites: {'leg_press'})));
    // Leg press nevytlačí dřep.
    if (plain.contains('squat')) expect(withPress, contains('squat'));
    final fresh = personalizeDay(
      findSplit('ppl')!.days.first,
      const PlanAnswers(experience: Experience.fresh, focus: {'chest'}),
    );
    // I začátečník dostane sérii navíc pro partii, na kterou se zaměřil.
    expect(fresh.exercises.first.sets, 4);
  });
}
