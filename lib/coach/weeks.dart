/// Týdny pro misi a streak. Čistý Dart bez Flutteru.
library;

/// Pondělí 00:00 místního času týdne, do kterého [d] patří.
DateTime weekStart(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day - (l.weekday - 1));
}

/// Začátek následujícího týdne (bezpečné i přes změnu času).
DateTime nextWeek(DateTime monday) =>
    DateTime(monday.year, monday.month, monday.day + 7);

/// Půlnoc místního dne.
DateTime dayStart(DateTime d) {
  final l = d.toLocal();
  return DateTime(l.year, l.month, l.day);
}
