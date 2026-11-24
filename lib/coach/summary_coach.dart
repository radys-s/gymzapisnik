/// Co kouč řekne hned po tréninku: verdikt a cíle na příště. Čistý Dart.
library;

import '../core/format.dart';
import '../core/i18n.dart';
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
    return tr(
      'První trénink máš za sebou. Nejtěžší je začít a to už máš.',
      'Your first workout is done. Starting is the hardest part, and you have done it.',
    );
  }
  if (records > 0) {
    if (recordExercise == null) {
      final many = records < 5
          ? tr('nové rekordy', 'new records')
          : tr('nových rekordů', 'new records');
      return '$records $many${tr('. Takhle vypadá progres.', '. That is progress.')}';
    }
    return records == 1
        ? '${tr('Nový rekord', 'New record')}: $recordExercise'
              '${tr('. Takhle vypadá progres.', '. That is progress.')}'
        : '${tr('Nové rekordy', 'New records')}: $recordExercise'
              '${tr('. Takhle vypadá progres.', '. That is progress.')}';
  }
  if (compared == 0) {
    return tr(
      'Nové cviky máš zapsané. Příště uvidíš srovnání s dneškem.',
      'You have logged new exercises. Next time you will see a comparison with today.',
    );
  }
  final of = compared == 1 ? tr('cviku', 'exercise') : tr('cviků', 'exercises');
  if (better > worse) {
    return '${tr('Lepší než minule v', 'Better than last time in')} $better '
        '${tr('z', 'of')} $compared $of. ${tr('Jen tak dál.', 'Keep it up.')}';
  }
  if (better == 0 && worse == 0) {
    return tr(
      'Stejně jako minule. Příště zkus v každém cviku '
          'o opakování víc.',
      'Same as last time. Next time try one more rep on every exercise.',
    );
  }
  if (worse > better) {
    return tr(
      'Dnes slabší den, to k tréninku patří. Příště stejné váhy '
          'a dotáhni opakování.',
      'A weaker day happens. Next time keep the same weights and match the reps.',
    );
  }
  return tr(
    'Něco líp, něco hůř. Drž váhy a hlídej techniku.',
    'Some better, some worse. Keep the weights and watch your form.',
  );
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
