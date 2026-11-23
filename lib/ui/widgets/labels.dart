import '../../core/format.dart';
import '../../core/i18n.dart';
import '../../domain/models.dart';
import '../../domain/stats.dart';

/// Série jako text: „80×8", u vlastní váhy „8 opak." nebo „+10 kg × 8".
String setLabel(ExerciseType type, SetEntry set) {
  if (type == ExerciseType.bodyweight) {
    return set.weight > 0
        ? '+${formatKg(set.weight)} kg × ${set.reps}'
        : tr('${set.reps} opak.', '${set.reps} reps');
  }
  return '${formatKg(set.weight)}×${set.reps}';
}

/// Hodnota rekordu s jednotkou.
String recordLabel(RecordKind kind, double value) => switch (kind) {
  RecordKind.maxReps => tr('${value.round()} opak.', '${value.round()} reps'),
  _ => '${formatKg(double.parse(value.toStringAsFixed(1)))} kg',
};

/// Délka tréninku: „52 min" nebo „1 h 05 min".
String durationLabel(Duration d) {
  final minutes = d.isNegative ? 0 : d.inMinutes;
  if (minutes < 1) return tr('< 1 min', '< 1 min');
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')} min';
}

/// Objem s jednotkou podle typu cviku.
String volumeLabel(ExerciseType type, double value) =>
    type == ExerciseType.weighted
    ? '${formatVolume(value)} kg'
    : tr('${formatVolume(value)} opak.', '${formatVolume(value)} reps');

/// „1 série", „3 série", „5 sérií".
String setsLabel(int n) {
  if (isEnglish) return n == 1 ? '1 set' : '$n sets';
  return '$n ${setsNoun(n)}';
}

/// Jen slovo k počtu sérií (čeština podle CLDR: 22 sérií).
String setsNoun(int n) => n == 1 || (n >= 2 && n <= 4) ? 'série' : 'sérií';

/// „1 trénink", „3 tréninky", „5 tréninků".
String workoutsLabel(int n) {
  if (isEnglish) return n == 1 ? '1 workout' : '$n workouts';
  return '$n ${n == 1
      ? 'trénink'
      : (n >= 2 && n <= 4)
      ? 'tréninky'
      : 'tréninků'}';
}

/// „1 týden", „3 týdny", „5 týdnů".
String weeksLabel(int n) {
  if (isEnglish) return n == 1 ? '1 week' : '$n weeks';
  return '$n ${n == 1
      ? 'týden'
      : (n >= 2 && n <= 4)
      ? 'týdny'
      : 'týdnů'}';
}

/// „1 cvik", „3 cviky", „5 cviků".
String exercisesLabel(int n) {
  if (isEnglish) return n == 1 ? '1 exercise' : '$n exercises';
  return '$n ${n == 1
      ? 'cvik'
      : (n >= 2 && n <= 4)
      ? 'cviky'
      : 'cviků'}';
}

/// „1 den", „3 dny", „5 dní".
String daysLabel(int n) {
  if (isEnglish) return n == 1 ? '1 day' : '$n days';
  return '$n ${n == 1
      ? 'den'
      : (n >= 2 && n <= 4)
      ? 'dny'
      : 'dní'}';
}

/// „Zbývá 1 trénink", „Zbývají 3 tréninky", „Zbývá 5 tréninků".
String remainingWorkoutsLabel(int n) {
  if (isEnglish) return n == 1 ? '1 workout left' : '$n workouts left';
  return '${n >= 2 && n <= 4 ? 'Zbývají' : 'Zbývá'} ${workoutsLabel(n)}';
}

/// Odhad délky tréninku: rozcvička a ~2,5 min na sérii i s pauzou,
/// zaokrouhleno na 5 min.
int workoutMinutes(int sets) => ((5 + sets * 2.5) / 5).round() * 5;

/// Pozdrav podle denní doby. V noci pořád večer: „dobrou noc“ je loučení.
String greeting(DateTime now) => switch (now.hour) {
  >= 5 && < 9 => tr('Dobré ráno', 'Good morning'),
  >= 9 && < 12 => tr('Dobré dopoledne', 'Good morning'),
  >= 12 && < 18 => tr('Dobré odpoledne', 'Good afternoon'),
  _ => tr('Dobrý večer', 'Good evening'),
};

/// Pauza: „90 s“, „2 min“, „2 min 30 s“.
String restLabel(int seconds) {
  if (seconds < 60) return '$seconds s';
  final m = seconds ~/ 60, s = seconds % 60;
  return s == 0 ? '$m min' : '$m min $s s';
}

/// Display name for a muscle group storage key.
String muscleLabel(String key) => switch (key) {
  'Hrudník' => tr('Hrudník', 'Chest'),
  'Záda' => tr('Záda', 'Back'),
  'Nohy' => tr('Nohy', 'Legs'),
  'Ramena' => tr('Ramena', 'Shoulders'),
  'Paže' => tr('Paže', 'Arms'),
  'Střed těla' => tr('Střed těla', 'Core'),
  'Ostatní' => tr('Ostatní', 'Other'),
  _ => key,
};
