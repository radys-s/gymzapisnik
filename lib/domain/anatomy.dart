/// Hlavy a části svalů, na které cviky míří. Čistý Dart bez Flutteru.
///
/// Slouží k nabídce alternativ („stejná hlava“) a k sestavení tréninku,
/// který pokryje celou partii, ne jen jednu její část.
library;

import 'catalog.dart';
import 'models.dart';

class MuscleHead {
  final String id;

  /// Krátký český název („Boční delt“).
  final String name;

  /// Partie z katalogu, do které hlava patří (`muscleGroups`).
  final String group;
  const MuscleHead(this.id, this.name, this.group);
}

const muscleHeads = <MuscleHead>[
  MuscleHead('chest_upper', 'Horní hrudník', 'Hrudník'),
  MuscleHead('chest_mid', 'Střední a spodní hrudník', 'Hrudník'),
  MuscleHead('lats', 'Široký sval zádový', 'Záda'),
  MuscleHead('upper_back', 'Střed zad a trapézy', 'Záda'),
  MuscleHead('lower_back', 'Bedra (vzpřimovače)', 'Záda'),
  MuscleHead('quads', 'Kvadricepsy', 'Nohy'),
  MuscleHead('hamstrings', 'Hamstringy', 'Nohy'),
  MuscleHead('glutes', 'Hýždě', 'Nohy'),
  MuscleHead('calves_gastro', 'Lýtka – dvojhlavý sval', 'Nohy'),
  MuscleHead('calves_soleus', 'Lýtka – šikmý sval', 'Nohy'),
  MuscleHead('delt_front', 'Přední delt', 'Ramena'),
  MuscleHead('delt_side', 'Boční delt', 'Ramena'),
  MuscleHead('delt_rear', 'Zadní delt', 'Ramena'),
  MuscleHead('biceps_long', 'Biceps – dlouhá hlava', 'Paže'),
  MuscleHead('biceps_short', 'Biceps – krátká hlava', 'Paže'),
  MuscleHead('brachialis', 'Brachialis (nadloktí)', 'Paže'),
  MuscleHead('triceps_long', 'Triceps – dlouhá hlava', 'Paže'),
  MuscleHead('triceps_lateral', 'Triceps – boční a střední hlava', 'Paže'),
  MuscleHead('abs', 'Přímý sval břišní', 'Střed těla'),
  MuscleHead('abs_lower', 'Spodní břicho a flexory kyčle', 'Střed těla'),
];

MuscleHead? headById(String id) {
  for (final h in muscleHeads) {
    if (h.id == id) return h;
  }
  return null;
}

class ExerciseAnatomy {
  /// Hlavy, které cvik zatěžuje nejvíc (první je hlavní).
  final List<String> primary;

  /// Hlavy, které pomáhají.
  final List<String> secondary;

  /// Vícekloubový cvik (dřep, tlak, přítah): těžký, jde první.
  final bool compound;
  const ExerciseAnatomy(
    this.primary, {
    this.secondary = const [],
    this.compound = false,
  });
}

const _c = true;

/// Anatomie vestavěných cviků. Vlastní cviky ji nemají.
const exerciseAnatomy = <String, ExerciseAnatomy>{
  'bench_press': ExerciseAnatomy(
    ['chest_mid'],
    secondary: ['delt_front', 'triceps_lateral'],
    compound: _c,
  ),
  'dumbbell_bench_press': ExerciseAnatomy(
    ['chest_mid'],
    secondary: ['delt_front', 'triceps_lateral'],
    compound: _c,
  ),
  'chest_press_machine': ExerciseAnatomy(
    ['chest_mid'],
    secondary: ['triceps_lateral'],
    compound: _c,
  ),
  'push_up': ExerciseAnatomy(
    ['chest_mid'],
    secondary: ['delt_front', 'triceps_lateral'],
    compound: _c,
  ),
  'incline_press': ExerciseAnatomy(
    ['chest_upper'],
    secondary: ['delt_front', 'triceps_lateral'],
    compound: _c,
  ),
  'incline_dumbbell_press': ExerciseAnatomy(
    ['chest_upper'],
    secondary: ['delt_front', 'triceps_lateral'],
    compound: _c,
  ),
  'low_to_high_cable_fly': ExerciseAnatomy(['chest_upper']),
  'pec_deck': ExerciseAnatomy(['chest_mid']),
  'cable_fly': ExerciseAnatomy(['chest_mid']),
  'dips': ExerciseAnatomy(
    ['triceps_lateral', 'chest_mid'],
    secondary: ['delt_front'],
    compound: _c,
  ),
  'pull_up': ExerciseAnatomy(
    ['lats'],
    secondary: ['upper_back', 'biceps_short'],
    compound: _c,
  ),
  'lat_pulldown': ExerciseAnatomy(
    ['lats'],
    secondary: ['upper_back', 'biceps_short'],
    compound: _c,
  ),
  'close_grip_pulldown': ExerciseAnatomy(
    ['lats'],
    secondary: ['biceps_short'],
    compound: _c,
  ),
  'dumbbell_row': ExerciseAnatomy(
    ['lats', 'upper_back'],
    secondary: ['biceps_short'],
    compound: _c,
  ),
  'barbell_row': ExerciseAnatomy(
    ['upper_back', 'lats'],
    secondary: ['lower_back', 'biceps_short'],
    compound: _c,
  ),
  'seated_row': ExerciseAnatomy(
    ['upper_back'],
    secondary: ['lats', 'biceps_short'],
    compound: _c,
  ),
  'chest_supported_row': ExerciseAnatomy(
    ['upper_back'],
    secondary: ['lats', 'delt_rear'],
    compound: _c,
  ),
  'machine_row': ExerciseAnatomy(
    ['upper_back'],
    secondary: ['lats'],
    compound: _c,
  ),
  'shrug': ExerciseAnatomy(['upper_back']),
  'deadlift': ExerciseAnatomy(
    ['lower_back', 'glutes', 'hamstrings'],
    secondary: ['upper_back', 'quads'],
    compound: _c,
  ),
  'back_extension': ExerciseAnatomy(
    ['lower_back'],
    secondary: ['glutes', 'hamstrings'],
  ),
  'squat': ExerciseAnatomy(
    ['quads'],
    secondary: ['glutes', 'lower_back'],
    compound: _c,
  ),
  'front_squat': ExerciseAnatomy(
    ['quads'],
    secondary: ['glutes'],
    compound: _c,
  ),
  'goblet_squat': ExerciseAnatomy(
    ['quads'],
    secondary: ['glutes'],
    compound: _c,
  ),
  'smith_squat': ExerciseAnatomy(
    ['quads'],
    secondary: ['glutes'],
    compound: _c,
  ),
  'hack_squat': ExerciseAnatomy(['quads'], secondary: ['glutes'], compound: _c),
  'leg_press': ExerciseAnatomy(['quads'], secondary: ['glutes'], compound: _c),
  'leg_extension': ExerciseAnatomy(['quads']),
  'bulgarian_split_squat': ExerciseAnatomy(['quads', 'glutes'], compound: _c),
  'walking_lunge': ExerciseAnatomy(['glutes', 'quads'], compound: _c),
  'romanian_deadlift': ExerciseAnatomy(
    ['hamstrings'],
    secondary: ['glutes', 'lower_back'],
    compound: _c,
  ),
  'leg_curl': ExerciseAnatomy(['hamstrings']),
  'hip_thrust': ExerciseAnatomy(
    ['glutes'],
    secondary: ['hamstrings'],
    compound: _c,
  ),
  'calf_raise': ExerciseAnatomy(['calves_gastro']),
  'seated_calf_raise': ExerciseAnatomy(['calves_soleus']),
  'calf_press': ExerciseAnatomy(['calves_gastro']),
  'overhead_press': ExerciseAnatomy(
    ['delt_front'],
    secondary: ['delt_side', 'triceps_lateral'],
    compound: _c,
  ),
  'shoulder_press': ExerciseAnatomy(
    ['delt_front'],
    secondary: ['delt_side', 'triceps_lateral'],
    compound: _c,
  ),
  'dumbbell_shoulder_press': ExerciseAnatomy(
    ['delt_front'],
    secondary: ['delt_side', 'triceps_lateral'],
    compound: _c,
  ),
  'lateral_raise': ExerciseAnatomy(['delt_side']),
  'cable_lateral_raise': ExerciseAnatomy(['delt_side']),
  'reverse_pec_deck': ExerciseAnatomy(['delt_rear'], secondary: ['upper_back']),
  'rear_delt_fly': ExerciseAnatomy(['delt_rear'], secondary: ['upper_back']),
  'face_pull': ExerciseAnatomy(['delt_rear', 'upper_back']),
  'incline_dumbbell_curl': ExerciseAnatomy(['biceps_long']),
  'cable_curl': ExerciseAnatomy(['biceps_long', 'biceps_short']),
  'biceps_curl': ExerciseAnatomy(['biceps_short', 'biceps_long']),
  'barbell_curl': ExerciseAnatomy(['biceps_short'], secondary: ['biceps_long']),
  'preacher_curl': ExerciseAnatomy(['biceps_short'], secondary: ['brachialis']),
  'hammer_curl': ExerciseAnatomy(['brachialis'], secondary: ['biceps_long']),
  'reverse_curl': ExerciseAnatomy(['brachialis']),
  'overhead_triceps_extension': ExerciseAnatomy(['triceps_long']),
  'skull_crusher': ExerciseAnatomy(
    ['triceps_long'],
    secondary: ['triceps_lateral'],
  ),
  'triceps_pushdown': ExerciseAnatomy(['triceps_lateral']),
  'ab_crunch': ExerciseAnatomy(['abs']),
  'cable_crunch': ExerciseAnatomy(['abs']),
  'lying_leg_raise': ExerciseAnatomy(['abs_lower']),
  'hanging_leg_raise': ExerciseAnatomy(['abs_lower'], secondary: ['abs']),
};

ExerciseAnatomy? anatomyOf(String exerciseId) => exerciseAnatomy[exerciseId];

/// Hlavní hlavy cviku jako text („Boční delt“), prázdný pro vlastní cvik.
String headsLabel(String exerciseId) => [
  for (final id in anatomyOf(exerciseId)?.primary ?? const <String>[])
    headById(id)!.name,
].join(' · ');

/// Skupina alternativ: nadpis a cviky.
class AlternativeSection {
  final String title;
  final List<Exercise> exercises;
  const AlternativeSection(this.title, this.exercises);
}

/// Náhrady za cvik. Nejdřív cviky na stejnou hlavu svalu, pak ostatní
/// cviky stejné partie rozdělené podle hlavy, na kterou míří.
List<AlternativeSection> alternativesFor(
  String exerciseId,
  Iterable<Exercise> all,
) {
  final own = findExercise(exerciseId, all);
  final anatomy = anatomyOf(exerciseId);
  final others = [
    for (final e in all)
      if (e.id != exerciseId) e,
  ];
  final used = <String>{};
  final sections = <AlternativeSection>[];

  if (anatomy != null) {
    final main = anatomy.primary.first;
    final same = [
      for (final e in others)
        if (anatomyOf(e.id)?.primary.contains(main) ?? false) e,
    ];
    // Stejný typ cviku (vícekloubový / izolovaný) jako první.
    int kind(Exercise e) =>
        anatomyOf(e.id)!.compound == anatomy.compound ? 0 : 1;
    same.sort((a, b) {
      final k = kind(a) - kind(b);
      return k != 0 ? k : a.name.compareTo(b.name);
    });
    if (same.isNotEmpty) {
      sections.add(
        AlternativeSection('Stejná hlava: ${headById(main)!.name}', same),
      );
      used.addAll(same.map((e) => e.id));
    }
  }

  final group = own?.muscle ?? 'Ostatní';
  for (final head in muscleHeads) {
    if (head.group != group) continue;
    final list = [
      for (final e in others)
        if (!used.contains(e.id) && anatomyOf(e.id)?.primary.first == head.id)
          e,
    ]..sort((a, b) => a.name.compareTo(b.name));
    if (list.isEmpty) continue;
    sections.add(AlternativeSection(head.name, list));
    used.addAll(list.map((e) => e.id));
  }

  // Vlastní a nepřiřazené cviky stejné partie.
  final rest = [
    for (final e in others)
      if (!used.contains(e.id) && e.muscle == group) e,
  ]..sort((a, b) => a.name.compareTo(b.name));
  if (rest.isNotEmpty) {
    sections.add(AlternativeSection('Další cviky – $group', rest));
  }
  return sections;
}
