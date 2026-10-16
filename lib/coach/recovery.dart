/// Regenerace partií podle nedávných těžkých sérií. Čistý Dart.
///
/// Hrubý odhad pro výběr, co dnes cvičit: velké partie potřebují zhruba
/// 72 hodin, malé 48 hodin. Vedlejší zapojení (triceps u benche) se počítá
/// napůl a jen pár sérií zotavení zkracuje.
library;

import '../domain/anatomy.dart';
import '../domain/models.dart';
import 'splits.dart';
import 'tips.dart';

/// Velké partie: delší regenerace.
const _bigFocuses = {'chest', 'back', 'legs', 'glutes'};

/// Kolik hodin potřebuje partie po plném tréninku.
int recoveryHours(String focusId) => _bigFocuses.contains(focusId) ? 72 : 48;

/// Od tolika sérií (vedlejší napůl) se počítá plná doba regenerace.
const _fullLoadSets = 6.0;

class FocusRecovery {
  final String focusId;

  /// 0 = právě odcvičeno, 1 = připraveno.
  final double ready;

  /// Kdy bude partie připravená (`null` = už je).
  final DateTime? readyAt;

  const FocusRecovery(this.focusId, this.ready, this.readyAt);

  bool get isReady => ready >= 1;
}

/// Regenerace všech partií z [dayFocuses] k času [now].
///
/// Na rozdíl od týdenního objemu (jen první hlavní hlava) unaví cvik
/// všechny partie svých hlavních hlav, protože jde o to, co dnes nebolí.
/// Vlastní cviky bez anatomie se počítají podle skupiny ([muscleOf]).
Map<String, FocusRecovery> recoveryByFocus(
  Iterable<Workout> workouts,
  DateTime now, {
  String Function(String exerciseId)? muscleOf,
}) {
  final window = <String, (DateTime, DateTime)>{};
  final windowStart = now.subtract(const Duration(hours: 72));
  for (final w in workouts) {
    final end = w.finishedAt;
    if (end == null || end.isBefore(windowStart)) continue;
    // Hodiny jiného zařízení můžou být o chvíli napřed.
    final at = end.isAfter(now) ? now : end;
    final load = <String, double>{};
    for (final e in w.exercises) {
      final sets = e.countedSets.length;
      if (sets == 0) continue;
      final anatomy = anatomyOf(e.exerciseId);
      if (anatomy == null) {
        final f = muscleOf == null
            ? null
            : focusOfMuscle(muscleOf(e.exerciseId));
        if (f != null) load[f] = (load[f] ?? 0) + sets;
        continue;
      }
      final primary = {for (final h in anatomy.primary) ?focusOfHead(h)};
      final secondary = {for (final h in anatomy.secondary) ?focusOfHead(h)}
          .difference(primary);
      for (final f in primary) {
        load[f] = (load[f] ?? 0) + sets;
      }
      for (final f in secondary) {
        load[f] = (load[f] ?? 0) + sets / 2;
      }
    }
    for (final MapEntry(key: f, value: sets) in load.entries) {
      final share = (sets / _fullLoadSets).clamp(0.34, 1.0);
      final hours = (recoveryHours(f) * share).round();
      final until = at.add(Duration(hours: hours));
      final current = window[f];
      if (current == null || until.isAfter(current.$2)) window[f] = (at, until);
    }
  }
  return {
    for (final focus in dayFocuses)
      focus.id: _state(focus.id, window[focus.id], now),
  };
}

FocusRecovery _state(String id, (DateTime, DateTime)? window, DateTime now) {
  if (window == null || !window.$2.isAfter(now)) {
    return FocusRecovery(id, 1, null);
  }
  final (from, until) = window;
  final total = until.difference(from).inMinutes;
  final done = now.difference(from).inMinutes;
  return FocusRecovery(id, (done / total).clamp(0, 0.99), until);
}

/// Partie pro „Sestavit z odpočatých“: připravené partie s nejmenším
/// týdenním objemem, nejvýš dvě velké a zbytek malé (ať to není trénink
/// jen z lýtek a bicepsu). Nejvýš [limit].
List<String> suggestFocuses(
  Map<String, FocusRecovery> recovery,
  Map<String, int> weeklySets, {
  int limit = 3,
}) {
  final order = [for (final f in dayFocuses) f.id];
  int byVolume(String a, String b) {
    final bySets = (weeklySets[a] ?? 0).compareTo(weeklySets[b] ?? 0);
    return bySets != 0 ? bySets : order.indexOf(a) - order.indexOf(b);
  }

  final ready = [
    for (final id in order)
      if (recovery[id]?.isReady ?? true) id,
  ];
  final big = ready.where(_bigFocuses.contains).toList()..sort(byVolume);
  final small = ready.where((f) => !_bigFocuses.contains(f)).toList()
    ..sort(byVolume);
  final picked = big.take(2).toList();
  return [...picked, ...small].take(limit).toList();
}
