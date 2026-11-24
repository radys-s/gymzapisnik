/// Část těla, kterou měříme krejčovským metrem. Čistý Dart bez Flutteru.
library;

import '../core/i18n.dart';

enum BodyPart {
  waist,
  chest,
  arm,
  forearm,
  thigh,
  calf,
  hips,
  neck;

  String get label => switch (this) {
    waist => tr('Pas', 'Waist'),
    chest => tr('Hrudník', 'Chest'),
    arm => tr('Paže', 'Arm'),
    forearm => tr('Předloktí', 'Forearm'),
    thigh => tr('Stehno', 'Thigh'),
    calf => tr('Lýtko', 'Calf'),
    hips => tr('Boky', 'Hips'),
    neck => tr('Krk', 'Neck'),
  };

  /// Czech name as stored by older versions, independent of the UI language.
  String get storedLabel => switch (this) {
    waist => 'Pas',
    chest => 'Hrudník',
    arm => 'Paže',
    forearm => 'Předloktí',
    thigh => 'Stehno',
    calf => 'Lýtko',
    hips => 'Boky',
    neck => 'Krk',
  };

  /// Načte část těla z uložené hodnoty; neznámou vrátí `null`.
  static BodyPart? parse(Object? v) {
    if (v is BodyPart) return v;
    if (v is! String) return null;
    for (final part in values) {
      if (part.name == v || part.storedLabel == v) return part;
    }
    return null;
  }
}

/// Záznam obvodu části těla v cm. Čistý Dart bez Flutteru.
class Measurement {
  final String id;
  final DateTime date;
  final BodyPart part;
  final double cm;

  const Measurement({
    required this.id,
    required this.date,
    required this.part,
    required this.cm,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) {
    final part = BodyPart.parse(json['part']);
    if (part == null) {
      throw FormatException(tr('Neznámá část těla.', 'Unknown body part.'));
    }
    return Measurement(
      id: json['id'] as String,
      date:
          DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      part: part,
      cm: (json['cm'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toUtc().toIso8601String(),
    'part': part.name,
    'cm': cm,
  };
}

/// Rozumný obvod v cm (chrání před překlepem).
bool validMeasurement(double cm) => cm >= 10 && cm <= 250;

/// Změna obvodu dané části proti záznamu nejblíž [days] dní před posledním;
/// `null`, když není s čím porovnat.
double? measurementChange(
  List<Measurement> newestFirst,
  BodyPart part, {
  int days = 30,
}) {
  final entries = [
    for (final m in newestFirst)
      if (m.part == part) m,
  ];
  if (entries.length < 2) return null;
  final latest = entries.first;
  final from = latest.date.subtract(Duration(days: days));
  Measurement? base;
  for (final m in entries.skip(1)) {
    if (!m.date.isAfter(from)) {
      base = m;
      break;
    }
    base = m; // nejstarší v okně, když nic staršího není
  }
  if (base == null) return null;
  return double.parse((latest.cm - base.cm).toStringAsFixed(1));
}
