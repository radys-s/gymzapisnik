import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/data/hevy_import.dart';
import 'package:gymzapisnik/domain/catalog.dart';
import 'package:gymzapisnik/domain/models.dart';
import 'package:gymzapisnik/domain/technique.dart';
import 'package:gymzapisnik/core/text.dart';
import 'package:gymzapisnik/ui/workout/exercise_picker.dart';

/// ID z verze 1.0.0-beta.10: jsou v historii uživatelů, nesmí zmizet.
const _oldIds = [
  'bench_press',
  'incline_press',
  'chest_press_machine',
  'pec_deck',
  'cable_fly',
  'squat',
  'leg_press',
  'hack_squat',
  'leg_extension',
  'leg_curl',
  'romanian_deadlift',
  'calf_raise',
  'deadlift',
  'lat_pulldown',
  'seated_row',
  'chest_supported_row',
  'pull_up',
  'shoulder_press',
  'lateral_raise',
  'reverse_pec_deck',
  'biceps_curl',
  'preacher_curl',
  'triceps_pushdown',
  'dips',
  'ab_crunch',
  'dumbbell_bench_press',
  'incline_dumbbell_press',
  'push_up',
  'front_squat',
  'goblet_squat',
  'smith_squat',
  'hip_thrust',
  'bulgarian_split_squat',
  'walking_lunge',
  'seated_calf_raise',
  'barbell_row',
  'dumbbell_row',
  'close_grip_pulldown',
  'machine_row',
  'face_pull',
  'overhead_press',
  'dumbbell_shoulder_press',
  'cable_lateral_raise',
  'rear_delt_fly',
  'barbell_curl',
  'hammer_curl',
  'cable_curl',
  'overhead_triceps_extension',
  'skull_crusher',
  'cable_crunch',
  'hanging_leg_raise',
  'incline_dumbbell_curl',
  'low_to_high_cable_fly',
  'shrug',
  'back_extension',
  'calf_press',
  'reverse_curl',
  'lying_leg_raise',
];

const _header =
    'title,start_time,end_time,description,exercise_title,superset_id,'
    'exercise_notes,set_index,set_type,weight_kg,reps,distance_km,'
    'duration_seconds,rpe';

String _row(String exercise) =>
    'A,"15 Jul 2026, 09:00","15 Jul 2026, 10:00",,$exercise,,,0,normal,'
    '20,10,,,';

List<Exercise> _search(String q) =>
    builtInExercises.where((e) => matchesExercise(e, fold(q))).toList();

void main() {
  test('old ids survive and the library is big', () {
    final ids = builtInExercises.map((e) => e.id).toSet();
    expect(ids, containsAll(_oldIds));
    expect(ids.length, builtInExercises.length);
    expect(builtInExercises.length, greaterThanOrEqualTo(130));
  });

  test('every exercise has equipment, pattern and a name with equipment', () {
    for (final e in builtInExercises) {
      // Kolečko na břicho nemá vlastní kategorii vybavení.
      if (e.id != 'ab_wheel') {
        expect(e.equipment, isNot(Equipment.other), reason: e.id);
      }
      expect(e.pattern, isNotEmpty, reason: e.id);
      expect(e.name, contains('('), reason: e.id);
      expect(techniqueOf(e.id), isNotNull, reason: e.id);
    }
  });

  test('search finds machines by Czech and English names', () {
    expect(_search('addukt').map((e) => e.id), contains('hip_adduction'));
    expect(_search('adductor').map((e) => e.id), contains('hip_adduction'));
    expect(_search('pec deck').map((e) => e.id), contains('pec_deck'));
    expect(_search('PRITAHOVACE').map((e) => e.id), contains('hip_adduction'));
    expect(
      _search('lat pulldown').map((e) => e.id),
      contains('machine_pulldown'),
    );
    expect(_search(''), hasLength(builtInExercises.length));
  });

  test('Hevy names map to the right equipment variant', () {
    final r = parseHevyCsv(
      '$_header\n'
      '${_row('Hip Adduction (Machine)')}\n'
      '${_row('Hip Abduction (Machine)')}\n'
      '${_row('Lat Pulldown (Machine)')}\n'
      '${_row('Lat Pulldown (Cable)')}\n'
      '${_row('Lateral Raise (Dumbbell)')}\n'
      '${_row('Lateral Raise (Cable)')}\n',
    );
    final ids = r.workouts.single.exercises.map((e) => e.exerciseId).toList();
    expect(ids, [
      'hip_adduction',
      'hip_abduction',
      'machine_pulldown',
      'lat_pulldown',
      'lateral_raise',
      'cable_lateral_raise',
    ]);
    expect(r.newExercises, isEmpty);
  });

  test('Hevy variant with unknown equipment becomes its own exercise', () {
    final r = parseHevyCsv(
      '$_header\n'
      '${_row('Bicep Curl (Machine)')}\n'
      '${_row('Deadlift')}\n',
    );
    final ids = r.workouts.single.exercises.map((e) => e.exerciseId).toList();
    expect(ids.last, 'deadlift');
    expect(r.newExercises.map((e) => e.name), ['Bicep Curl (Machine)']);
    expect(ids.first, r.newExercises.single.id);
  });

  test(
    'custom exercise keeps equipment through JSON, old JSON reads as other',
    () {
      const e = Exercise(
        id: 'custom_1',
        name: 'Můj stroj',
        muscle: 'Nohy',
        custom: true,
        equipment: Equipment.machine,
      );
      final back = Exercise.fromJson(e.toJson());
      expect(back.equipment, Equipment.machine);
      expect(
        Exercise.fromJson({'id': 'c', 'name': 'x', 'muscle': 'Nohy'}).equipment,
        Equipment.other,
      );
    },
  );
}
