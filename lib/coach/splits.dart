/// Šablony tréninkových splitů. Čistý Dart bez Flutteru.
///
/// Každý den má pevné pořadí cviků, počet pracovních sérií a rozsah
/// opakování pro dvojitou progresi (viz `progression.dart`).
library;

import '../core/i18n.dart';
import '../domain/anatomy.dart';
import '../domain/catalog.dart';

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
  if (program.name.trim().isEmpty)
    return tr('Pojmenuj program.', 'Name the program.');
  if (program.name.trim().length > maxNameLength) {
    return tr('Název programu je moc dlouhý.', 'The program name is too long.');
  }
  if (program.perWeek < 1 || program.perWeek > 7) {
    return tr(
      'Frekvence musí být 1–7× týdně.',
      'Frequency must be 1–7× per week.',
    );
  }
  if (program.days.isEmpty)
    return tr('Přidej aspoň jeden den.', 'Add at least one day.');
  if (program.days.length > maxProgramDays) {
    return tr(
      'Program může mít nejvýš $maxProgramDays dní.',
      'A program can have at most $maxProgramDays days.',
    );
  }
  for (final day in program.days) {
    final name = day.name.trim();
    if (name.isEmpty)
      return tr('Každý den potřebuje název.', 'Every day needs a name.');
    if (name.length > maxNameLength)
      return tr(
        'Název dne „$name“ je moc dlouhý.',
        'The name of day “$name” is too long.',
      );
    if (day.exercises.isEmpty)
      return tr(
        'Den „$name“ nemá žádný cvik.',
        'Day “$name” has no exercises.',
      );
    if (day.exercises.length > maxDayExercises) {
      return tr(
        'Den „$name“ má víc než $maxDayExercises cviků.',
        'Day “$name” has more than $maxDayExercises exercises.',
      );
    }
    for (final e in day.exercises) {
      if (e.exerciseId.trim().isEmpty)
        return tr(
          'Den „$name“ má cvik bez názvu.',
          'Day “$name” has an exercise without a name.',
        );
      if (e.sets < 1 || e.sets > 10)
        return tr('Počet sérií musí být 1–10.', 'Sets must be 1–10.');
      if (e.repMin < 1 || e.repMax > 50 || e.repMin > e.repMax) {
        return tr(
          'Opakování musí být 1–50, od menšího čísla k většímu.',
          'Reps must be 1–50, from the lower number to the higher one.',
        );
      }
    }
  }
  return null;
}

/// Krátký popis programu („3 dny · 14 cviků“).
String programSummary(SplitTemplate program) {
  final days = program.days.length;
  final exercises = program.days.fold(0, (n, d) => n + d.exercises.length);
  final dayWord = days == 1
      ? tr('den', 'day')
      : (days < 5 ? tr('dny', 'days') : tr('dní', 'days'));
  final exWord = exercises == 1
      ? tr('cvik', 'exercise')
      : (exercises >= 2 && exercises <= 4
            ? tr('cviky', 'exercises')
            : tr('cviků', 'exercises'));
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
List<DayFocus> get dayFocuses => [
  DayFocus('chest', tr('Hrudník', 'Chest'), tr('hrudník', 'chest'), [
    _h('bench_press'),
    _m('incline_dumbbell_press'),
    _m('chest_press_machine'),
    _m('cable_fly'),
    _m('pec_deck'),
  ]),
  DayFocus('back', tr('Záda', 'Back'), tr('záda', 'back'), [
    _h('barbell_row'),
    _m('lat_pulldown'),
    _m('seated_row'),
    _m('dumbbell_row'),
    _m('close_grip_pulldown'),
  ]),
  DayFocus('legs', tr('Nohy', 'Legs'), tr('nohy', 'legs'), [
    _h('squat'),
    _m('romanian_deadlift'),
    _m('leg_press'),
    _m('leg_curl'),
    _m('leg_extension'),
  ]),
  DayFocus('glutes', tr('Hýždě', 'Glutes'), tr('hýždě', 'glutes'), [
    _h('hip_thrust'),
    _m('bulgarian_split_squat'),
    _m('walking_lunge'),
  ]),
  DayFocus('shoulders', tr('Ramena', 'Shoulders'), tr('ramena', 'shoulders'), [
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
  DayFocus('calves', tr('Lýtka', 'Calves'), tr('lýtka', 'calves'), [
    _l('calf_raise', sets: 4),
    _l('seated_calf_raise'),
  ]),
  DayFocus('core', tr('Břicho', 'Core'), tr('břicho', 'core'), [
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
  return SplitDay(_dayName(chosen), [
    for (final f in chosen) ...f.exercises.take(per),
  ]);
}

String _dayName(List<DayFocus> chosen) {
  final names = [chosen.first.name, for (final f in chosen.skip(1)) f.inner];
  var name = names.length == 1
      ? names.single
      : '${names.sublist(0, names.length - 1).join(', ')}'
            '${tr(' a ', ' and ')}${names.last}';
  // Moc partií: krátký název, ať projde validací.
  if (name.length > maxNameLength) {
    name =
        '${chosen.first.name}${tr(' a ', ' and ')}${chosen.length - 1} '
        '${tr('další', 'more')}';
  }
  return name;
}

/// Hlavy svalů, které partie ve výběru zahrnuje.
const focusHeads = <String, List<String>>{
  'chest': ['chest_upper', 'chest_mid'],
  'back': ['lats', 'upper_back', 'lower_back'],
  'legs': ['quads', 'hamstrings', 'adductors'],
  'glutes': ['glutes', 'glutes_med'],
  'shoulders': ['delt_front', 'delt_side', 'delt_rear'],
  'biceps': ['biceps_long', 'biceps_short', 'brachialis'],
  'triceps': ['triceps_long', 'triceps_lateral'],
  'calves': ['calves_gastro', 'calves_soleus'],
  'core': ['abs', 'abs_lower', 'obliques'],
};

/// Nejvíc cviků v sestaveném tréninku.
const maxBuiltExercises = 10;

/// Trénink sestavený ze zvolených partií a počtu cviků. Partie se střídají
/// (velké první), takže se cviky rozdělí rovnoměrně; když jedné partii
/// dojdou cviky, zbytek dostanou ostatní. Každá partie začne těžkým
/// vícekloubovým cvikem a další cviky míří na hlavy svalu, které ještě
/// nejsou pokryté. Cviky, jejichž hlavní hlava patří do [avoidFocuses]
/// (partie, které ještě regenerují), se vynechají.
SplitDay buildDay(
  Iterable<String> focusIds,
  int count, {
  Iterable<String> avoidFocuses = const [],
}) {
  final chosen = [
    for (final f in dayFocuses)
      if (focusIds.contains(f.id)) f,
  ];
  final total = count.clamp(0, maxBuiltExercises);
  if (chosen.isEmpty || total == 0) return const SplitDay('', []);
  final avoidHeads = {
    for (final f in avoidFocuses)
      if (!focusIds.contains(f)) ...?focusHeads[f],
  };
  final pools = [for (final f in chosen) _FocusPool(f, avoidHeads)];
  final picked = <String>{};
  final result = <PlannedExercise>[];
  var progress = true;
  while (result.length < total && progress) {
    progress = false;
    for (final pool in pools) {
      if (result.length >= total) break;
      final next = pool.take(picked);
      if (next == null) continue;
      picked.add(next.exerciseId);
      result.add(next);
      progress = true;
    }
  }
  // Vícekloubové cviky celého tréninku dopředu (dokud jsou čerstvé síly).
  final ordered = [
    ...result.where((p) => anatomyOf(p.exerciseId)?.compound ?? false),
    ...result.where((p) => !(anatomyOf(p.exerciseId)?.compound ?? false)),
  ];
  return SplitDay(
    _dayName([
      for (final pool in pools)
        if (pool.taken > 0) pool.focus,
    ]),
    ordered,
  );
}

/// Kandidáti jedné partie a výběr dalšího cviku.
class _FocusPool {
  final DayFocus focus;
  final List<String> heads;
  final Map<String, PlannedExercise> curated;
  final List<String> candidates;
  final covered = <String>{};
  int taken = 0;

  _FocusPool(this.focus, Set<String> avoidHeads)
    : heads = focusHeads[focus.id] ?? const <String>[],
      curated = {for (final p in focus.exercises) p.exerciseId: p},
      candidates = [] {
    // Vybrané cviky partie, pak ostatní z katalogu na její hlavy.
    candidates.addAll([
      ...curated.keys,
      for (final e in catalogExercises)
        if (!curated.containsKey(e.id) &&
            heads.contains(anatomyOf(e.id)?.primary.first))
          e.id,
    ]);
    candidates.removeWhere(
      (id) => anatomyOf(id)?.primary.any(avoidHeads.contains) ?? false,
    );
  }

  PlannedExercise? take(Set<String> picked) {
    candidates.removeWhere(picked.contains);
    if (candidates.isEmpty) return null;
    var best = 0;
    var bestScore = -1;
    for (var j = 0; j < candidates.length; j++) {
      final a = anatomyOf(candidates[j]);
      final fresh = [
        for (final h in a?.primary ?? const <String>[])
          if (heads.contains(h) && !covered.contains(h)) h,
      ].length;
      // První cvik partie vícekloubový, pak co nejvíc nových hlav.
      final score =
          (taken == 0 && (a?.compound ?? false) ? 100 : 0) +
          fresh * 10 +
          (curated.containsKey(candidates[j]) ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = j;
      }
    }
    final id = candidates.removeAt(best);
    covered.addAll(anatomyOf(id)?.primary ?? const []);
    final compound = anatomyOf(id)?.compound ?? false;
    final first = taken == 0;
    taken++;
    return curated[id] ?? (compound ? (first ? _h(id) : _m(id)) : _l(id));
  }
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

List<SplitTemplate> get splitTemplates => [
  SplitTemplate(
    id: 'full_body_3',
    name: 'Full body 3×',
    description: tr(
      'Celé tělo třikrát týdně. Nejlepší start pro začátečníky a pro málo času.',
      'Full body three times a week. The best start for beginners or when short on time.',
    ),
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
    description: tr(
      'Horní a dolní polovina těla střídavě, 4× týdně. Každá partie 2× týdně.',
      'Upper and lower body alternately, 4× a week. Each muscle group 2× a week.',
    ),
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
    description: tr(
      'Tlaky, tahy a nohy dokola. 3× týdně (každá partie 1×) nebo 6× pro pokročilé.',
      'Push, pull and legs in rotation. 3× a week (each group 1×) or 6× for advanced lifters.',
    ),
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
    description: tr(
      'Hrudník + záda, ramena + paže, nohy. Náročnější, pro pokročilé.',
      'Chest + back, shoulders + arms, legs. More demanding, for advanced lifters.',
    ),
    perWeek: 3,
    days: [
      SplitDay(tr('Hrudník a záda', 'Chest and back'), [
        _h('bench_press'),
        _m('barbell_row'),
        _m('incline_dumbbell_press'),
        _m('lat_pulldown'),
        _m('cable_fly'),
      ]),
      SplitDay(tr('Ramena a paže', 'Shoulders and arms'), [
        _h('overhead_press'),
        _l('lateral_raise'),
        _m('barbell_curl'),
        _m('skull_crusher'),
        _m('hammer_curl'),
      ]),
      SplitDay(tr('Nohy', 'Legs'), [
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
    description: tr(
      'Každý den jedna partie, 5× týdně. Velký objem na partii, ale jen 1× týdně.',
      'One muscle group per day, 5× a week. High volume per group, but only 1× a week.',
    ),
    perWeek: 5,
    days: [
      SplitDay(tr('Hrudník', 'Chest'), [
        _h('bench_press'),
        _m('incline_dumbbell_press'),
        _m('chest_press_machine'),
        _m('cable_fly'),
      ]),
      SplitDay(tr('Záda', 'Back'), [
        _h('deadlift'),
        _m('lat_pulldown'),
        _m('barbell_row'),
        _m('seated_row'),
      ]),
      SplitDay(tr('Ramena', 'Shoulders'), [
        _h('overhead_press'),
        _l('lateral_raise', sets: 4),
        _l('reverse_pec_deck'),
        _l('face_pull'),
      ]),
      SplitDay(tr('Nohy', 'Legs'), [
        _h('squat'),
        _m('leg_press'),
        _m('leg_curl'),
        _m('leg_extension'),
        _l('calf_raise', sets: 4),
      ]),
      SplitDay(tr('Paže', 'Arms'), [
        _m('barbell_curl'),
        _m('skull_crusher'),
        _m('hammer_curl'),
        _m('triceps_pushdown'),
        _m('preacher_curl'),
      ]),
    ],
  ),
];

PlannedExercise _x(String id, int sets, int repMin, int repMax) =>
    PlannedExercise(id, sets: sets, repMin: repMin, repMax: repMax);

/// Plans for the three styles of the plan quiz. Science-based plans pick
/// exercises that load the muscle in the stretched position (see
/// `evidence.dart`) and hit every muscle at least twice a week.
List<SplitTemplate> get styleTemplates => [
  SplitTemplate(
    id: 'science_full_body',
    name: 'Full body (science-based)',
    description: tr(
      'Celé tělo 2–3× týdně, cviky s důrazem na protažení svalu, '
          '1–2 opakování v záloze.',
      'Full body 2–3× a week, exercises emphasizing the stretched position, '
          '1–2 reps in reserve.',
    ),
    perWeek: 3,
    days: [
      SplitDay('Full body A', [
        _x('squat', 3, 6, 10),
        _x('incline_dumbbell_press', 3, 8, 12),
        _x('chest_supported_row', 3, 8, 12),
        _x('seated_leg_curl', 3, 10, 15),
        _x('overhead_triceps_extension', 2, 10, 15),
        _x('cable_lateral_raise', 3, 12, 20),
      ]),
      SplitDay('Full body B', [
        _x('romanian_deadlift', 3, 6, 10),
        _x('bench_press', 3, 6, 10),
        _x('lat_pulldown', 3, 8, 12),
        _x('leg_extension', 3, 10, 15),
        _x('incline_dumbbell_curl', 2, 10, 15),
        _x('calf_raise', 3, 10, 15),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'science_upper_lower',
    name: 'Upper / Lower (science-based)',
    description: tr(
      'Horní a dolní polovina střídavě, každý sval 2× týdně, cviky '
          's důrazem na protažení.',
      'Upper and lower body alternately, every muscle 2× a week, exercises '
          'emphasizing the stretch.',
    ),
    perWeek: 4,
    days: [
      SplitDay('Upper', [
        _x('bench_press', 3, 6, 10),
        _x('chest_supported_row', 3, 8, 12),
        _x('incline_dumbbell_press', 3, 8, 12),
        _x('lat_pulldown', 3, 8, 12),
        _x('cable_lateral_raise', 3, 12, 20),
        _x('overhead_triceps_extension', 2, 10, 15),
        _x('bayesian_curl', 2, 10, 15),
      ]),
      SplitDay('Lower', [
        _x('squat', 3, 6, 10),
        _x('romanian_deadlift', 3, 8, 12),
        _x('seated_leg_curl', 3, 10, 15),
        _x('leg_extension', 3, 10, 15),
        _x('calf_raise', 4, 10, 15),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'science_ppl',
    name: 'Push / Pull / Legs (science-based)',
    description: tr(
      'Tlaky, tahy a nohy dokola, 5–6× týdně. Každý sval skoro 2× '
          'týdně s velkým objemem.',
      'Push, pull and legs in rotation, 5–6× a week. Every muscle almost 2× '
          'a week with high volume.',
    ),
    perWeek: 6,
    days: [
      SplitDay('Push', [
        _x('bench_press', 3, 6, 10),
        _x('incline_dumbbell_press', 3, 8, 12),
        _x('cable_fly', 2, 10, 15),
        _x('cable_lateral_raise', 3, 12, 20),
        _x('overhead_triceps_extension', 3, 10, 15),
      ]),
      SplitDay('Pull', [
        _x('lat_pulldown', 3, 8, 12),
        _x('chest_supported_row', 3, 8, 12),
        _x('reverse_pec_deck', 3, 12, 20),
        _x('bayesian_curl', 3, 10, 15),
        _x('incline_dumbbell_curl', 2, 10, 15),
      ]),
      SplitDay('Legs', [
        _x('squat', 3, 6, 10),
        _x('romanian_deadlift', 3, 8, 12),
        _x('seated_leg_curl', 3, 10, 15),
        _x('leg_extension', 3, 10, 15),
        _x('calf_raise', 4, 10, 15),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'basics_5x5',
    name: 'Old school 5×5',
    description: tr(
      'Dva tréninky dokola, těžké základy 5 sérií po 5. Když dáš '
          'všech 5×5, příště přidej váhu.',
      'Two workouts in rotation, heavy basics 5 sets of 5. Once you hit all '
          '5×5, add weight next time.',
    ),
    perWeek: 3,
    days: [
      SplitDay('A', [
        _x('squat', 5, 5, 5),
        _x('bench_press', 5, 5, 5),
        _x('barbell_row', 5, 5, 5),
      ]),
      SplitDay('B', [
        _x('squat', 5, 5, 5),
        _x('overhead_press', 5, 5, 5),
        _x('deadlift', 1, 5, 5),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'strength_sbd',
    name: 'Strength: squat, bench, deadlift',
    description: tr(
      'Tři hlavní cviky v různé intenzitě. Těžké série po 3–5, '
          'objemové po 6–8, pauzy 3 minuty.',
      'The three main lifts at different intensities. Heavy sets of 3–5, '
          'volume sets of 6–8, 3-minute rests.',
    ),
    perWeek: 3,
    days: [
      SplitDay(tr('Těžký dřep', 'Heavy squat'), [
        _x('squat', 5, 3, 5),
        _x('bench_press', 4, 6, 8),
        _x('barbell_row', 3, 6, 8),
        _x('back_extension', 3, 8, 12),
      ]),
      SplitDay(tr('Těžký bench', 'Heavy bench'), [
        _x('bench_press', 5, 3, 5),
        _x('deadlift', 3, 3, 5),
        _x('pull_up', 3, 5, 8),
        _x('overhead_press', 3, 6, 8),
      ]),
      SplitDay(tr('Těžký mrtvý tah', 'Heavy deadlift'), [
        _x('deadlift', 4, 2, 4),
        _x('squat', 3, 6, 8),
        _x('close_grip_bench', 3, 6, 8),
        _x('dumbbell_row', 3, 8, 10),
      ]),
    ],
  ),
  SplitTemplate(
    id: 'strength_upper_lower',
    name: 'Strength: upper / lower',
    description: tr(
      'Horní a dolní polovina střídavě, hlavní cvik těžce a doplňky '
          'na slabá místa.',
      'Upper and lower body alternately, the main lift heavy and accessories '
          'for weak spots.',
    ),
    perWeek: 4,
    days: [
      SplitDay(tr('Horní těžce', 'Upper heavy'), [
        _x('bench_press', 5, 3, 5),
        _x('barbell_row', 4, 5, 8),
        _x('overhead_press', 3, 5, 8),
        _x('chin_up', 3, 5, 8),
      ]),
      SplitDay(tr('Dolní těžce', 'Lower heavy'), [
        _x('squat', 5, 3, 5),
        _x('romanian_deadlift', 3, 6, 8),
        _x('leg_press', 3, 8, 10),
        _x('hanging_leg_raise', 3, 8, 12),
      ]),
      SplitDay(tr('Horní objem', 'Upper volume'), [
        _x('close_grip_bench', 4, 6, 8),
        _x('pull_up', 4, 6, 10),
        _x('dumbbell_shoulder_press', 3, 8, 10),
        _x('dumbbell_row', 3, 8, 10),
        _x('triceps_pushdown', 3, 10, 12),
      ]),
      SplitDay(tr('Dolní objem', 'Lower volume'), [
        _x('deadlift', 4, 3, 5),
        _x('front_squat', 3, 6, 8),
        _x('leg_curl', 3, 8, 12),
        _x('back_extension', 3, 8, 12),
      ]),
    ],
  ),
];

/// Hotová šablona nebo vlastní program podle ID.
SplitTemplate? findSplit(
  String? id, [
  Iterable<SplitTemplate> custom = const [],
]) => [
  ...custom,
  ...splitTemplates,
  ...styleTemplates,
].where((t) => t.id == id).firstOrNull;
