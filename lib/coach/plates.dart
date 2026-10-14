/// Kotouče na činku a rozcvičovací série. Čistý Dart.
library;

/// Běžné kotouče v posilovně (kg), od největšího.
const standardPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];

/// Běžné osy: olympijská, ženská/technická, EZ.
const barWeights = [20.0, 15.0, 10.0];

class PlateLoad {
  /// Kotouče na jednu stranu, od největšího.
  final List<double> perSide;

  /// Kolik chybí do zadané váhy (nedá se složit z kotoučů).
  final double missing;
  const PlateLoad(this.perSide, this.missing);

  double get loaded => perSide.fold(0.0, (a, b) => a + b);
}

/// Kotouče na každou stranu osy, aby dohromady dávaly [total].
PlateLoad platesFor(
  double total, {
  double bar = 20,
  List<double> plates = standardPlates,
}) {
  if (!total.isFinite || total <= bar) {
    return PlateLoad(const [], total > bar ? total - bar : 0);
  }
  // V setinách kg, ať 1,25 nesčítá zaokrouhlovací chyby.
  var side = ((total - bar) * 50).round(); // = půlka v setinách
  final result = <double>[];
  for (final p in plates) {
    final c = (p * 100).round();
    while (side >= c) {
      result.add(p);
      side -= c;
    }
  }
  return PlateLoad(result, side * 2 / 100);
}

/// Rozcvičovací série před pracovní vahou [working]: 40 % × 10, 60 % × 5,
/// 80 % × 3, zaokrouhleno dolů na 2,5 kg. Lehké váhy se nerozcvičují.
List<({double weight, int reps})> warmupPlan(double working) {
  if (!working.isFinite || working < 20) return const [];
  final result = <({double weight, int reps})>[];
  for (final (share, reps) in const [(0.4, 10), (0.6, 5), (0.8, 3)]) {
    final w = (working * share / 2.5).floor() * 2.5;
    if (w < 2.5 || w >= working) continue;
    if (result.isNotEmpty && result.last.weight == w) continue;
    result.add((weight: w, reps: reps));
  }
  return result;
}
