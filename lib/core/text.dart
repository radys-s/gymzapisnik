const _from = 'áčďéěíňóřšťúůýžÁČĎÉĚÍŇÓŘŠŤÚŮÝŽ';
const _to = 'acdeeinorstuuyzACDEEINORSTUUYZ';

/// Text pro vyhledávání: malá písmena bez diakritiky.
String fold(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final index = _from.indexOf(char);
    buffer.write(index < 0 ? char : _to[index]);
  }
  return buffer.toString().toLowerCase();
}
