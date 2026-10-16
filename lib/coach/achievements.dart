/// Odznaky za dlouhodobou snahu. Čistý Dart.
///
/// Počítají se jedním průchodem historie od nejstaršího tréninku, takže
/// u každého odznaku je známé, kterým tréninkem se odemkl.
library;

import '../domain/models.dart';
import '../domain/stats.dart';
import 'weeks.dart';

/// Co odznak měří.
enum BadgeMetric {
  workouts,
  weekRun,
  volumeTons,
  records,
  sets,
  weekWorkouts,
  longMinutes,
  earlyStarts,
  lateStarts,
  distinctExercises,
}

/// Skupina odznaků na stránce.
enum BadgeGroup {
  workouts('Tréninky'),
  consistency('Pravidelnost'),
  strength('Síla a objem'),
  habits('Zvyky');

  final String label;
  const BadgeGroup(this.label);
}

class Achievement {
  final String id;
  final String title;
  final String detail;
  final BadgeGroup group;
  final BadgeMetric metric;
  final int target;
  const Achievement(
    this.id,
    this.title,
    this.detail,
    this.group,
    this.metric,
    this.target,
  );
}

const achievements = <Achievement>[
  Achievement(
    'w1',
    'První krok',
    'Dokonči první trénink.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    1,
  ),
  Achievement(
    'w10',
    'Rozjezd',
    'Dokonči 10 tréninků.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    10,
  ),
  Achievement(
    'w25',
    'Stálice',
    'Dokonči 25 tréninků.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    25,
  ),
  Achievement(
    'w50',
    'Padesátka',
    'Dokonči 50 tréninků.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    50,
  ),
  Achievement(
    'w100',
    'Stovka',
    'Dokonči 100 tréninků.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    100,
  ),
  Achievement(
    'w250',
    'Železný',
    'Dokonči 250 tréninků.',
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    250,
  ),
  Achievement(
    'r2',
    'Dva týdny',
    'Cvič 2 týdny po sobě.',
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    2,
  ),
  Achievement(
    'r4',
    'Měsíc v kuse',
    'Cvič 4 týdny po sobě.',
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    4,
  ),
  Achievement(
    'r8',
    'Dva měsíce',
    'Cvič 8 týdnů po sobě.',
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    8,
  ),
  Achievement(
    'r16',
    'Návyk',
    'Cvič 16 týdnů po sobě.',
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    16,
  ),
  Achievement(
    'ww3',
    'Plný týden',
    'Dej 3 tréninky v jednom týdnu.',
    BadgeGroup.consistency,
    BadgeMetric.weekWorkouts,
    3,
  ),
  Achievement(
    'v10',
    '10 tun',
    'Zvedni celkem 10 tun.',
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    10,
  ),
  Achievement(
    'v50',
    '50 tun',
    'Zvedni celkem 50 tun.',
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    50,
  ),
  Achievement(
    'v100',
    '100 tun',
    'Zvedni celkem 100 tun.',
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    100,
  ),
  Achievement(
    'v500',
    '500 tun',
    'Zvedni celkem 500 tun.',
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    500,
  ),
  Achievement(
    'p1',
    'První rekord',
    'Překonej svůj osobní rekord.',
    BadgeGroup.strength,
    BadgeMetric.records,
    1,
  ),
  Achievement(
    'p10',
    'Lovec rekordů',
    'Překonej 10 osobních rekordů.',
    BadgeGroup.strength,
    BadgeMetric.records,
    10,
  ),
  Achievement(
    'p50',
    'Sběratel',
    'Překonej 50 osobních rekordů.',
    BadgeGroup.strength,
    BadgeMetric.records,
    50,
  ),
  Achievement(
    's100',
    '100 sérií',
    'Odcvič 100 pracovních sérií.',
    BadgeGroup.habits,
    BadgeMetric.sets,
    100,
  ),
  Achievement(
    's1000',
    '1000 sérií',
    'Odcvič 1000 pracovních sérií.',
    BadgeGroup.habits,
    BadgeMetric.sets,
    1000,
  ),
  Achievement(
    'long',
    'Vytrvalec',
    'Dokonči aspoň hodinový trénink.',
    BadgeGroup.habits,
    BadgeMetric.longMinutes,
    60,
  ),
  Achievement(
    'early',
    'Ranní ptáče',
    'Začni trénink před 7:00.',
    BadgeGroup.habits,
    BadgeMetric.earlyStarts,
    1,
  ),
  Achievement(
    'late',
    'Noční směna',
    'Začni trénink po 21:00.',
    BadgeGroup.habits,
    BadgeMetric.lateStarts,
    1,
  ),
  Achievement(
    'var20',
    'Všestranný',
    'Vyzkoušej 20 různých cviků.',
    BadgeGroup.habits,
    BadgeMetric.distinctExercises,
    20,
  ),
];

/// Stav jednoho odznaku.
class BadgeState {
  final Achievement badge;

  /// Dosažená hodnota (může přesáhnout cíl).
  final int value;

  /// Trénink, kterým se odznak odemkl, a kdy.
  final String? workoutId;
  final DateTime? unlockedAt;

  const BadgeState(this.badge, this.value, this.workoutId, this.unlockedAt);

  bool get unlocked => unlockedAt != null;
  double get progress => (value / badge.target).clamp(0, 1).toDouble();
}

/// Delší „trénink“ se nepočítá (zapomenuté dokončení přes noc).
const _maxCountedMinutes = 300;

/// Stav všech odznaků z dokončených tréninků.
List<BadgeState> computeBadges(
  Iterable<Workout> workouts,
  ExerciseType Function(String exerciseId) typeOf,
) {
  final done = workouts.where((w) => w.finished).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  final values = {for (final m in BadgeMetric.values) m: 0};
  final unlocked = <String, (String, DateTime)>{};
  var volumeKg = 0.0;
  DateTime? lastWeek;
  var run = 0;
  var inWeek = 0;
  final exercises = <String>{};
  // Rekordy: nejlepší hodnota každého druhu u cviku, který už má historii.
  final best = <String, Map<RecordKind, double>>{};

  void raise(BadgeMetric m, int v) {
    if (v > values[m]!) values[m] = v;
  }

  for (final w in done) {
    values[BadgeMetric.workouts] = values[BadgeMetric.workouts]! + 1;
    final week = weekStart(w.date);
    if (lastWeek == null || week != lastWeek) {
      run = lastWeek != null && nextWeek(lastWeek) == week ? run + 1 : 1;
      inWeek = 0;
      lastWeek = week;
    }
    inWeek++;
    raise(BadgeMetric.weekRun, run);
    raise(BadgeMetric.weekWorkouts, inWeek);

    final finishedAt = w.finishedAt;
    if (finishedAt != null) {
      final minutes = finishedAt.difference(w.startedAt).inMinutes;
      if (minutes <= _maxCountedMinutes) {
        raise(BadgeMetric.longMinutes, minutes);
      }
    }
    final hour = w.startedAt.toLocal().hour;
    if (hour < 7) {
      values[BadgeMetric.earlyStarts] = values[BadgeMetric.earlyStarts]! + 1;
    }
    if (hour >= 21) {
      values[BadgeMetric.lateStarts] = values[BadgeMetric.lateStarts]! + 1;
    }

    final setsByExercise = <String, List<SetEntry>>{};
    for (final e in w.exercises) {
      final counted = e.countedSets;
      if (counted.isEmpty) continue;
      setsByExercise.putIfAbsent(e.exerciseId, () => []).addAll(counted);
    }
    var records = 0;
    for (final MapEntry(key: id, value: sets) in setsByExercise.entries) {
      final type = typeOf(id);
      values[BadgeMetric.sets] = values[BadgeMetric.sets]! + sets.length;
      if (type == ExerciseType.weighted) {
        volumeKg += volume(type, sets);
      }
      exercises.add(id);
      final previous = best[id];
      final current = <RecordKind, double>{...?previous};
      for (final kind in recordKinds(type)) {
        var top = 0.0;
        for (final s in sets) {
          final v = recordValue(kind, s);
          if (v > top) top = v;
        }
        if (top <= 0) continue;
        // Jako newRecords: bez dřívější nenulové hodnoty rekord nevzniká.
        if (previous != null &&
            previous.isNotEmpty &&
            top > (previous[kind] ?? 0)) {
          records++;
        }
        if (top > (current[kind] ?? 0)) current[kind] = top;
      }
      best[id] = current;
    }
    values[BadgeMetric.records] = values[BadgeMetric.records]! + records;
    values[BadgeMetric.volumeTons] = volumeKg ~/ 1000;
    values[BadgeMetric.distinctExercises] = exercises.length;

    for (final b in achievements) {
      if (!unlocked.containsKey(b.id) && values[b.metric]! >= b.target) {
        unlocked[b.id] = (w.id, w.date);
      }
    }
  }
  return [
    for (final b in achievements)
      BadgeState(b, values[b.metric]!, unlocked[b.id]?.$1, unlocked[b.id]?.$2),
  ];
}
