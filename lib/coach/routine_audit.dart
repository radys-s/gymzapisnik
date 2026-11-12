/// Kontrola rutiny: pokrývá každá partie všechny důležité hlavy a má
/// rozumný týdenní objem? Čistý Dart bez Flutteru.
///
/// Rutina = dny, které se cvičí dokola; každý den počítáme jednou týdně.
library;

import '../domain/anatomy.dart';
import '../domain/catalog.dart';
import '../domain/models.dart';
import 'splits.dart';

enum AuditKind { missingHead, missingFocus, lowVolume, highVolume }

class AuditFinding {
  /// Stálý klíč (pro animované vkládání a mazání v seznamu).
  final String id;
  final AuditKind kind;

  /// Partie z [dayFocuses].
  final String focusId;

  /// „Biceps: chybí krátká hlava“.
  final String title;

  /// Proč na tom záleží.
  final String detail;

  /// Navržený cvik, který nález vyřeší (`null` = nic vhodného).
  final String? exerciseId;

  /// Den (index), kam navržený cvik patří.
  final int dayIndex;

  const AuditFinding({
    required this.id,
    required this.kind,
    required this.focusId,
    required this.title,
    required this.detail,
    required this.dayIndex,
    this.exerciseId,
  });

  /// Upozornění (objem navíc) neblokuje, ostatní jsou mezery.
  bool get isGap => kind != AuditKind.highVolume;
}

/// Hlavy, které stačí trefit nepřímo: vedlejší nebo malé části.
const _optionalHeads = {
  'lower_back',
  'adductors',
  'glutes_med',
  'abs_lower',
  'obliques',
  'brachialis',
  'calves_soleus',
  'forearms',
};

/// Velké partie, které by v týdnu neměly chybět.
const _majorFocuses = {'chest', 'back', 'legs', 'shoulders'};

/// Malé partie dostanou objem i z velkých cviků, stačí jim méně.
const _smallFocuses = {'biceps', 'triceps', 'calves', 'core'};

/// Doporučený rozsah přímých sérií za týden.
(int, int) weeklyRange(String focusId) =>
    _smallFocuses.contains(focusId) ? (6, 16) : (10, 22);

/// Hlava -> partie výběru.
final Map<String, String> _focusOfHead = {
  for (final MapEntry(key: focus, value: heads) in focusHeads.entries)
    for (final h in heads) h: focus,
};

/// Krátký název hlavy do nadpisu („krátká hlava“, „zadní delt“).
String _shortHead(String headId) {
  final name = headById(headId)?.name ?? headId;
  final dash = name.indexOf('–');
  final short = dash >= 0 ? name.substring(dash + 1).trim() : name;
  return short[0].toLowerCase() + short.substring(1);
}

String _focusName(String focusId) => dayFocuses
    .firstWhere(
      (f) => f.id == focusId,
      orElse: () => DayFocus(focusId, focusId, focusId, const []),
    )
    .name;

String _sets(num n) {
  final v = n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
  final i = n.round();
  return '$v ${i == 1 ? 'série' : (i >= 2 && i <= 4 ? 'série' : 'sérií')}';
}

/// Nejlepší dostupný cvik, který hlavu [headId] cvičí jako hlavní.
String? suggestFor(
  String headId, {
  required Set<String> taken,
  bool Function(Exercise e)? allowed,
}) {
  String? fallback;
  for (final e in builtInExercises) {
    if (taken.contains(e.id)) continue;
    if (allowed != null && !allowed(e)) continue;
    final a = anatomyOf(e.id);
    if (a == null || !a.primary.contains(headId)) continue;
    if (a.primary.first == headId) return e.id;
    fallback ??= e.id;
  }
  return fallback;
}

/// Projde rutinu a vrátí nálezy seřazené od nejdůležitějších.
List<AuditFinding> auditRoutine(
  List<SplitDay> days, {
  bool Function(Exercise e)? allowed,
}) {
  if (days.every((d) => d.exercises.isEmpty)) return const [];
  final focusSets = <String, double>{};
  final headSets = <String, double>{};
  // Kam partie patří: den, kde se cvičí nejvíc.
  final focusDay = <String, (int, double)>{};
  final taken = <String>{};
  for (final (i, day) in days.indexed) {
    final dayFocus = <String, double>{};
    for (final p in day.exercises) {
      taken.add(p.exerciseId);
      final a = anatomyOf(p.exerciseId);
      if (a == null) continue;
      final focuses = <String, double>{};
      for (final h in a.primary) {
        headSets[h] = (headSets[h] ?? 0) + p.sets;
        final f = _focusOfHead[h];
        if (f != null) focuses[f] = 1;
      }
      for (final h in a.secondary) {
        headSets[h] = (headSets[h] ?? 0) + p.sets * 0.5;
        final f = _focusOfHead[h];
        if (f != null) focuses.putIfAbsent(f, () => 0.5);
      }
      for (final MapEntry(key: f, value: w) in focuses.entries) {
        focusSets[f] = (focusSets[f] ?? 0) + p.sets * w;
        if (w == 1) dayFocus[f] = (dayFocus[f] ?? 0) + p.sets;
      }
    }
    for (final MapEntry(key: f, value: s) in dayFocus.entries) {
      final best = focusDay[f];
      if (best == null || s > best.$2) focusDay[f] = (i, s);
    }
  }
  // Nejkratší den dostane chybějící velkou partii.
  var shortest = 0;
  for (final (i, d) in days.indexed) {
    if (d.exercises.length < days[shortest].exercises.length) shortest = i;
  }

  final out = <AuditFinding>[];
  for (final f in dayFocuses) {
    final sets = focusSets[f.id] ?? 0;
    final direct = focusDay[f.id];
    final (low, high) = weeklyRange(f.id);
    final name = _focusName(f.id);
    if (direct == null) {
      // Celá partie chybí: hlásíme jen velké, a jen u víc než jednoho dne.
      if (_majorFocuses.contains(f.id) && days.length >= 2 && sets < 4) {
        final head = focusHeads[f.id]!.first;
        out.add(
          AuditFinding(
            id: 'focus-${f.id}',
            kind: AuditKind.missingFocus,
            focusId: f.id,
            title: '$name: ${_sets(sets)} týdně',
            detail: 'Velká partie v rutině chybí. Přidej aspoň jeden cvik.',
            dayIndex: shortest,
            exerciseId: suggestFor(head, taken: taken, allowed: allowed),
          ),
        );
      }
      continue;
    }
    for (final head in focusHeads[f.id]!) {
      if (_optionalHeads.contains(head)) continue;
      if ((headSets[head] ?? 0) >= 2) continue;
      out.add(
        AuditFinding(
          id: 'head-$head',
          kind: AuditKind.missingHead,
          focusId: f.id,
          title: '$name: chybí ${_shortHead(head)}',
          detail: switch (head) {
            'biceps_short' =>
              'Krátkou hlavu nejvíc trefí zdvih s lokty před tělem, '
                  'třeba na Scottově lavici.',
            'biceps_long' =>
              'Dlouhá hlava pracuje nejvíc s pažemi za tělem, '
                  'třeba zdvih na šikmé lavici.',
            'triceps_long' =>
              'Dlouhá hlava potřebuje cvik s pažemi nad hlavou.',
            'delt_rear' => 'Zadní ramena drží rameno zdravé a plné zezadu.',
            'delt_side' =>
              'Boční delt dělá šířku ramen. Tlaky ho skoro netrefí.',
            'chest_upper' => 'Horní hrudník trefí tlak na šikmé lavici.',
            'hamstrings' => 'Zadní stehna vyvažují dřepy a chrání kolena.',
            _ => 'Tahle část partie zatím nedostává žádnou přímou práci.',
          },
          dayIndex: direct.$1,
          exerciseId: suggestFor(head, taken: taken, allowed: allowed),
        ),
      );
    }
    if (sets < low) {
      final head = focusHeads[f.id]!.first;
      out.add(
        AuditFinding(
          id: 'low-${f.id}',
          kind: AuditKind.lowVolume,
          focusId: f.id,
          title: '$name: ${_sets(sets)} týdně, málo',
          detail: 'Na růst počítej s $low až $high sériemi týdně.',
          dayIndex: direct.$1,
          exerciseId: suggestFor(head, taken: taken, allowed: allowed),
        ),
      );
    } else if (sets > high) {
      out.add(
        AuditFinding(
          id: 'high-${f.id}',
          kind: AuditKind.highVolume,
          focusId: f.id,
          title: '$name: ${_sets(sets)} týdně, hodně',
          detail:
              'Nad $high sérií týdně už to spíš unaví, než přidá. '
              'Zvaž ubrat.',
          dayIndex: direct.$1,
        ),
      );
    }
  }
  int rank(AuditKind k) => switch (k) {
    AuditKind.missingFocus => 0,
    AuditKind.missingHead => 1,
    AuditKind.lowVolume => 2,
    AuditKind.highVolume => 3,
  };
  out.sort((a, b) => rank(a.kind).compareTo(rank(b.kind)));
  return out;
}

/// Odcvičené série na partii od pondělí do [now] (hlavní cvik 1, vedlejší
/// 0,5, jako [auditRoutine]). Pro kartu pokrytí partií na Domů.
Map<String, double> weekCoverage(Iterable<Workout> workouts, DateTime now) {
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final out = <String, double>{};
  for (final w in workouts) {
    if (!w.finished || w.date.isBefore(monday) || w.date.isAfter(now)) {
      continue;
    }
    for (final e in w.exercises) {
      final a = anatomyOf(e.exerciseId);
      final sets = e.countedSets.length;
      if (a == null || sets == 0) continue;
      final focuses = <String, double>{};
      for (final h in a.primary) {
        if (_focusOfHead[h] case final f?) focuses[f] = 1;
      }
      for (final h in a.secondary) {
        if (_focusOfHead[h] case final f?) focuses.putIfAbsent(f, () => 0.5);
      }
      for (final MapEntry(key: f, value: wgt) in focuses.entries) {
        out[f] = (out[f] ?? 0) + sets * wgt;
      }
    }
  }
  return out;
}
