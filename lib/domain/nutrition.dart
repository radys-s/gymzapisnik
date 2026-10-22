/// Výživový deník: záznamy jídla a denní součty. Čistý Dart bez Flutteru.
///
/// Hodnota `null` = chybí (v zdroji nebyla), `0` = skutečná nula. Součty
/// proto jedno od druhého rozlišují a neukazují chybějící jako nulu.
library;

/// Energie a makroživiny. Vztahují se k [FoodBasis] záznamu.
class Nutrition {
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  const Nutrition({this.kcal, this.protein, this.carbs, this.fat});

  bool get isEmpty =>
      kcal == null && protein == null && carbs == null && fat == null;

  Nutrition scaled(double factor) => Nutrition(
    kcal: kcal == null ? null : kcal! * factor,
    protein: protein == null ? null : protein! * factor,
    carbs: carbs == null ? null : carbs! * factor,
    fat: fat == null ? null : fat! * factor,
  );

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
    kcal: _num(json['kcal']),
    protein: _num(json['protein']),
    carbs: _num(json['carbs']),
    fat: _num(json['fat']),
  );

  Map<String, dynamic> toJson() => {
    'kcal': ?kcal,
    'protein': ?protein,
    'carbs': ?carbs,
    'fat': ?fat,
  };
}

double? _num(Object? v) =>
    v is num && v.isFinite && v >= 0 ? v.toDouble() : null;

/// K čemu se hodnoty v záznamu vztahují.
enum FoodBasis {
  /// Na 100 g (nebo 100 ml); množství je v gramech/mililitrech.
  per100,

  /// Na jednu porci; množství je počet porcí.
  perServing,
}

/// Jednotka množství u hodnot na 100 g / 100 ml.
enum FoodUnit { g, ml }

/// Záznam jídla v deníku.
class FoodEntry {
  final String id;

  /// Den deníku, `yyyy-MM-dd` (místní).
  final String day;
  final DateTime loggedAt;
  final String name;
  final String? brand;
  final String? barcode;
  final FoodBasis basis;
  final FoodUnit unit;

  /// Gramy/mililitry ([FoodBasis.per100]) nebo počet porcí ([FoodBasis.perServing]).
  final double amount;

  /// Hodnoty vztažené k [basis]: na 100 g/ml, nebo na jednu porci.
  final Nutrition values;

  const FoodEntry({
    required this.id,
    required this.day,
    required this.loggedAt,
    required this.name,
    required this.basis,
    required this.amount,
    required this.values,
    this.unit = FoodUnit.g,
    this.brand,
    this.barcode,
  });

  /// Skutečně snědené hodnoty (hodnoty × množství); chybějící zůstanou `null`.
  Nutrition get eaten =>
      values.scaled(basis == FoodBasis.per100 ? amount / 100 : amount);

  FoodEntry copyWith({
    String? day,
    String? name,
    String? brand,
    String? barcode,
    FoodBasis? basis,
    FoodUnit? unit,
    double? amount,
    Nutrition? values,
  }) => FoodEntry(
    id: id,
    day: day ?? this.day,
    loggedAt: loggedAt,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    barcode: barcode ?? this.barcode,
    basis: basis ?? this.basis,
    unit: unit ?? this.unit,
    amount: amount ?? this.amount,
    values: values ?? this.values,
  );

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
    id: json['id'] as String,
    day: json['day'] as String,
    loggedAt:
        DateTime.tryParse(json['loggedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    name: json['name'] as String? ?? '',
    brand: json['brand'] as String?,
    barcode: json['barcode'] as String?,
    basis: json['basis'] == 'serving' ? FoodBasis.perServing : FoodBasis.per100,
    unit: json['unit'] == 'ml' ? FoodUnit.ml : FoodUnit.g,
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    values: Nutrition.fromJson(
      Map<String, dynamic>.from(json['values'] as Map? ?? const {}),
    ),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'day': day,
    'loggedAt': loggedAt.toUtc().toIso8601String(),
    'name': name,
    'brand': ?brand,
    'barcode': ?barcode,
    'basis': basis == FoodBasis.perServing ? 'serving' : 'per100',
    'unit': unit == FoodUnit.ml ? 'ml' : 'g',
    'amount': amount,
    'values': values.toJson(),
  };
}

/// Klíč dne deníku z data (místní den).
String dayKey(DateTime d) {
  final l = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${l.year.toString().padLeft(4, '0')}-${two(l.month)}-${two(l.day)}';
}

/// Zpět z klíče dne; `null` při neplatném formátu.
DateTime? parseDayKey(String key) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(key);
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  final date = DateTime(y, mo, d);
  return date.year == y && date.month == mo && date.day == d ? date : null;
}

/// Čas zápisu do dne [day]. Dnes je to [now]; u jiného dne datum toho dne
/// a čas z [timeOf] (třeba původního jídla), jinak z [now]. Podle času se
/// jídlo řadí do snídaně, oběda a dalších.
DateTime loggedAtFor(String day, DateTime now, {DateTime? timeOf}) {
  final d = parseDayKey(day);
  if (d == null || dayKey(now) == day) return now;
  final t = timeOf ?? now;
  return DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

/// Denní součet. U každé veličiny `*Missing` říká, že alespoň jednomu
/// záznamu hodnota chyběla, takže součet je spodní odhad.
class DayTotals {
  final double kcal, protein, carbs, fat;
  final bool kcalMissing, proteinMissing, carbsMissing, fatMissing;
  final int entries;
  const DayTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.kcalMissing,
    required this.proteinMissing,
    required this.carbsMissing,
    required this.fatMissing,
    required this.entries,
  });
}

DayTotals totalsOf(Iterable<FoodEntry> entries) {
  var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0;
  var kM = false, pM = false, cM = false, fM = false;
  var n = 0;
  for (final e in entries) {
    n++;
    final v = e.eaten;
    if (v.kcal == null) {
      kM = true;
    } else {
      kcal += v.kcal!;
    }
    if (v.protein == null) {
      pM = true;
    } else {
      p += v.protein!;
    }
    if (v.carbs == null) {
      cM = true;
    } else {
      c += v.carbs!;
    }
    if (v.fat == null) {
      fM = true;
    } else {
      f += v.fat!;
    }
  }
  return DayTotals(
    kcal: kcal,
    protein: p,
    carbs: c,
    fat: f,
    kcalMissing: kM,
    proteinMissing: pM,
    carbsMissing: cM,
    fatMissing: fM,
    entries: n,
  );
}

/// Výsledek kontroly formuláře: chybová zpráva, nebo `null` při platných datech.
String? validateFood({
  required String name,
  required double? amount,
  required FoodBasis basis,
  required Nutrition values,
}) {
  if (name.trim().isEmpty) return 'Zadej název jídla.';
  if (name.trim().length > 120) return 'Název je příliš dlouhý.';
  if (amount == null || amount <= 0) return 'Zadej množství větší než nula.';
  if (amount > (basis == FoodBasis.per100 ? 10000 : 1000)) {
    return 'Množství vypadá jako překlep.';
  }
  if (values.isEmpty) {
    return 'Vyplň alespoň jednu hodnotu (energii nebo makro).';
  }
  final macroMax = basis == FoodBasis.per100 ? 100.0 : 1000.0;
  if ((values.kcal ?? 0) > 10000) return 'Energie vypadá jako překlep.';
  for (final m in [values.protein, values.carbs, values.fat]) {
    if ((m ?? 0) > macroMax) return 'Makroživiny vypadají jako překlep.';
  }
  if (basis == FoodBasis.per100 &&
      (values.protein ?? 0) + (values.carbs ?? 0) + (values.fat ?? 0) > 100.5) {
    return 'Na 100 g nemůže být víc než 100 g živin dohromady.';
  }
  return null;
}

/// Platný čárový kód EAN-8, UPC-A (12), EAN-13 nebo GTIN-14 (kontrolní číslice).
bool validBarcode(String code) {
  if (!RegExp(r'^\d+$').hasMatch(code)) return false;
  if (![8, 12, 13, 14].contains(code.length)) return false;
  final digits = [for (final r in code.runes) r - 48];
  var sum = 0;
  for (var i = 0; i < digits.length - 1; i++) {
    final fromRight = digits.length - 2 - i;
    sum += digits[i] * (fromRight.isEven ? 3 : 1);
  }
  return (10 - sum % 10) % 10 == digits.last;
}
