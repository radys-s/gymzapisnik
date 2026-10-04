/// Dvojitá progrese s automatickým odlehčením. Čistý Dart bez Flutteru.
///
/// Pravidla (v tomto pořadí):
/// 1. Bez historie: uživatel zvolí váhu sám, cíl je spodní hranice rozsahu.
/// 2. Dvakrát po sobě bez posunu (nejlepší série) → odlehčení o 10 %.
/// 3. Všechny plánované série na horní hranici → přidat váhu, zpět na spodní.
/// 4. Jinak držet váhu a přidat opakování.
library;

import '../domain/history.dart';
import '../domain/models.dart';
import '../domain/stats.dart';
import 'splits.dart';

enum SuggestionKind { start, increase, hold, deload }

/// Klíč v `WorkoutExercise.extra`, pod kterým se ukládá použitý návrh.
const coachKey = 'coach';

class Suggestion {
  final SuggestionKind kind;

  /// `0` = váhu zvolí uživatel (první provedení) nebo jde o vlastní váhu.
  final double weight;
  final int reps;
  final int sets;

  /// Vysvětlení česky, ukazuje se u cviku.
  final String reason;

  const Suggestion({
    required this.kind,
    required this.weight,
    required this.reps,
    required this.sets,
    required this.reason,
  });

  List<SetEntry> toSets() => [
    for (var i = 0; i < sets; i++) SetEntry(weight: weight, reps: reps),
  ];

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'weight': weight,
    'reps': reps,
    'sets': sets,
    'reason': reason,
  };
}

String _kg(double v) {
  final text = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
}

double roundTo(double value, double step) =>
    step <= 0 ? value : (value / step).round() * step;

bool _wasDeload(ExerciseSession s) {
  final coach = s.entry.extra[coachKey];
  return coach is Map && coach['kind'] == SuggestionKind.deload.name;
}

/// Návrh na další provedení cviku podle plánu a historie (od nejstarší).
Suggestion suggest(
  PlannedExercise plan,
  ExerciseType type,
  List<ExerciseSession> history, {
  double increment = 2.5,
}) {
  if (history.isEmpty) {
    return Suggestion(
      kind: SuggestionKind.start,
      weight: 0,
      reps: plan.repMin,
      sets: plan.sets,
      reason: type == ExerciseType.weighted
          ? 'Poprvé: zvol váhu, se kterou dáš ${plan.repMax} opakování '
                's 1–2 v rezervě.'
          : 'Poprvé: udělej ${plan.repMin}–${plan.repMax} opakování v sérii.',
    );
  }

  final last = history.last;
  final working = last.entry.countedSets;
  final topWeight = working
      .map((s) => s.weight)
      .reduce((a, b) => a > b ? a : b);
  final atTop = working.where((s) => s.weight == topWeight).toList();
  final minReps = atTop.map((s) => s.reps).reduce((a, b) => a < b ? a : b);
  final maxReps = working.map((s) => s.reps).reduce((a, b) => a > b ? a : b);

  // Odlehčení: tři poslední provedení bez zlepšení nejlepší série,
  // a žádné z nich nebylo samo odlehčením.
  if (history.length >= 3 && type == ExerciseType.weighted) {
    final recent = history.sublist(history.length - 3);
    final best = [for (final s in recent) bestSet(type, s.entry.countedSets)!];
    final stalled =
        compareSets(type, best[1], best[0]) <= 0 &&
        compareSets(type, best[2], best[1]) <= 0;
    if (stalled && !recent.any(_wasDeload) && topWeight > 0) {
      final lighter = roundTo(topWeight * 0.9, increment);
      return Suggestion(
        kind: SuggestionKind.deload,
        weight: lighter,
        reps: plan.repMax,
        sets: plan.sets,
        reason:
            'Dvakrát po sobě bez posunu → lehčí trénink: ${_kg(lighter)} kg '
            '(−10 %). Příště se vrátíš na ${_kg(topWeight)} kg s čerstvou silou.',
      );
    }
  }

  if (type == ExerciseType.bodyweight && topWeight == 0) {
    final target = minReps + 1;
    return Suggestion(
      kind: maxReps >= plan.repMax
          ? SuggestionKind.increase
          : SuggestionKind.hold,
      weight: 0,
      reps: target,
      sets: plan.sets,
      reason: minReps >= plan.repMax
          ? 'Zvládáš ${plan.repMax}+ opakování → zkus přidat zátěž '
                'nebo těžší variantu.'
          : 'Minule nejméně $minReps opakování → zkus $target v každé sérii.',
    );
  }

  final allAtTop = atTop.length >= plan.sets && minReps >= plan.repMax;
  if (allAtTop) {
    final next = topWeight + increment;
    return Suggestion(
      kind: SuggestionKind.increase,
      weight: next,
      reps: plan.repMin,
      sets: plan.sets,
      reason:
          'Minule ${atTop.length}× ${plan.repMax}+ na ${_kg(topWeight)} kg '
          '→ přidej ${_kg(increment)} kg a začni na ${plan.repMin} opakováních.',
    );
  }
  final target = (minReps + 1).clamp(plan.repMin, plan.repMax);
  return Suggestion(
    kind: SuggestionKind.hold,
    weight: topWeight,
    reps: target,
    sets: plan.sets,
    reason:
        'Drž ${_kg(topWeight)} kg a zkus $target opakování v každé sérii. '
        'Až dáš ${plan.sets}× ${plan.repMax}, přidáš váhu.',
  );
}

/// Index dalšího dne splitu: po posledním odcvičeném dni tohoto splitu.
int nextDayIndex(SplitTemplate split, Iterable<Workout> workouts) {
  for (final w in finishedNewestFirst(workouts)) {
    if (w.extra['split'] == split.id && w.extra['splitDay'] is num) {
      return ((w.extra['splitDay'] as num).toInt() + 1) % split.days.length;
    }
  }
  return 0;
}
