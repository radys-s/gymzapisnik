/// Odznaky za dlouhodobou snahu. Čistý Dart.
///
/// Počítají se jedním průchodem historie od nejstaršího tréninku, takže
/// u každého odznaku je známé, kterým tréninkem se odemkl.
library;

import '../core/i18n.dart';
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
  workouts,
  consistency,
  strength,
  habits;

  String get label => switch (this) {
    workouts => tr('Tréninky', 'Workouts'),
    consistency => tr('Pravidelnost', 'Consistency'),
    strength => tr('Síla a objem', 'Strength and volume'),
    habits => tr('Zvyky', 'Habits'),
  };
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

  /// Drobnost podle času začátku: po tréninku se ukáže menší než
  /// skutečné milníky.
  bool get bonus =>
      metric == BadgeMetric.earlyStarts || metric == BadgeMetric.lateStarts;
}

List<Achievement> get achievements => [
  Achievement(
    'w1',
    tr('První krok', 'First step'),
    tr('Dokonči první trénink.', 'Complete your first workout.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    1,
  ),
  Achievement(
    'w10',
    tr('Rozjezd', 'Getting started'),
    tr('Dokonči 10 tréninků.', 'Complete 10 workouts.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    10,
  ),
  Achievement(
    'w25',
    tr('Stálice', 'Regular'),
    tr('Dokonči 25 tréninků.', 'Complete 25 workouts.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    25,
  ),
  Achievement(
    'w50',
    tr('Padesátka', 'Fifty'),
    tr('Dokonči 50 tréninků.', 'Complete 50 workouts.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    50,
  ),
  Achievement(
    'w100',
    tr('Stovka', 'Century'),
    tr('Dokonči 100 tréninků.', 'Complete 100 workouts.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    100,
  ),
  Achievement(
    'w250',
    tr('Železný', 'Iron man'),
    tr('Dokonči 250 tréninků.', 'Complete 250 workouts.'),
    BadgeGroup.workouts,
    BadgeMetric.workouts,
    250,
  ),
  Achievement(
    'r2',
    tr('Dva týdny', 'Two weeks'),
    tr('Cvič 2 týdny po sobě.', 'Train for 2 weeks in a row.'),
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    2,
  ),
  Achievement(
    'r4',
    tr('Měsíc v kuse', 'Month in a row'),
    tr('Cvič 4 týdny po sobě.', 'Train for 4 weeks in a row.'),
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    4,
  ),
  Achievement(
    'r8',
    tr('Dva měsíce', 'Two months'),
    tr('Cvič 8 týdnů po sobě.', 'Train for 8 weeks in a row.'),
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    8,
  ),
  Achievement(
    'r16',
    tr('Návyk', 'Habit'),
    tr('Cvič 16 týdnů po sobě.', 'Train for 16 weeks in a row.'),
    BadgeGroup.consistency,
    BadgeMetric.weekRun,
    16,
  ),
  Achievement(
    'ww3',
    tr('Plný týden', 'Full week'),
    tr('Dej 3 tréninky v jednom týdnu.', 'Do 3 workouts in one week.'),
    BadgeGroup.consistency,
    BadgeMetric.weekWorkouts,
    3,
  ),
  Achievement(
    'v10',
    tr('10 tun', '10 tons'),
    tr('Zvedni celkem 10 tun.', 'Lift 10 tons in total.'),
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    10,
  ),
  Achievement(
    'v50',
    tr('50 tun', '50 tons'),
    tr('Zvedni celkem 50 tun.', 'Lift 50 tons in total.'),
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    50,
  ),
  Achievement(
    'v100',
    tr('100 tun', '100 tons'),
    tr('Zvedni celkem 100 tun.', 'Lift 100 tons in total.'),
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    100,
  ),
  Achievement(
    'v500',
    tr('500 tun', '500 tons'),
    tr('Zvedni celkem 500 tun.', 'Lift 500 tons in total.'),
    BadgeGroup.strength,
    BadgeMetric.volumeTons,
    500,
  ),
  Achievement(
    'p1',
    tr('První rekord', 'First record'),
    tr('Překonej svůj osobní rekord.', 'Beat your personal record.'),
    BadgeGroup.strength,
    BadgeMetric.records,
    1,
  ),
  Achievement(
    'p10',
    tr('Lovec rekordů', 'Record hunter'),
    tr('Překonej 10 osobních rekordů.', 'Beat 10 personal records.'),
    BadgeGroup.strength,
    BadgeMetric.records,
    10,
  ),
  Achievement(
    'p50',
    tr('Sběratel', 'Collector'),
    tr('Překonej 50 osobních rekordů.', 'Beat 50 personal records.'),
    BadgeGroup.strength,
    BadgeMetric.records,
    50,
  ),
  Achievement(
    's100',
    tr('100 sérií', '100 sets'),
    tr('Odcvič 100 pracovních sérií.', 'Complete 100 working sets.'),
    BadgeGroup.habits,
    BadgeMetric.sets,
    100,
  ),
  Achievement(
    's1000',
    tr('1000 sérií', '1000 sets'),
    tr('Odcvič 1000 pracovních sérií.', 'Complete 1000 working sets.'),
    BadgeGroup.habits,
    BadgeMetric.sets,
    1000,
  ),
  Achievement(
    'long',
    tr('Vytrvalec', 'Endurance'),
    tr(
      'Dokonči aspoň hodinový trénink.',
      'Complete a workout of at least one hour.',
    ),
    BadgeGroup.habits,
    BadgeMetric.longMinutes,
    60,
  ),
  Achievement(
    'early',
    tr('Ranní ptáče', 'Early bird'),
    tr('Začni trénink před 7:00.', 'Start a workout before 7:00.'),
    BadgeGroup.habits,
    BadgeMetric.earlyStarts,
    1,
  ),
  Achievement(
    'late',
    tr('Noční směna', 'Night shift'),
    tr('Začni trénink po 21:00.', 'Start a workout after 21:00.'),
    BadgeGroup.habits,
    BadgeMetric.lateStarts,
    1,
  ),
  Achievement(
    'var20',
    tr('Všestranný', 'Versatile'),
    tr('Vyzkoušej 20 různých cviků.', 'Try 20 different exercises.'),
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
