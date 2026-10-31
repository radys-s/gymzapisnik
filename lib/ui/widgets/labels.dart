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
  if (minutes < 1) return '< 1 min';
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}

/// Objem s jednotkou podle typu cviku.
String volumeLabel(ExerciseType type, double value) =>
    type == ExerciseType.weighted
    ? '${formatVolume(value)} kg'
    : '${formatVolume(value)} opak.';

/// „1 série", „3 série", „5 sérií".
String setsLabel(int n) => '$n ${setsNoun(n)}';

/// Jen slovo k počtu sérií (čeština podle CLDR: 22 sérií).
String setsNoun(int n) => n == 1 || (n >= 2 && n <= 4) ? 'série' : 'sérií';

/// „1 trénink", „3 tréninky", „5 tréninků".
String workoutsLabel(int n) =>
    '$n ${n == 1
        ? 'trénink'
        : (n >= 2 && n <= 4)
        ? 'tréninky'
        : 'tréninků'}';

/// „1 týden", „3 týdny", „5 týdnů".
String weeksLabel(int n) =>
    '$n ${n == 1
        ? 'týden'
        : (n >= 2 && n <= 4)
        ? 'týdny'
        : 'týdnů'}';

/// „1 cvik", „3 cviky", „5 cviků".
String exercisesLabel(int n) =>
    '$n ${n == 1
        ? 'cvik'
        : (n >= 2 && n <= 4)
        ? 'cviky'
        : 'cviků'}';

/// „1 den", „3 dny", „5 dní".
String daysLabel(int n) =>
    '$n ${n == 1
        ? 'den'
        : (n >= 2 && n <= 4)
        ? 'dny'
        : 'dní'}';

/// „Zbývá 1 trénink", „Zbývají 3 tréninky", „Zbývá 5 tréninků".
String remainingWorkoutsLabel(int n) =>
    '${n >= 2 && n <= 4 ? 'Zbývají' : 'Zbývá'} ${workoutsLabel(n)}';

/// Odhad délky tréninku: rozcvička a ~2,5 min na sérii i s pauzou,
/// zaokrouhleno na 5 min.
int workoutMinutes(int sets) => ((5 + sets * 2.5) / 5).round() * 5;

/// Pozdrav podle denní doby. V noci pořád večer: „dobrou noc“ je loučení.
String greeting(DateTime now) => switch (now.hour) {
  >= 5 && < 9 => 'Dobré ráno',
  >= 9 && < 12 => 'Dobré dopoledne',
  >= 12 && < 18 => 'Dobré odpoledne',
  _ => 'Dobrý večer',
};
