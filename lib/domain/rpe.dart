/// Náročnost série (RPE) a opakování v zásobě. Čistý Dart.
library;

/// Hodnoty nabízené v listu série.
const rpeChoices = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];

/// „8“, „7,5“.
String formatRpe(double rpe) => rpe == rpe.roundToDouble()
    ? rpe.toStringAsFixed(0)
    : rpe.toStringAsFixed(1).replaceAll('.', ',');

/// Co hodnota znamená: kolik opakování zbylo v zásobě.
String rpeHint(double rpe) {
  final rir = 10 - rpe;
  if (rir <= 0) return 'Na maximum, nic v zásobě';
  if (rir >= 4) return 'Lehké, 4 a víc opakování v zásobě';
  if (rir == rir.roundToDouble()) {
    return '${rir.toStringAsFixed(0)} opakování v zásobě';
  }
  return '${rir.floor()}–${rir.ceil()} opakování v zásobě';
}
