import '../../core/format.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';

/// Série jako text: „80×8", u vlastní váhy „8 opak." nebo „+10 kg × 8".
String setLabel(ExerciseType type, SetEntry set) {
  if (type == ExerciseType.bodyweight) {
    return set.weight > 0
        ? '+${formatKg(set.weight)} kg × ${set.reps}'
        : '${set.reps} opak.';
  }
  return '${formatKg(set.weight)}×${set.reps}';
}

/// Hodnota rekordu s jednotkou.
String recordLabel(RecordKind kind, double value) => switch (kind) {
  RecordKind.maxReps => '${value.round()} opak.',
  _ => '${formatKg(double.parse(value.toStringAsFixed(1)))} kg',
};

/// Délka tréninku: „52 min" nebo „1 h 05 min".
String durationLabel(Duration d) {
  final minutes = d.isNegative ? 0 : d.inMinutes;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}

/// Objem s jednotkou podle typu cviku.
String volumeLabel(ExerciseType type, double value) =>
    type == ExerciseType.weighted
    ? '${formatKg(value.roundToDouble())} kg'
    : '${value.round()} opak.';
