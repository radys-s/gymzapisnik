/// Záznam tělesné váhy. Čistý Dart bez Flutteru.
class BodyWeight {
  final String id;
  final DateTime date;
  final double kg;

  const BodyWeight({required this.id, required this.date, required this.kg});

  factory BodyWeight.fromJson(Map<String, dynamic> json) => BodyWeight(
    id: json['id'] as String,
    date:
        DateTime.tryParse(json['date'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    kg: (json['kg'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toUtc().toIso8601String(),
    'kg': kg,
  };
}

/// Rozumná tělesná váha v kg (chrání před překlepem).
bool validBodyWeight(double kg) => kg >= 20 && kg <= 400;

/// Změna proti záznamu nejblíž [days] dní před posledním; `null`, když
/// není s čím porovnat (jen jeden záznam nebo žádný starší).
double? changeOver(List<BodyWeight> newestFirst, {int days = 30}) {
  if (newestFirst.length < 2) return null;
  final latest = newestFirst.first;
  final from = latest.date.subtract(Duration(days: days));
  BodyWeight? base;
  for (final w in newestFirst.skip(1)) {
    if (!w.date.isAfter(from)) {
      base = w;
      break;
    }
    base = w; // nejstarší v okně, když nic staršího není
  }
  if (base == null) return null;
  return double.parse((latest.kg - base.kg).toStringAsFixed(1));
}
