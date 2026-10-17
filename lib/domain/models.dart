/// Datové modely tréninku. Čistý Dart bez Flutteru.
///
/// Každý model si nese `extra`: klíče, které tato verze nezná, se při
/// uložení zachovají (data z novější verze aplikace se neztratí).
library;

enum ExerciseType {
  /// Váha × opakování.
  weighted,

  /// Vlastní váha; `weight` je volitelná přidaná zátěž.
  bodyweight;

  static ExerciseType parse(Object? value) =>
      value == 'bodyweight' ? bodyweight : weighted;
}

Map<String, dynamic> _extra(Map<String, dynamic> json, Set<String> known) => {
  for (final e in json.entries)
    if (!known.contains(e.key)) e.key: e.value,
};

double _double(Object? v) => v is num ? v.toDouble() : 0;
int _int(Object? v) => v is num ? v.toInt() : 0;
DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

class Exercise {
  final String id;
  final String name;
  final String muscle;
  final ExerciseType type;
  final bool custom;
  final Map<String, dynamic> extra;

  const Exercise({
    required this.id,
    required this.name,
    required this.muscle,
    this.type = ExerciseType.weighted,
    this.custom = false,
    this.extra = const {},
  });

  static const _known = {'id', 'name', 'muscle', 'type', 'custom'};

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    muscle: json['muscle'] as String? ?? 'Ostatní',
    type: ExerciseType.parse(json['type']),
    custom: json['custom'] == true,
    extra: _extra(json, _known),
  );

  Map<String, dynamic> toJson() => {
    ...extra,
    'id': id,
    'name': name,
    'muscle': muscle,
    'type': type.name,
    'custom': custom,
  };
}

class SetEntry {
  /// Kg; u cviku s vlastní váhou přidaná zátěž.
  double weight;
  int reps;
  bool warmup;
  bool done;
  final Map<String, dynamic> extra;

  SetEntry({
    this.weight = 0,
    this.reps = 0,
    this.warmup = false,
    this.done = false,
    Map<String, dynamic>? extra,
  }) : extra = extra ?? {};

  /// Dokončená pracovní série (rozcvička se nepočítá do objemu ani PR).
  bool get counts => done && !warmup && reps > 0;

  SetEntry copy({bool? done}) => SetEntry(
    weight: weight,
    reps: reps,
    warmup: warmup,
    done: done ?? this.done,
    extra: {...extra},
  );

  static const _known = {'weight', 'reps', 'warmup', 'done'};

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
    weight: _double(json['weight']),
    reps: _int(json['reps']),
    warmup: json['warmup'] == true,
    done: json['done'] == true,
    extra: _extra(json, _known),
  );

  Map<String, dynamic> toJson() => {
    ...extra,
    'weight': weight,
    'reps': reps,
    'warmup': warmup,
    'done': done,
  };
}

class WorkoutExercise {
  final String id;
  String exerciseId;
  String note;
  List<SetEntry> sets;
  final Map<String, dynamic> extra;

  WorkoutExercise({
    required this.id,
    required this.exerciseId,
    this.note = '',
    List<SetEntry>? sets,
    Map<String, dynamic>? extra,
  }) : sets = sets ?? [],
       extra = extra ?? {};

  List<SetEntry> get countedSets => sets.where((s) => s.counts).toList();

  static const _known = {'id', 'exerciseId', 'note', 'sets'};

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        note: json['note'] as String? ?? '',
        sets: [
          for (final s in json['sets'] as List? ?? const [])
            SetEntry.fromJson(Map<String, dynamic>.from(s as Map)),
        ],
        extra: _extra(json, _known),
      );

  Map<String, dynamic> toJson() => {
    ...extra,
    'id': id,
    'exerciseId': exerciseId,
    'note': note,
    'sets': [for (final s in sets) s.toJson()],
  };
}

class Workout {
  final String id;
  String name;
  DateTime startedAt;

  /// `null` = rozepsaný (aktivní) trénink.
  DateTime? finishedAt;
  String note;
  List<WorkoutExercise> exercises;
  final Map<String, dynamic> extra;

  Workout({
    required this.id,
    required this.name,
    required this.startedAt,
    this.finishedAt,
    this.note = '',
    List<WorkoutExercise>? exercises,
    Map<String, dynamic>? extra,
  }) : exercises = exercises ?? [],
       extra = extra ?? {};

  bool get finished => finishedAt != null;

  /// Čas pro řazení historie.
  DateTime get date => finishedAt ?? startedAt;

  static const _known = {
    'id',
    'name',
    'startedAt',
    'finishedAt',
    'note',
    'exercises',
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Trénink',
    // Bez začátku se vezme konec; bez obou trénink nedává smysl (jinak by
    // spadl do roku 1970) a načítání záznam přeskočí.
    startedAt:
        _date(json['startedAt']) ??
        _date(json['finishedAt']) ??
        (throw const FormatException('Trénink bez platného začátku.')),
    finishedAt: _date(json['finishedAt']),
    note: json['note'] as String? ?? '',
    exercises: [
      for (final e in json['exercises'] as List? ?? const [])
        WorkoutExercise.fromJson(Map<String, dynamic>.from(e as Map)),
    ],
    extra: _extra(json, _known),
  );

  Map<String, dynamic> toJson() => {
    ...extra,
    'id': id,
    'name': name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'note': note,
    'exercises': [for (final e in exercises) e.toJson()],
  };

  /// Hluboká kopie (pro úpravy, které jde zahodit).
  Workout copy() => Workout.fromJson(toJson());
}
