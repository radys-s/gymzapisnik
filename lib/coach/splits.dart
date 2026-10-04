/// Šablony tréninkových splitů. Čistý Dart bez Flutteru.
///
/// Každý den má pevné pořadí cviků, počet pracovních sérií a rozsah
/// opakování pro dvojitou progresi (viz `progression.dart`).
library;

class PlannedExercise {
  final String exerciseId;
  final int sets;
  final int repMin;
  final int repMax;

  const PlannedExercise(
    this.exerciseId, {
    this.sets = 3,
    this.repMin = 8,
    this.repMax = 12,
  });
}

class SplitDay {
  final String name;
  final List<PlannedExercise> exercises;
  const SplitDay(this.name, this.exercises);
}

class SplitTemplate {
  final String id;
  final String name;
  final String description;

  /// Doporučený počet tréninků týdně.
  final int perWeek;
  final List<SplitDay> days;

  const SplitTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.perWeek,
    required this.days,
  });

  SplitDay day(int index) => days[index % days.length];
}

// Silové základy: méně opakování, víc sérií.
const _heavy = (sets: 4, repMin: 5, repMax: 8);

PlannedExercise _h(String id) => PlannedExercise(
  id,
  sets: _heavy.sets,
  repMin: _heavy.repMin,
  repMax: _heavy.repMax,
);

PlannedExercise _m(String id, {int sets = 3}) =>
    PlannedExercise(id, sets: sets);

PlannedExercise _l(String id, {int sets = 3}) =>
    PlannedExercise(id, sets: sets, repMin: 12, repMax: 15);

final List<SplitTemplate> splitTemplates = [
  SplitTemplate(
    id: 'full_body_3',
    name: 'Full body 3×',
    description: 'Celé tělo třikrát týdně. Nejlepší start pro začátečníky a pro málo času.',
    perWeek: 3,
    days: [
      SplitDay('Full body A', [
        _h('squat'),
        _h('bench_press'),
        _m('barbell_row'),
        _m('lateral_raise'),
        _m('biceps_curl', sets: 2),
      ]),
      SplitDay('Full body B', [
        _h('deadlift'),
        _h('overhead_press'),
        _m('lat_pulldown'),
        _m('leg_curl'),
        _m('triceps_pushdown', sets: 2),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'upper_lower',
    name: 'Upper / Lower',
    description: 'Horní a dolní polovina těla střídavě, 4× týdně. Každá partie 2× týdně.',
    perWeek: 4,
    days: [
      SplitDay('Upper', [
        _h('bench_press'),
        _m('barbell_row'),
        _m('shoulder_press'),
        _m('lat_pulldown'),
        _m('biceps_curl', sets: 2),
        _m('triceps_pushdown', sets: 2),
      ]),
      SplitDay('Lower', [
        _h('squat'),
        _m('romanian_deadlift'),
        _m('leg_press'),
        _m('leg_curl'),
        _l('calf_raise'),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'ppl',
    name: 'Push / Pull / Legs',
    description: 'Tlaky, tahy a nohy dokola. 3× týdně (každá partie 1×) nebo 6× pro pokročilé.',
    perWeek: 3,
    days: [
      SplitDay('Push', [
        _h('bench_press'),
        _m('overhead_press'),
        _m('incline_dumbbell_press'),
        _l('lateral_raise'),
        _m('triceps_pushdown'),
      ]),
      SplitDay('Pull', [
        _h('deadlift'),
        _m('lat_pulldown'),
        _m('seated_row'),
        _l('face_pull'),
        _m('biceps_curl'),
      ]),
      SplitDay('Legs', [
        _h('squat'),
        _m('romanian_deadlift'),
        _m('leg_press'),
        _m('leg_curl'),
        _l('calf_raise', sets: 4),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'arnold',
    name: 'Arnold split',
    description:
        'Hrudník + záda, ramena + paže, nohy. Náročnější, pro pokročilé.',
    perWeek: 3,
    days: [
      SplitDay('Hrudník a záda', [
        _h('bench_press'),
        _m('barbell_row'),
        _m('incline_dumbbell_press'),
        _m('lat_pulldown'),
        _m('cable_fly'),
      ]),
      SplitDay('Ramena a paže', [
        _h('overhead_press'),
        _l('lateral_raise'),
        _m('barbell_curl'),
        _m('skull_crusher'),
        _m('hammer_curl'),
      ]),
      SplitDay('Nohy', [
        _h('squat'),
        _m('romanian_deadlift'),
        _m('leg_extension'),
        _m('leg_curl'),
        _l('calf_raise'),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'bro_split',
    name: 'Bro split',
    description: 'Každý den jedna partie, 5× týdně. Velký objem na partii, ale jen 1× týdně.',
    perWeek: 5,
    days: [
      SplitDay('Hrudník', [
        _h('bench_press'),
        _m('incline_dumbbell_press'),
        _m('chest_press_machine'),
        _m('cable_fly'),
      ]),
      SplitDay('Záda', [
        _h('deadlift'),
        _m('lat_pulldown'),
        _m('barbell_row'),
        _m('seated_row'),
      ]),
      SplitDay('Ramena', [
        _h('overhead_press'),
        _l('lateral_raise', sets: 4),
        _l('reverse_pec_deck'),
        _l('face_pull'),
      ]),
      SplitDay('Nohy', [
        _h('squat'),
        _m('leg_press'),
        _m('leg_curl'),
        _m('leg_extension'),
        _l('calf_raise', sets: 4),
      ]),
      SplitDay('Paže', [
        _m('barbell_curl'),
        _m('skull_crusher'),
        _m('hammer_curl'),
        _m('triceps_pushdown'),
        _m('preacher_curl'),
      ]),
    ],
  ),
];

SplitTemplate? findSplit(String? id) =>
    splitTemplates.where((t) => t.id == id).firstOrNull;
