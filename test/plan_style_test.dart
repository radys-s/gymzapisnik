import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/evidence.dart';
import 'package:gymzapisnik/coach/plan_quiz.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/catalog.dart';

void main() {
  String split(PlanStyle style, int days) =>
      recommendPlan(PlanAnswers(style: style, days: days)).splitId;

  test('each style maps every day count to a real template', () {
    for (final style in PlanStyle.values) {
      for (var d = 2; d <= 6; d++) {
        final id = split(style, d);
        expect(findSplit(id), isNotNull, reason: '$style $d → $id');
      }
    }
  });

  test('styles pick their own plans', () {
    expect(split(PlanStyle.science, 3), 'science_full_body');
    expect(split(PlanStyle.science, 4), 'science_upper_lower');
    expect(split(PlanStyle.oldSchool, 3), 'basics_5x5');
    expect(split(PlanStyle.oldSchool, 5), 'bro_split');
    expect(split(PlanStyle.strength, 3), 'strength_sbd');
    expect(
      recommendPlan(const PlanAnswers(style: PlanStyle.strength)).restSeconds,
      180,
    );
  });

  test('answers without a style keep the original mapping', () {
    expect(recommendPlan(const PlanAnswers(days: 4)).splitId, 'upper_lower');
  });

  test('style survives a save', () {
    const a = PlanAnswers(style: PlanStyle.oldSchool);
    expect(PlanAnswers.tryParse(a.toJson())!.style, PlanStyle.oldSchool);
    expect(PlanAnswers.tryParse(const PlanAnswers().toJson())!.style, isNull);
  });

  test('style templates and evidence use catalog exercises', () {
    for (final t in styleTemplates) {
      expect(programError(t), isNull, reason: t.id);
      for (final d in t.days) {
        for (final e in d.exercises) {
          expect(
            findExercise(e.exerciseId, const []),
            isNotNull,
            reason: '${t.id} ${e.exerciseId}',
          );
        }
      }
    }
    for (final id in exerciseEvidence.keys) {
      expect(findExercise(id, const []), isNotNull, reason: id);
    }
  });

  test('every science plan exercise that has a stretch rationale shows it', () {
    final t = findSplit('science_upper_lower')!;
    final ids = [
      for (final d in t.days) ...d.exercises.map((e) => e.exerciseId),
    ];
    expect(
      ids.where((id) => evidenceFor(id) != null).length,
      greaterThanOrEqualTo(6),
    );
  });
}
