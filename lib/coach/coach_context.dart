/// Krátký souhrn tréninků pro AI trenéra. Čistý Dart bez Flutteru.
///
/// Jen čísla a názvy cviků: žádné jméno, poznámky ani celá historie.
/// Vejde se pod limit proxy (6000 znaků JSON).
library;

import 'dart:convert';

import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/stats.dart';
import 'plan_quiz.dart';
import 'recovery.dart';
import 'splits.dart';

const _weekdays = ['po', 'út', 'st', 'čt', 'pá', 'so', 'ne'];

String _day(DateTime d) {
  final l = d.toLocal();
  final m = '${l.month}'.padLeft(2, '0');
  final day = '${l.day}'.padLeft(2, '0');
  return '${l.year}-$m-$day ${_weekdays[l.weekday - 1]}';
}

String _num(double v) => v == v.roundToDouble()
    ? v.toStringAsFixed(0)
    : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

/// „80×8“, u vlastní váhy „+10×8“ nebo „8 opak.“.
String _set(ExerciseType type, SetEntry s) => switch (type) {
  ExerciseType.weighted => '${_num(s.weight)}×${s.reps}',
  ExerciseType.bodyweight when s.weight > 0 => '+${_num(s.weight)}×${s.reps}',
  ExerciseType.bodyweight => '${s.reps} opak.',
};

Map<String, dynamic> coachContext({
  required DateTime now,
  required Iterable<Workout> workouts,
  required Exercise Function(String id) exercise,
  required bool adult,
  required int weekGoal,
  SplitTemplate? split,
  int nextDay = 0,
  PlanAnswers? plan,
  double? bodyweightKg,
  Map<String, FocusRecovery> recovery = const {},
  Map<String, String> focusNames = const {},
  int maxChars = 5500,
}) {
  final finished = finishedNewestFirst(workouts);
  final week = weekSummary(workouts, now, (id) => exercise(id).type);

  final recent = <Map<String, dynamic>>[
    for (final w in finished.take(5))
      {
        'date': _day(w.date),
        'name': w.name,
        if (w.finishedAt case final end?)
          'minutes': end.difference(w.startedAt).inMinutes.clamp(0, 600),
        'exercises': [
          for (final e in w.exercises)
            if (e.countedSets.isNotEmpty)
              {
                'name': exercise(e.exerciseId).name,
                'sets': [
                  for (final s in e.countedSets.take(6))
                    _set(exercise(e.exerciseId).type, s),
                ].join(', '),
              },
        ],
      },
  ];

  // Nejčastější cviky za posledních 8 týdnů: poslední 3 nejlepší série.
  final since = now.subtract(const Duration(days: 56));
  final counts = <String, int>{};
  for (final w in finished) {
    if (w.date.isBefore(since)) break;
    for (final e in w.exercises) {
      if (e.countedSets.isEmpty) continue;
      counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
    }
  }
  final top = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  final lifts = <Map<String, dynamic>>[
    for (final id in top.take(8))
      () {
        final ex = exercise(id);
        final history = exerciseHistory(workouts, id);
        final records = allTimeRecords(workouts, id, ex.type);
        return {
          'name': ex.name,
          'last': [
            for (final s in history.reversed.take(3))
              if (bestSet(ex.type, s.entry.countedSets) case final b?)
                '${_day(s.date)}: ${_set(ex.type, b)}',
          ],
          if (records[RecordKind.bestE1rm] case final r?)
            'bestE1rmKg': _num(double.parse(r.value.toStringAsFixed(1))),
        };
      }(),
  ];

  final day = split == null || split.days.isEmpty
      ? null
      : split.days[nextDay % split.days.length];
  final out = <String, dynamic>{
    'today': _day(now),
    'adult': adult,
    if (plan != null)
      'plan': {
        'goal': plan.goal.label,
        'level': plan.level.label,
        'daysPerWeek': plan.days,
        'minutesPerWorkout': plan.minutes,
      },
    'weekGoal': weekGoal,
    'thisWeek': {'workouts': week.workouts, 'sets': week.sets},
    if (finished.isNotEmpty)
      'daysSinceLast': now.difference(finished.first.date).inDays.clamp(0, 999),
    if (split != null) 'program': split.name,
    if (day != null)
      'nextDay': {
        'name': day.name,
        'exercises': [
          for (final p in day.exercises)
            '${exercise(p.exerciseId).name} ${p.sets}×${p.repMin}–${p.repMax}',
        ],
      },
    if (adult && bodyweightKg != null) 'bodyweightKg': _num(bodyweightKg),
    if (recovery.isNotEmpty)
      'recovery': {
        for (final r in recovery.values)
          focusNames[r.focusId] ?? r.focusId: r.isReady
              ? 'připraveno'
              : 'za ${r.readyAt!.difference(now).inHours.clamp(1, 72)} h',
      },
    'recentWorkouts': recent,
    'lifts': lifts,
  };
  // Moc dlouhé: nejdřív ubrat starší tréninky, pak méně časté cviky.
  while (jsonEncode(out).length > maxChars) {
    if (recent.length > 1) {
      recent.removeLast();
    } else if (lifts.isNotEmpty) {
      lifts.removeLast();
    } else if (recent.isNotEmpty) {
      recent.removeLast();
    } else {
      out.remove('nextDay');
      out.remove('recovery');
      break;
    }
  }
  return out;
}
