/// Párování sérií s minulým tréninkem. Čistý Dart.
library;

import 'models.dart';

/// Hodnoty „minule" pro každou sérii v [current]: stejný druh (rozcvička
/// nebo pracovní) a stejné pořadí v rámci druhu. Rozcvička tak nikdy
/// neukazuje pracovní váhu a přidaná rozcvička neposune pracovní série.
List<SetEntry?> previousSets(List<SetEntry> current, List<SetEntry> last) {
  final warmups = [
    for (final s in last)
      if (s.warmup) s,
  ];
  final working = [
    for (final s in last)
      if (!s.warmup) s,
  ];
  var w = 0;
  var k = 0;
  final result = <SetEntry?>[];
  for (final s in current) {
    final pool = s.warmup ? warmups : working;
    final i = s.warmup ? w++ : k++;
    result.add(i < pool.length ? pool[i] : null);
  }
  return result;
}

/// Nová pracovní série: hodnoty z minula na stejné pozici mezi pracovními
/// sériemi, jinak kopie poslední pracovní (případně jakékoli) série.
SetEntry nextWorkingSet(List<SetEntry> current, List<SetEntry> last) {
  final index = current.where((s) => !s.warmup).length;
  final working = [
    for (final s in last)
      if (!s.warmup) s,
  ];
  final source = index < working.length
      ? working[index]
      : current.lastWhere(
          (s) => !s.warmup,
          orElse: () => current.lastOrNull ?? SetEntry(),
        );
  return source.copy(done: false)..warmup = false;
}
