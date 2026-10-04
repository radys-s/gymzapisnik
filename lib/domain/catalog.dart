import 'models.dart';

/// Najde cvik v katalogu nebo mezi vlastními cviky.
Exercise? findExercise(String id, Iterable<Exercise> custom) {
  for (final e in custom) {
    if (e.id == id) return e;
  }
  for (final e in builtInExercises) {
    if (e.id == id) return e;
  }
  return null;
}

/// Pořadí svalových partií ve výběru cviku.
const muscleGroups = [
  'Hrudník',
  'Záda',
  'Nohy',
  'Ramena',
  'Paže',
  'Střed těla',
  'Ostatní',
];

/// Vestavěný katalog cviků. ID se nesmí měnit (jsou v historii).
const builtInExercises = <Exercise>[
  Exercise(
    id: 'bench_press',
    name: 'Bench press',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'incline_press',
    name: 'Incline press',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'chest_press_machine',
    name: 'Chest press machine',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'pec_deck',
    name: 'Pec deck',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'cable_fly',
    name: 'Cable fly',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'squat',
    name: 'Barbell squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'leg_press',
    name: 'Leg press',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'hack_squat',
    name: 'Hack squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'leg_extension',
    name: 'Leg extension',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'leg_curl',
    name: 'Leg curl',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'romanian_deadlift',
    name: 'Romanian deadlift',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'calf_raise',
    name: 'Calf raise',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'deadlift',
    name: 'Deadlift',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'lat_pulldown',
    name: 'Lat pulldown',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'seated_row',
    name: 'Seated cable row',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'chest_supported_row',
    name: 'Chest-supported row',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'pull_up',
    name: 'Pull-up',
    muscle: 'Záda',
    type: ExerciseType.bodyweight,
  ),
  Exercise(
    id: 'shoulder_press',
    name: 'Shoulder press',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'lateral_raise',
    name: 'Lateral raise',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'reverse_pec_deck',
    name: 'Reverse pec deck',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'biceps_curl',
    name: 'Biceps curl',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'preacher_curl',
    name: 'Preacher curl',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'triceps_pushdown',
    name: 'Triceps pushdown',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'dips',
    name: 'Dips',
    muscle: 'Paže',
    type: ExerciseType.bodyweight,
  ),
  Exercise(
    id: 'ab_crunch',
    name: 'Ab crunch machine',
    muscle: 'Střed těla',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'dumbbell_bench_press',
    name: 'Dumbbell bench press',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'incline_dumbbell_press',
    name: 'Incline dumbbell press',
    muscle: 'Hrudník',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'push_up',
    name: 'Push-up',
    muscle: 'Hrudník',
    type: ExerciseType.bodyweight,
  ),
  Exercise(
    id: 'front_squat',
    name: 'Front squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'goblet_squat',
    name: 'Goblet squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'smith_squat',
    name: 'Smith machine squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'hip_thrust',
    name: 'Hip thrust',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'bulgarian_split_squat',
    name: 'Bulgarian split squat',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'walking_lunge',
    name: 'Walking lunge',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'seated_calf_raise',
    name: 'Seated calf raise',
    muscle: 'Nohy',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'barbell_row',
    name: 'Barbell row',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'dumbbell_row',
    name: 'One-arm dumbbell row',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'close_grip_pulldown',
    name: 'Close-grip lat pulldown',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'machine_row',
    name: 'Machine row',
    muscle: 'Záda',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'face_pull',
    name: 'Face pull',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'overhead_press',
    name: 'Barbell overhead press',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'dumbbell_shoulder_press',
    name: 'Dumbbell shoulder press',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'cable_lateral_raise',
    name: 'Cable lateral raise',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'rear_delt_fly',
    name: 'Rear delt dumbbell fly',
    muscle: 'Ramena',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'barbell_curl',
    name: 'Barbell curl',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'hammer_curl',
    name: 'Hammer curl',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'cable_curl',
    name: 'Cable curl',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'overhead_triceps_extension',
    name: 'Overhead triceps extension',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'skull_crusher',
    name: 'Skull crusher',
    muscle: 'Paže',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'cable_crunch',
    name: 'Cable crunch',
    muscle: 'Střed těla',
    type: ExerciseType.weighted,
  ),
  Exercise(
    id: 'hanging_leg_raise',
    name: 'Hanging leg raise',
    muscle: 'Střed těla',
    type: ExerciseType.bodyweight,
  ),
];
