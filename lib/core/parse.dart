/// Číslo z uživatelského vstupu; přijímá desetinnou čárku i tečku.
/// Mezery (i nezlomitelné z vloženého textu) se ignorují.
double? parseNum(String input) {
  final text = input.replaceAll(RegExp(r'\s'), '').replaceAll(',', '.');
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  return value != null && value.isFinite ? value : null;
}
