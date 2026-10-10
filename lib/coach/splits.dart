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

  PlannedExercise copyWith({
    String? exerciseId,
    int? sets,
    int? repMin,
    int? repMax,
  }) => PlannedExercise(
    exerciseId ?? this.exerciseId,
    sets: sets ?? this.sets,
    repMin: repMin ?? this.repMin,
    repMax: repMax ?? this.repMax,
  );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'repMin': repMin,
    'repMax': repMax,
  };

  factory PlannedExercise.fromJson(Map<String, dynamic> json) =>
      PlannedExercise(
        json['exerciseId'] as String,
        sets: (json['sets'] as num).toInt(),
        repMin: (json['repMin'] as num).toInt(),
        repMax: (json['repMax'] as num).toInt(),
      );
}

class SplitDay {
  final String name;
  final List<PlannedExercise> exercises;
  const SplitDay(this.name, this.exercises);

  SplitDay copyWith({String? name, List<PlannedExercise>? exercises}) =>
      SplitDay(name ?? this.name, exercises ?? this.exercises);

  Map<String, dynamic> toJson() => {
    'name': name,
    'exercises': [for (final e in exercises) e.toJson()],
  };

  factory SplitDay.fromJson(Map<String, dynamic> json) =>
      SplitDay(json['name'] as String, [
        for (final e in json['exercises'] as List)
          PlannedExercise.fromJson(Map<String, dynamic>.from(e as Map)),
      ]);
}

class SplitTemplate {
  final String id;
  final String name;
  final String description;

  /// Doporučený počet tréninků týdně.
  final int perWeek;
  final List<SplitDay> days;

  /// Program sestavený uživatelem (jinak hotová šablona).
  final bool custom;

  const SplitTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.perWeek,
    required this.days,
    this.custom = false,
  });

  SplitDay day(int index) => days[index % days.length];

  SplitTemplate copyWith({
    String? id,
    String? name,
    String? description,
    int? perWeek,
    List<SplitDay>? days,
    bool? custom,
  }) => SplitTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    perWeek: perWeek ?? this.perWeek,
    days: days ?? this.days,
    custom: custom ?? this.custom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'perWeek': perWeek,
    'days': [for (final d in days) d.toJson()],
  };

  /// Vlastní program z uloženého JSON; neplatný vrací `null`.
  static SplitTemplate? tryCustom(Object? json) {
    if (json is! Map) return null;
    try {
      final program = SplitTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        perWeek: (json['perWeek'] as num).toInt(),
        days: [
          for (final d in json['days'] as List)
            SplitDay.fromJson(Map<String, dynamic>.from(d as Map)),
        ],
        custom: true,
      );
      return program.id.startsWith(customProgramPrefix) &&
              programError(program) == null
          ? program
          : null;
    } catch (_) {
      return null;
    }
  }
}

/// Předpona ID vlastních programů (nesmí se potkat s šablonou).
const customProgramPrefix = 'custom_';

/// Meze programu (ať se dá rozumně zobrazit i cvičit).
const maxProgramDays = 7;
const maxDayExercises = 15;
const maxNameLength = 40;
const maxCustomPrograms = 20;

/// Česká chyba, nebo `null`, když je program v pořádku.
String? programError(SplitTemplate program) {
  if (program.name.trim().isEmpty) return 'Pojmenuj program.';
  if (program.name.trim().length > maxNameLength) {
    return 'Název programu je moc dlouhý.';
  }
  if (program.perWeek < 1 || program.perWeek > 7) {
    return 'Frekvence musí být 1–7× týdně.';
  }
  if (program.days.isEmpty) return 'Přidej aspoň jeden den.';
  if (program.days.length > maxProgramDays) {
    return 'Program může mít nejvýš $maxProgramDays dní.';
  }
  for (final day in program.days) {
    final name = day.name.trim();
    if (name.isEmpty) return 'Každý den potřebuje název.';
    if (name.length > maxNameLength) return 'Název dne „$name“ je moc dlouhý.';
    if (day.exercises.isEmpty) return 'Den „$name“ nemá žádný cvik.';
    if (day.exercises.length > maxDayExercises) {
      return 'Den „$name“ má víc než $maxDayExercises cviků.';
    }
    for (final e in day.exercises) {
      if (e.exerciseId.trim().isEmpty) return 'Den „$name“ má cvik bez názvu.';
      if (e.sets < 1 || e.sets > 10) return 'Počet sérií musí být 1–10.';
      if (e.repMin < 1 || e.repMax > 50 || e.repMin > e.repMax) {
        return 'Opakování musí být 1–50, od menšího čísla k většímu.';
      }
    }
  }
  return null;
}

/// Krátký popis programu („3 dny · 14 cviků“).
String programSummary(SplitTemplate program) {
  final days = program.days.length;
  final exercises = program.days.fold(0, (n, d) => n + d.exercises.length);
  final dayWord = days == 1 ? 'den' : (days < 5 ? 'dny' : 'dní');
  final exWord = exercises == 1
      ? 'cvik'
      : (exercises >= 2 && exercises <= 4 ? 'cviky' : 'cviků');
  return '$days $dayWord · $exercises $exWord';
}

/// Zaměření dne pro rychlé složení: partie a cviky od nejdůležitějšího.
class DayFocus {
  final String id;
  final String name;

  /// Tvar uvnitř názvu dne („Ramena a triceps“).
  final String inner;
  final List<PlannedExercise> exercises;
  const DayFocus(this.id, this.name, this.inner, this.exercises);
}

/// Partie v pořadí od velkých k malým (těžké cviky jdou první).
final List<DayFocus> dayFocuses = [
  DayFocus('chest', 'Hrudník', 'hrudník', [
    _h('bench_press'),
    _m('incline_dumbbell_press'),
    _m('chest_press_machine'),
    _m('cable_fly'),
    _m('pec_deck'),
  ]),
  DayFocus('back', 'Záda', 'záda', [
    _h('barbell_row'),
    _m('lat_pulldown'),
    _m('seated_row'),
    _m('dumbbell_row'),
    _m('close_grip_pulldown'),
  ]),
  DayFocus('legs', 'Nohy', 'nohy', [
    _h('squat'),
    _m('romanian_deadlift'),
    _m('leg_press'),
    _m('leg_curl'),
    _m('leg_extension'),
  ]),
  DayFocus('glutes', 'Hýždě', 'hýždě', [
    _h('hip_thrust'),
    _m('bulgarian_split_squat'),
    _m('walking_lunge'),
  ]),
  DayFocus('shoulders', 'Ramena', 'ramena', [
    _h('overhead_press'),
    _l('lateral_raise'),
    _m('dumbbell_shoulder_press'),
    _l('face_pull'),
    _l('rear_delt_fly'),
  ]),
  DayFocus('biceps', 'Biceps', 'biceps', [
    _m('barbell_curl'),
    _m('hammer_curl'),
    _m('preacher_curl'),
    _m('cable_curl'),
  ]),
  DayFocus('triceps', 'Triceps', 'triceps', [
    _m('triceps_pushdown'),
    _m('overhead_triceps_extension'),
    _m('skull_crusher'),
    _m('dips'),
  ]),
  DayFocus('calves', 'Lýtka', 'lýtka', [
    _l('calf_raise', sets: 4),
    _l('seated_calf_raise'),
  ]),
  DayFocus('core', 'Břicho', 'břicho', [
    _l('cable_crunch'),
    _l('hanging_leg_raise'),
  ]),
];

/// Den složený ze zvolených partií: název („Ramena a triceps“) a cviky.
/// Jedna partie dostane 5 cviků, víc partií se dělí zhruba o 6 cviků.
SplitDay dayFromFocuses(Iterable<String> focusIds) {
  final chosen = [
    for (final f in dayFocuses)
      if (focusIds.contains(f.id)) f,
  ];
  if (chosen.isEmpty) return const SplitDay('', []);
  final per = chosen.length == 1 ? 5 : (6 ~/ chosen.length).clamp(1, 3);
  final names = [chosen.first.name, for (final f in chosen.skip(1)) f.inner];
  var name = names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')} a ${names.last}';
  // Moc partií: krátký název, ať projde validací.
  if (name.length > maxNameLength) {
    name = '${chosen.first.name} a ${chosen.length - 1} další';
  }
  return SplitDay(name, [for (final f in chosen) ...f.exercises.take(per)]);
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

/// Hotová šablona nebo vlastní program podle ID.
SplitTemplate? findSplit(
  String? id, [
  Iterable<SplitTemplate> custom = const [],
]) => [...custom, ...splitTemplates].where((t) => t.id == id).firstOrNull;
