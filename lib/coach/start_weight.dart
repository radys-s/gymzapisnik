/// Startovní váha pro cvik, který uživatel dělá poprvé. Čistý Dart.
///
/// Konzervativní: radši lehčí první série a přidat, než zranění nebo
/// odchod z posilovny po prvním tréninku. Pokročilý začíná o polovinu výš.
library;

import 'plan_quiz.dart';

enum Gear { barbell, dumbbell, machine }

class StartLoad {
  final double kg;
  final Gear gear;
  const StartLoad(this.kg, this.gear);

  /// Prázdná olympijská osa.
  bool get emptyBar => gear == Gear.barbell && kg == 20;

  /// Popisek po předložce „na“: „začni na prázdné ose (20 kg)“.
  String get label {
    final w = _kg(kg);
    return switch (gear) {
      Gear.barbell when emptyBar => 'prázdné ose (20 kg)',
      Gear.barbell => 'ose $w kg',
      Gear.dumbbell => 'jednoručkách $w kg na ruku',
      Gear.machine => '$w kg',
    };
  }
}

String _kg(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(1).replaceAll('.', ',');

/// Kg pro začátečníka podle vestavěného cviku (jednoručky na ruku).
const _starts = <String, (double, Gear)>{
  // Osa
  'bench_press': (20, Gear.barbell),
  'incline_press': (20, Gear.barbell),
  'squat': (20, Gear.barbell),
  'front_squat': (20, Gear.barbell),
  'romanian_deadlift': (30, Gear.barbell),
  'deadlift': (40, Gear.barbell),
  'barbell_row': (20, Gear.barbell),
  'overhead_press': (20, Gear.barbell),
  'hip_thrust': (30, Gear.barbell),
  'shrug': (30, Gear.barbell),
  // Zátěž pod 20 kg se na olympijské ose nedá: lehčí cviky začínají
  // na prázdné ose (EZ osa v katalogu zatím není).
  'barbell_curl': (20, Gear.barbell),
  'skull_crusher': (20, Gear.barbell),
  'reverse_curl': (20, Gear.barbell),
  'smith_squat': (20, Gear.barbell),
  // Jednoručky
  'dumbbell_bench_press': (10, Gear.dumbbell),
  'incline_dumbbell_press': (8, Gear.dumbbell),
  'dumbbell_shoulder_press': (6, Gear.dumbbell),
  'dumbbell_row': (12, Gear.dumbbell),
  'lateral_raise': (4, Gear.dumbbell),
  'rear_delt_fly': (4, Gear.dumbbell),
  'biceps_curl': (6, Gear.dumbbell),
  'hammer_curl': (6, Gear.dumbbell),
  'incline_dumbbell_curl': (5, Gear.dumbbell),
  'preacher_curl': (6, Gear.dumbbell),
  'overhead_triceps_extension': (8, Gear.dumbbell),
  'goblet_squat': (12, Gear.dumbbell),
  'bulgarian_split_squat': (6, Gear.dumbbell),
  'walking_lunge': (6, Gear.dumbbell),
  // Stroje a kladky (nízké závaží)
  'chest_press_machine': (20, Gear.machine),
  'pec_deck': (20, Gear.machine),
  'cable_fly': (5, Gear.machine),
  'low_to_high_cable_fly': (5, Gear.machine),
  'leg_press': (50, Gear.machine),
  'hack_squat': (20, Gear.machine),
  'leg_extension': (20, Gear.machine),
  'leg_curl': (20, Gear.machine),
  'calf_raise': (30, Gear.machine),
  'seated_calf_raise': (15, Gear.machine),
  'calf_press': (50, Gear.machine),
  'lat_pulldown': (30, Gear.machine),
  'close_grip_pulldown': (30, Gear.machine),
  'seated_row': (30, Gear.machine),
  'machine_row': (30, Gear.machine),
  'chest_supported_row': (20, Gear.machine),
  'shoulder_press': (15, Gear.machine),
  'reverse_pec_deck': (15, Gear.machine),
  'face_pull': (10, Gear.machine),
  'cable_lateral_raise': (2.5, Gear.machine),
  'triceps_pushdown': (15, Gear.machine),
  'cable_curl': (10, Gear.machine),
  'cable_crunch': (20, Gear.machine),
  'ab_crunch': (15, Gear.machine),
};

/// Startovní zátěž, nebo `null` pro vlastní a neznámé cviky.
StartLoad? startLoad(String exerciseId, PlanLevel level) {
  final start = _starts[exerciseId];
  if (start == null) return null;
  final (kg, gear) = start;
  if (level == PlanLevel.beginner) return StartLoad(kg, gear);
  final step = gear == Gear.dumbbell ? 1.0 : 2.5;
  return StartLoad(((kg * 1.5) / step).round() * step, gear);
}
