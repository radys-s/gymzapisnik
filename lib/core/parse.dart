/// Číslo z uživatelského vstupu; přijímá desetinnou čárku i tečku.
double? parseNum(String input) {
  final text = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (text.isEmpty) return null;
  final value = double.tryParse(text);
  return value != null && value.isFinite ? value : null;
}
