/// Co kouč řekne hned po tréninku: verdikt a cíle na příště. Čistý Dart.
library;

import '../core/format.dart';
import 'progression.dart';

/// Jednou větou, jak trénink dopadl proti minulému provedení.
///
/// [better] a [worse] počítají cviky, které mají s čím porovnat
/// ([compared]); nové cviky se do nich nepočítají.
String summaryVerdict({
  required int number,
  required int records,
  String? recordExercise,
  required int compared,
  required int better,
  required int worse,
}) {
  if (number == 1) {
    return 'První trénink máš za sebou. Nejtěžší je začít a to už máš.';
  }
  if (records > 0) {
    if (recordExercise == null) {
      final many = records < 5 ? 'nové rekordy' : 'nových rekordů';
      return '$records $many. Takhle vypadá progres.';
    }
    return records == 1
        ? 'Nový rekord: $recordExercise. Takhle vypadá progres.'
        : 'Nové rekordy: $recordExercise. Takhle vypadá progres.';
  }
  if (compared == 0) {
    return 'Nové cviky máš zapsané. Příště uvidíš srovnání s dneškem.';
  }
  final of = compared == 1 ? 'cviku' : 'cviků';
  if (better > worse) {
    return 'Lepší než minule v $better z $compared $of. Jen tak dál.';
  }
  if (better == 0 && worse == 0) {
    return 'Stejně jako minule. Příště zkus v každém cviku '
        'o opakování víc.';
  }
  if (worse > better) {
    return 'Dnes slabší den, to k tréninku patří. Příště stejné váhy '
        'a dotáhni opakování.';
  }
  return 'Něco líp, něco hůř. Drž váhy a hlídej techniku.';
}

/// Cíl na příští provedení cviku, např. „Dřep 62,5 kg × 5“.
///
/// `null`, když návrh nic konkrétního neříká (bez historie nebo bez Pro).
String? nextTargetLabel(String name, Suggestion s, {required bool weighted}) {
  if (s.kind == SuggestionKind.start || s.reps <= 0) return null;
  if (weighted) {
    return s.weight > 0 ? '$name ${formatKg(s.weight)} kg × ${s.reps}' : null;
  }
  return '$name × ${s.reps}';
}
