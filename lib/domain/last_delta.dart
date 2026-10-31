import 'models.dart';

/// Srovnání cviku s minulým tréninkem: nejtěžší pracovní série a objem.
typedef LastDelta = ({
  SetEntry lastTop,
  double lastVolume,
  SetEntry? nowTop,
  double nowVolume,
  int lastSets,
  int nowSets,
});

/// Nejtěžší série (při shodě víc opakování); jen započítané série.
SetEntry? topSet(Iterable<SetEntry> sets) {
  SetEntry? best;
  for (final s in sets.where((s) => s.counts)) {
    if (best == null ||
        s.weight > best.weight ||
        (s.weight == best.weight && s.reps > best.reps)) {
      best = s;
    }
  }
  return best;
}

double volumeOf(Iterable<SetEntry> sets) =>
    sets.where((s) => s.counts).fold(0.0, (a, s) => a + s.weight * s.reps);

/// `null`, když minule nebyla žádná započítaná série.
LastDelta? compareToLast(List<SetEntry> now, List<SetEntry> last) {
  final lastTop = topSet(last);
  if (lastTop == null) return null;
  return (
    lastTop: lastTop,
    lastVolume: volumeOf(last),
    nowTop: topSet(now),
    nowVolume: volumeOf(now),
    lastSets: last.where((s) => s.counts).length,
    nowSets: now.where((s) => s.counts).length,
  );
}
