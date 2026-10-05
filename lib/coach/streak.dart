/// Streak po týdnech: kolik týdnů v řadě byl splněný týdenní cíl.
/// Čistý Dart.
///
/// Týdny jsou férovější než dny (nemoc, škola, zápas). Žolík automaticky
/// zachrání jeden zmeškaný týden, pak se obnoví za [jokerCooldownWeeks] týdnů.
library;

import 'weeks.dart';

const jokerCooldownWeeks = 8;

class Streak {
  /// Týdny v řadě včetně rozběhnutého, pokud už je splněný.
  final int weeks;

  /// Tento týden už cíl splnil.
  final bool currentWeekMet;

  /// Žolík je připravený zachránit příští zmeškaný týden.
  final bool jokerReady;

  /// Žolík zachránil poslední dokončený týden.
  final bool jokerJustUsed;

  const Streak({
    required this.weeks,
    required this.currentWeekMet,
    required this.jokerReady,
    required this.jokerJustUsed,
  });
}

Streak computeStreak({
  required int goal,
  required Iterable<DateTime> finished,
  required DateTime now,
}) {
  final perWeek = <DateTime, int>{};
  DateTime? first;
  final today = dayStart(now);
  for (final f in finished) {
    if (dayStart(f).isAfter(today)) continue;
    final w = weekStart(f);
    perWeek.update(w, (n) => n + 1, ifAbsent: () => 1);
    if (first == null || w.isBefore(first)) first = w;
  }
  final thisWeek = weekStart(now);
  final currentMet = (perWeek[thisWeek] ?? 0) >= goal;
  if (first == null || !first.isBefore(thisWeek)) {
    return Streak(
      weeks: currentMet ? 1 : 0,
      currentWeekMet: currentMet,
      jokerReady: true,
      jokerJustUsed: false,
    );
  }
  var streak = 0;
  var sinceJoker = jokerCooldownWeeks;
  var justUsed = false;
  for (var w = first; w.isBefore(thisWeek); w = nextWeek(w)) {
    justUsed = false;
    if ((perWeek[w] ?? 0) >= goal) {
      streak++;
      sinceJoker++;
    } else if (streak > 0 && sinceJoker >= jokerCooldownWeeks) {
      sinceJoker = 0;
      justUsed = true;
    } else {
      streak = 0;
      sinceJoker++;
    }
  }
  return Streak(
    weeks: streak + (currentMet ? 1 : 0),
    currentWeekMet: currentMet,
    jokerReady: sinceJoker >= jokerCooldownWeeks,
    jokerJustUsed: justUsed,
  );
}
