/// Podrobnější odpovědi z úvodu: jak dlouho kdo cvičí, kde, na co se
/// chce zaměřit a čemu se vyhnout. Podle nich se plán přizpůsobí.
/// Čistý Dart bez Flutteru.
library;

import '../core/i18n.dart';
import '../domain/anatomy.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import 'splits.dart';
import 'tips.dart';

/// Jak dlouho už pravidelně cvičí. Rozlišuje víc než jen začátečník
/// a pokročilý: první měsíce rostou váhy rychle, po letech pomalu.
enum Experience {
  fresh(0),
  quarter(3),
  half(6),
  year(12),
  two(24),
  more(36);

  /// Přibližná délka cvičení v měsících.
  final int months;
  const Experience(this.months);

  String get label => switch (this) {
    fresh => tr('Teprve začínám', 'Just starting'),
    quarter => tr('Čtvrt roku', '3 months'),
    half => tr('Půl roku', '6 months'),
    year => tr('Rok', '1 year'),
    two => tr('Dva roky', '2 years'),
    more => tr('Víc než dva roky', 'More than 2 years'),
  };

  String get hint => switch (this) {
    fresh => tr(
      'Necvičím, nebo jen pár týdnů',
      'Not training, or just a few weeks',
    ),
    quarter => tr(
      'Cviky znám, technika se usazuje',
      'Know the exercises, dialing in form',
    ),
    half => tr(
      'Cvičím pravidelně, váhy pořád rostou',
      'Training regularly, weights still going up',
    ),
    year => tr(
      'Mám své váhy, zlepšuju se pomaleji',
      'Have my numbers, progress is slower',
    ),
    two => tr(
      'Vím, co mi sedí, pokrok je pomalý',
      'Know what works, progress is slow',
    ),
    more => tr(
      'Zkušený, hledám další posun',
      'Experienced, looking for the next step',
    ),
  };

  static Experience? tryParse(Object? v) =>
      values.where((e) => e.name == v).firstOrNull;
}

/// Kde cvičí: určuje, jaké vybavení plán smí použít.
enum TrainingPlace {
  gym,
  smallGym,
  home,
  bodyweight;

  String get label => switch (this) {
    gym => tr('Velké komerční fitko', 'Big commercial gym'),
    smallGym => tr('Menší / hotelové fitko', 'Small / hotel gym'),
    home => tr('Doma s činkami', 'Home with weights'),
    bodyweight => tr('Jen vlastní váha', 'Bodyweight only'),
  };

  String get hint => switch (this) {
    gym => tr(
      'Suncity, Okragon, Extrifit, Form Factory — většina strojů i volných vah',
      'Most machines and free weights',
    ),
    smallGym => tr(
      'Osa, jednoručky, kladky a základní stroje',
      'Barbell, dumbbells, cables, and basic machines',
    ),
    home => tr(
      'Jednoručky, kettlebell, gumy a lavička',
      'Dumbbells, kettlebell, bands, and a bench',
    ),
    bodyweight => tr(
      'Bez vybavení, nanejvýš guma',
      'No equipment, maybe a band',
    ),
  };

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
  knees({'squat', 'sumo_squat', 'lunge', 'step_up', 'leg_ext'}),
  lowerBack({'hinge', 'good_morning', 'row_bent', 'swing', 'back_ext'}),
  shoulders({'push_vertical', 'dip', 'bench_dip', 'upright_row'});

  /// Pohybové vzory, které kloub nejvíc zatěžují.
  final Set<String> patterns;
  const Joint(this.patterns);

  String get label => switch (this) {
    knees => tr('Kolena', 'Knees'),
    lowerBack => tr('Spodní záda', 'Lower back'),
    shoulders => tr('Ramena', 'Shoulders'),
  };

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
  male,
  female;

  String get label => switch (this) {
    male => tr('Muž', 'Male'),
    female => tr('Žena', 'Female'),
  };

  static Sex? tryParse(Object? v) =>
      values.where((s) => s.name == v).firstOrNull;
}

/// Co chce dělat s tělesnou váhou; mění kalorický cíl.
enum WeightGoal {
  lose(-400),
  keep(0),
  gain(250);

  /// Kolik kcal denně přidat k udržovacímu příjmu.
  final int kcal;
  const WeightGoal(this.kcal);

  String get label => switch (this) {
    lose => tr('Shodit', 'Lose'),
    keep => tr('Udržet', 'Maintain'),
    gain => tr('Nabrat', 'Gain'),
  };

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
  final pool = catalogExercises.where(ok).toList();
  return pool.where((e) => primaryHead(e.id) == head).firstOrNull ??
      pool.where((e) {
        final h = primaryHead(e.id);
        return h != null && focus != null && focusOfHead(h) == focus;
      }).firstOrNull;
}
