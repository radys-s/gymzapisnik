/// Náročnost série (RPE) a opakování v zásobě. Čistý Dart.
library;

import '../core/i18n.dart';

/// Hodnoty nabízené v listu série.
const rpeChoices = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];

/// „8“, „7,5“.
String formatRpe(double rpe) {
  final raw = rpe == rpe.roundToDouble()
      ? rpe.toStringAsFixed(0)
      : rpe.toStringAsFixed(1);
  return isEnglish ? raw : raw.replaceAll('.', ',');
}

/// Co hodnota znamená: kolik opakování zbylo v zásobě.
String rpeHint(double rpe) {
  final rir = 10 - rpe;
  if (rir <= 0) return tr('Na maximum, nic v zásobě', 'All out, nothing left');
  if (rir >= 4) {
    return tr('Lehké, 4 a víc opakování v zásobě', 'Easy, 4+ reps in the tank');
  }
  if (rir == rir.roundToDouble()) {
    final n = rir.toStringAsFixed(0);
    return tr('$n opakování v zásobě', '$n reps in the tank');
  }
  return tr(
    '${rir.floor()}–${rir.ceil()} opakování v zásobě',
    '${rir.floor()}–${rir.ceil()} reps in the tank',
  );
}
