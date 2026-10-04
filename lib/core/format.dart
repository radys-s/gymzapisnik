/// Váha bez zbytečných nul a s desetinnou čárkou: 80 → "80", 77.5 → "77,5".
String formatKg(double kg) {
  final text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  return text.replaceAll('.', ',');
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
