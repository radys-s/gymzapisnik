/// Váha bez zbytečných nul a s desetinnou čárkou: 80 → "80", 77.5 → "77,5".
String formatKg(double kg) {
  final text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
}

/// Objem v celých kg s mezerou mezi tisíci („12 450"), jako v češtině.
/// Mezera je nezlomitelná, aby se číslo nerozdělilo na dva řádky.
String formatVolume(double kg) {
  final digits = kg.round().abs().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(' ');
    grouped.write(digits[i]);
  }
  return kg.round() < 0 ? '-$grouped' : grouped.toString();
}

String _two(int v) => v.toString().padLeft(2, '0');

String formatDate(DateTime d) {
  final local = d.toLocal();
  return '${local.day}. ${local.month}. ${local.year}';
}

String formatTime(DateTime d) {
  final local = d.toLocal();
  return '${local.hour}:${_two(local.minute)}';
}

String formatDateTime(DateTime d) => '${formatDate(d)} ${formatTime(d)}';

/// Počet kalendářních dnů mezi dny [from] a [to] v místním čase.
/// Počítá se v UTC, takže změna letního času (den o 23 nebo 25 hodinách)
/// výsledek neposune.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = from.toLocal();
  final b = to.toLocal();
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

const _weekdayNames = [
  'Pondělí',
  'Úterý',
  'Středa',
  'Čtvrtek',
  'Pátek',
  'Sobota',
  'Neděle',
];

/// „Dnes", „Včera", den v týdnu do týdne zpět, jinak datum.
String relativeDay(DateTime d, DateTime now) {
  final diff = calendarDaysBetween(d, now);
  if (diff == 0) return 'Dnes';
  if (diff == 1) return 'Včera';
  if (diff > 1 && diff < 7) return _weekdayNames[d.toLocal().weekday - 1];
  return formatDate(d);
}
