import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/coach/routine_audit.dart';
import 'package:gymzapisnik/coach/splits.dart';
import 'package:gymzapisnik/domain/anatomy.dart';

SplitDay _day(String name, List<(String, int)> ex) => SplitDay(name, [
  for (final (id, sets) in ex) PlannedExercise(id, sets: sets),
]);

void main() {
  test('every exercise used here has anatomy', () {
    for (final f in dayFocuses) {
      for (final e in f.exercises) {
        expect(anatomyOf(e.exerciseId), isNotNull, reason: e.exerciseId);
      }
    }
  });

  test('biceps without a short-head exercise gets a finding with a fix', () {
    final days = [
      _day('Ruce', [('hammer_curl', 3), ('barbell_curl', 0)]),
    ];
    final found = auditRoutine(days);
    final short = found.where((f) => f.id == 'head-biceps_short');
    expect(short, hasLength(1));
    expect(short.single.title, 'Biceps: chybí krátká hlava');
    final fix = short.single.exerciseId!;
    expect(anatomyOf(fix)!.primary, contains('biceps_short'));

    // Navržený cvik nález vyřeší.
    final fixed = [
      _day('Ruce', [('hammer_curl', 3), (fix, 3)]),
    ];
    expect(
      auditRoutine(fixed).where((f) => f.id == 'head-biceps_short'),
      isEmpty,
    );
  });

  test('a full generated push/pull/legs week has no head gaps', () {
    final days = [
      dayFromFocuses(['chest', 'shoulders', 'triceps']),
      dayFromFocuses(['back', 'biceps']),
      dayFromFocuses(['legs', 'calves']),
      dayFromFocuses(['chest', 'shoulders', 'triceps']),
      dayFromFocuses(['back', 'biceps']),
      dayFromFocuses(['legs', 'calves']),
    ];
    final gaps = auditRoutine(days)
        .where((f) => f.kind == AuditKind.missingFocus);
    expect(gaps, isEmpty);
  });

  test('volume thresholds flag too little and too much', () {
    final low = auditRoutine([
      _day('A', [('bench_press', 3)]),
    ]);
    expect(low.map((f) => f.id), contains('low-chest'));

    final high = auditRoutine([
      _day('A', [
        ('bench_press', 6),
        ('incline_dumbbell_press', 6),
        ('cable_fly', 6),
        ('pec_deck', 6),
      ]),
    ]);
    expect(high.map((f) => f.id), contains('high-chest'));
    expect(high.map((f) => f.id), isNot(contains('low-chest')));
    expect(weeklyRange('chest'), (10, 22));
  });

  test('a missing major focus shows up only for multi-day routines', () {
    final arms = [
      _day('A', [('barbell_curl', 3)]),
      _day('B', [('triceps_pushdown', 3)]),
    ];
    final ids = auditRoutine(arms).map((f) => f.id);
    expect(ids, contains('focus-back'));
    expect(
      auditRoutine([arms.first]).map((f) => f.id),
      isNot(contains('focus-back')),
    );
  });

  test('suggestions respect what the gym has', () {
    final s = suggestFor(
      'biceps_short',
      taken: const {},
      allowed: (e) => e.id != 'preacher_curl',
    );
    expect(s, isNot('preacher_curl'));
  });
}
