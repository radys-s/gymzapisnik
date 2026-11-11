/// Podrobnější odpovědi z úvodu: jak dlouho kdo cvičí, kde, na co se
/// chce zaměřit a čemu se vyhnout. Podle nich se plán přizpůsobí.
/// Čistý Dart bez Flutteru.
library;

import '../domain/anatomy.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import 'splits.dart';
import 'tips.dart';

/// Jak dlouho už pravidelně cvičí. Rozlišuje víc než jen začátečník
/// a pokročilý: první měsíce rostou váhy rychle, po letech pomalu.
enum Experience {
  fresh('Teprve začínám', 'Necvičím, nebo jen pár týdnů', 0),
  quarter('Čtvrt roku', 'Cviky znám, technika se usazuje', 3),
  half('Půl roku', 'Cvičím pravidelně, váhy pořád rostou', 6),
  year('Rok', 'Mám své váhy, zlepšuju se pomaleji', 12),
  two('Dva roky', 'Vím, co mi sedí, pokrok je pomalý', 24),
  more('Víc než dva roky', 'Zkušený, hledám další posun', 36);

  final String label;
  final String hint;

  /// Přibližná délka cvičení v měsících.
  final int months;
  const Experience(this.label, this.hint, this.months);

  static Experience? tryParse(Object? v) =>
      values.where((e) => e.name == v).firstOrNull;
}

/// Kde cvičí: určuje, jaké vybavení plán smí použít.
enum TrainingPlace {
  gym('Velké fitko', 'Extrifit, Form Factory a podobné: všechny stroje'),
  smallGym('Menší fitko', 'Osa, jednoručky, kladky a základní stroje'),
  home('Doma s činkami', 'Jednoručky, kettlebell, gumy a lavička'),
  bodyweight('Jen vlastní váha', 'Bez vybavení, nanejvýš guma');

  final String label;
  final String hint;
  const TrainingPlace(this.label, this.hint);

  static TrainingPlace parse(Object? v) =>
      values.where((p) => p.name == v).firstOrNull ?? gym;

  /// Stroje, které menší fitko obvykle nemá. Uživatel si je v Moje
  /// posilovna může zaškrtnout zpátky.
  Set<String> get presetMissing => switch (this) {
    smallGym => smallGymMissing,
    _ => const {},
  };

  bool allows(Equipment e) => switch (this) {
    gym || smallGym => true,
    home => const {
      Equipment.dumbbell,
      Equipment.kettlebell,
      Equipment.band,
      Equipment.bodyweight,
      Equipment.plate,
    }.contains(e),
    bodyweight => e == Equipment.bodyweight || e == Equipment.band,
  };
}

/// Kloub, který bolí nebo se má šetřit.
enum Joint {
  knees('Kolena', {'squat', 'sumo_squat', 'lunge', 'step_up', 'leg_ext'}),
  lowerBack('Spodní záda', {
    'hinge',
    'good_morning',
    'row_bent',
    'swing',
    'back_ext',
  }),
  shoulders('Ramena', {'push_vertical', 'dip', 'bench_dip', 'upright_row'});

  final String label;

  /// Pohybové vzory, které kloub nejvíc zatěžují.
  final Set<String> patterns;
  const Joint(this.label, this.patterns);

  static Set<Joint> parseAll(Object? v) => {
    if (v is List)
      for (final x in v) ?values.where((j) => j.name == x).firstOrNull,
  };

  bool stresses(Exercise e) =>
      patterns.contains(e.pattern) ||
      // Dřep s osou na zádech zatěžuje i bedra.
      (this == lowerBack &&
          e.pattern == 'squat' &&
          e.equipment == Equipment.barbell);
}

/// Pohlaví pro odhad energie; nepovinné.
enum Sex {
  male('Muž'),
  female('Žena');

  final String label;
  const Sex(this.label);

  static Sex? tryParse(Object? v) =>
      values.where((s) => s.name == v).firstOrNull;
}

/// Co chce dělat s tělesnou váhou; mění kalorický cíl.
enum WeightGoal {
  lose('Shodit', -400),
  keep('Udržet', 0),
  gain('Nabrat', 250);

  final String label;

  /// Kolik kcal denně přidat k udržovacímu příjmu.
  final int kcal;
  const WeightGoal(this.label, this.kcal);

  static WeightGoal? tryParse(Object? v) =>
      values.where((g) => g.name == v).firstOrNull;
}

/// Hlavní cviky, které si lidé chtějí nechat v plánu.
const favoriteChoices = [
  'bench_press',
  'squat',
  'deadlift',
  'overhead_press',
  'pull_up',
  'barbell_row',
  'hip_thrust',
  'dips',
  'leg_press',
  'barbell_curl',
];

/// Partie, kterým jde dát přednost (víc sérií).
const focusChoices = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'legs',
  'glutes',
  'core',
];

String focusName(String id) =>
    dayFocuses.where((f) => f.id == id).firstOrNull?.name ?? id;

/// Specializované stroje, které v menším fitku většinou nejsou.
const smallGymMissing = {
  'hack_squat',
  'pendulum_squat',
  'belt_squat',
  'hip_thrust_machine',
  'glute_kickback_machine',
  't_bar_row',
  'machine_high_row',
  'machine_lateral_raise',
  'machine_preacher_curl',
  'triceps_dip_machine',
  'torso_rotation_machine',
  'seated_calf_raise',
  'standing_leg_curl',
  'incline_chest_press_machine',
  'reverse_pec_deck',
  'hip_adduction',
  'hip_abduction',
};

/// Cvik smí do plánu: vybavení je k dispozici, stroj v posilovně je
/// (není v [unavailable]) a nešetřený kloub netrpí.
bool exerciseAllowed(
  Exercise e,
  TrainingPlace place,
  Set<Joint> avoid, {
  Set<String> unavailable = const {},
}) =>
    place.allows(e.equipment) &&
    !unavailable.contains(e.id) &&
    !avoid.any((j) => j.stresses(e));

/// Hlavní hlava cviku; vlastní cviky žádnou nemají.
String? primaryHead(String id) => anatomyOf(id)?.primary.firstOrNull;

/// Náhrada za nepovolený cvik: nejdřív stejná hlavní hlava svalu, pak
/// stejná partie. Bere jen vestavěné cviky, které ještě nejsou v [taken].
Exercise? replacementFor(
  String exerciseId, {
  required TrainingPlace place,
  required Set<Joint> avoid,
  required Set<String> taken,
  Set<String> unavailable = const {},
}) {
  final head = primaryHead(exerciseId);
  if (head == null) return null;
  final focus = focusOfHead(head);
  bool ok(Exercise e) =>
      !taken.contains(e.id) &&
      exerciseAllowed(e, place, avoid, unavailable: unavailable);
  final pool = builtInExercises.where(ok).toList();
  return pool.where((e) => primaryHead(e.id) == head).firstOrNull ??
      pool.where((e) {
        final h = primaryHead(e.id);
        return h != null && focus != null && focusOfHead(h) == focus;
      }).firstOrNull;
}
