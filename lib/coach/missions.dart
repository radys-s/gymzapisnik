/// Dnešní mise: co dnes dělat, aby se stihl týdenní cíl. Čistý Dart.
///
/// Žádné trestání: mise jen říká, kolik zbývá a jestli je dnes dobrý den
/// na trénink. Týden začíná v pondělí.
library;

import 'weeks.dart';

enum MissionKind {
  /// Týdenní cíl je splněný.
  weekDone,

  /// Dnes už se trénovalo.
  doneToday,

  /// Zbývá právě tolik tréninků co dní: trénovat je potřeba dnes.
  /// Ne v týdnu, kdy uživatel začal, a ne když už cíl stihnout nejde.
  catchUp,

  /// Včera se trénovalo a cíl se dá stihnout i bez tréninku dnes.
  rest,

  /// Dnes je dobrý den na trénink.
  trainToday,

  /// Dnes není v plánu trénink (uživatel si zvolil dny tréninku).
  plannedRest,
}

class Mission {
  final MissionKind kind;

  /// Tréninky v tomto týdnu.
  final int done;
  final int goal;

  /// Kolik tréninků do cíle ještě chybí (0 po splnění).
  final int remaining;

  /// Dnů do konce týdne včetně dneška.
  final int daysLeft;

  const Mission({
    required this.kind,
    required this.done,
    required this.goal,
    required this.remaining,
    required this.daysLeft,
  });

  /// Dnes se doporučuje trénovat (ne odpočívat).
  bool get shouldTrain =>
      kind == MissionKind.trainToday || kind == MissionKind.catchUp;
}

/// Mise na [now] podle dokončených tréninků ([finished]) a týdenního cíle.
/// [startedAt] je začátek používání aplikace (první týden se nenaléhá).
Mission todayMission({
  required int goal,
  required Iterable<DateTime> finished,
  required DateTime now,
  DateTime? startedAt,
  List<int>? trainingDays,
}) {
  final today = dayStart(now);
  final monday = weekStart(now);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  var done = 0;
  var trainedToday = false;
  var trainedYesterday = false;
  for (final f in finished) {
    final day = dayStart(f);
    if (day.isBefore(monday) || day.isAfter(today)) continue;
    done++;
    if (day == today) trainedToday = true;
    if (day == yesterday) trainedYesterday = true;
  }
  final remaining = done >= goal ? 0 : goal - done;
  final daysLeft = 8 - today.weekday;
  // První týden: začátek používání v tomto týdnu a žádná starší historie
  // (stávající uživatel s novým souhlasem první týden nemá).
  final firstWeek =
      startedAt != null &&
      !dayStart(startedAt).isBefore(monday) &&
      !finished.any((f) => dayStart(f).isBefore(monday));
  final MissionKind kind;
  if (remaining == 0) {
    kind = MissionKind.weekDone;
  } else if (trainedToday) {
    kind = MissionKind.doneToday;
  } else if (remaining == daysLeft && !firstWeek) {
    kind = MissionKind.catchUp;
  } else if (trainedYesterday) {
    kind = MissionKind.rest;
  } else if (trainingDays != null && !trainingDays.contains(today.weekday)) {
    kind = MissionKind.plannedRest;
  } else {
    kind = MissionKind.trainToday;
  }
  return Mission(
    kind: kind,
    done: done,
    goal: goal,
    remaining: remaining,
    daysLeft: daysLeft,
  );
}
