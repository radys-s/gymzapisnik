/// Supersérie: cviky odcvičené střídavě bez pauzy mezi nimi. Čistý Dart.
///
/// Cvik nese ID skupiny v `WorkoutExercise.extra[supersetKey]`. Skupinu
/// tvoří jen cviky, které jdou v tréninku hned po sobě a mají stejné ID;
/// osamocený cvik (po odebrání nebo přesunu souseda) supersérií není.
library;

import 'models.dart';

const supersetKey = 'superset';

/// ID skupiny cviku, nebo `null`.
String? supersetId(WorkoutExercise e) {
  final v = e.extra[supersetKey];
  return v is String && v.isNotEmpty ? v : null;
}

/// Místo cviku v supersérii.
class SupersetSlot {
  /// Pořadí skupiny v tréninku od nuly (0 = A, 1 = B…).
  final int group;

  /// Pozice cviku ve skupině od nuly.
  final int position;

  /// Počet cviků ve skupině (vždy aspoň 2).
  final int size;

  const SupersetSlot(this.group, this.position, this.size);

  /// Písmeno skupiny: A, B, C…
  String get letter => String.fromCharCode(0x41 + group % 26);

  bool get isFirst => position == 0;
  bool get isLast => position == size - 1;

  @override
  bool operator ==(Object other) =>
      other is SupersetSlot &&
      other.group == group &&
      other.position == position &&
      other.size == size;

  @override
  int get hashCode => Object.hash(group, position, size);

  @override
  String toString() => 'SupersetSlot($letter ${position + 1}/$size)';
}

/// Místo každého cviku v supersérii (`null` = samostatný cvik).
List<SupersetSlot?> supersetSlots(List<WorkoutExercise> exercises) {
  final result = List<SupersetSlot?>.filled(exercises.length, null);
  var group = 0;
  var i = 0;
  while (i < exercises.length) {
    final id = supersetId(exercises[i]);
    var end = i + 1;
    if (id != null) {
      while (end < exercises.length && supersetId(exercises[end]) == id) {
        end++;
      }
    }
    final size = end - i;
    if (size >= 2) {
      for (var k = i; k < end; k++) {
        result[k] = SupersetSlot(group, k - i, size);
      }
      group++;
    }
    i = end;
  }
  return result;
}

/// Cviky ve stejné supersérii jako [entry] (včetně něj), v pořadí tréninku.
List<WorkoutExercise> supersetOf(
  List<WorkoutExercise> exercises,
  WorkoutExercise entry,
) {
  final index = exercises.indexOf(entry);
  if (index < 0) return const [];
  final id = supersetId(entry);
  if (id == null) return [entry];
  var start = index;
  while (start > 0 && supersetId(exercises[start - 1]) == id) {
    start--;
  }
  var end = index + 1;
  while (end < exercises.length && supersetId(exercises[end]) == id) {
    end++;
  }
  return exercises.sublist(start, end);
}

bool _pending(WorkoutExercise e) => e.sets.any((s) => !s.done && !s.warmup);

/// Spustit pauzu po potvrzení série cviku [entry]? V supersérii se
/// odpočívá až po posledním cviku kola: dokud má některý další cvik
/// skupiny nepotvrzenou pracovní sérii, jde se rovnou na něj.
bool restsAfter(List<WorkoutExercise> exercises, WorkoutExercise entry) {
  final group = supersetOf(exercises, entry);
  if (group.length < 2) return true;
  final after = group.skip(group.indexOf(entry) + 1);
  return !after.any(_pending);
}

/// Další cvik, na který se v supersérii přechází bez pauzy (`null`, když
/// se po [entry] odpočívá).
WorkoutExercise? nextInSuperset(
  List<WorkoutExercise> exercises,
  WorkoutExercise entry,
) {
  final group = supersetOf(exercises, entry);
  if (group.length < 2) return null;
  return group.skip(group.indexOf(entry) + 1).where(_pending).firstOrNull;
}

/// Spojí [entry] s cvikem hned za ním do supersérie (přidá ho do
/// skupiny, kterou už jeden z nich má). Vrací `false`, když za ním nic není.
bool linkWithNext(
  List<WorkoutExercise> exercises,
  WorkoutExercise entry, {
  required String newId,
}) {
  final index = exercises.indexOf(entry);
  if (index < 0 || index + 1 >= exercises.length) return false;
  final next = exercises[index + 1];
  final id = supersetId(entry) ?? supersetId(next) ?? newId;
  // Soused za dalším cvikem se starým ID by se jinak připojil taky.
  final old = supersetId(next);
  if (old != null && old != id) {
    for (final e in supersetOf(exercises, next)) {
      e.extra[supersetKey] = id;
    }
  }
  entry.extra[supersetKey] = id;
  next.extra[supersetKey] = id;
  return true;
}

/// Vyjme [entry] ze supersérie. Zbyde-li ve skupině jediný cvik, zruší ji
/// celou. Když cvik stál uprostřed, zbylé dvě části dostanou různá ID,
/// aby se po přesunu znovu nespojily.
void unlink(
  List<WorkoutExercise> exercises,
  WorkoutExercise entry, {
  required String newId,
}) {
  final group = supersetOf(exercises, entry);
  entry.extra.remove(supersetKey);
  if (group.length < 2) return;
  final at = group.indexOf(entry);
  final before = group.sublist(0, at);
  final after = group.sublist(at + 1);
  for (final part in [before, after]) {
    if (part.length < 2) {
      for (final e in part) {
        e.extra.remove(supersetKey);
      }
    }
  }
  if (before.length >= 2 && after.length >= 2) {
    for (final e in after) {
      e.extra[supersetKey] = newId;
    }
  }
}
