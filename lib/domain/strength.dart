/// Úroveň síly podle odhadu 1RM vůči tělesné váze. Čistý Dart.
///
/// Hranice jsou násobky tělesné váhy, orientačně podle běžně
/// používaných silových tabulek pro dospělé. Slouží k motivaci, ne
/// k soutěžnímu hodnocení.
library;

/// Tabulka, se kterou se porovnává.
enum StrengthStandard {
  men('Muži'),
  women('Ženy');

  final String label;
  const StrengthStandard(this.label);

  static StrengthStandard? parse(Object? v) =>
      values.where((s) => s.name == v).firstOrNull;
}

/// Názvy úrovní; první hranice z tabulky otevírá „Začátečník“.
const strengthLevels = [
  'Začínáš',
  'Začátečník',
  'Mírně pokročilý',
  'Pokročilý',
  'Velmi pokročilý',
  'Elita',
];

/// Hranice (násobky tělesné váhy) pro úrovně 1–5.
const _men = {
  'squat': [0.75, 1.0, 1.5, 2.0, 2.5],
  'bench_press': [0.5, 0.75, 1.0, 1.5, 2.0],
  'deadlift': [1.0, 1.25, 1.75, 2.5, 3.0],
  'overhead_press': [0.35, 0.55, 0.75, 1.0, 1.35],
};
const _women = {
  'squat': [0.5, 0.75, 1.0, 1.5, 2.0],
  'bench_press': [0.25, 0.5, 0.75, 1.0, 1.5],
  'deadlift': [0.5, 1.0, 1.25, 1.75, 2.5],
  'overhead_press': [0.2, 0.35, 0.5, 0.75, 1.0],
};

/// Má cvik tabulku úrovní?
bool hasStrengthStandard(String exerciseId) => _men.containsKey(exerciseId);

/// Výsledek porovnání.
class StrengthLevel {
  /// Index do [strengthLevels] (0–5).
  final int level;

  /// Odhad 1RM / tělesná váha.
  final double ratio;

  /// Kolik kg 1RM chybí do další úrovně (`null` na nejvyšší).
  final double? toNext;

  /// Postup od aktuální hranice k další (0–1; na nejvyšší 1).
  final double progress;

  const StrengthLevel({
    required this.level,
    required this.ratio,
    required this.toNext,
    required this.progress,
  });

  String get label => strengthLevels[level];
  String? get nextLabel =>
      level + 1 < strengthLevels.length ? strengthLevels[level + 1] : null;
}

/// Úroveň pro odhad 1RM [oneRm] při tělesné váze [bodyweight];
/// `null`, když cvik tabulku nemá nebo chybí data.
StrengthLevel? strengthLevel(
  String exerciseId,
  double oneRm,
  double bodyweight,
  StrengthStandard standard,
) {
  final table = (standard == StrengthStandard.men ? _men : _women)[exerciseId];
  if (table == null || oneRm <= 0 || bodyweight <= 0) return null;
  final ratio = oneRm / bodyweight;
  var level = 0;
  while (level < table.length && ratio >= table[level]) {
    level++;
  }
  if (level == table.length) {
    return StrengthLevel(level: level, ratio: ratio, toNext: null, progress: 1);
  }
  final from = level == 0 ? 0.0 : table[level - 1];
  final to = table[level];
  return StrengthLevel(
    level: level,
    ratio: ratio,
    toNext: (to * bodyweight - oneRm).clamp(0, double.infinity).toDouble(),
    progress: ((ratio - from) / (to - from)).clamp(0, 1).toDouble(),
  );
}
