import 'package:flutter/material.dart';

/// Barevný motiv, který si uživatel vybere při prvním spuštění.
enum Accent {
  lime('Limetka', 'Zeleno-žlutá'),
  lagoon('Laguna', 'Zeleno-modrá'),
  sunset('Západ', 'Oranžovo-žlutá');

  final String label;
  final String description;
  const Accent(this.label, this.description);

  static Accent parse(Object? value) => Accent.values.firstWhere(
    (a) => a.name == value,
    orElse: () => Accent.lime,
  );

  /// Gradient pro hlavní tlačítko, kruh postupu a úvodní kartu.
  List<Color> gradient(Brightness b) => switch (this) {
    Accent.lime =>
      b == Brightness.dark
          ? const [Color(0xFFD4F76B), Color(0xFF5BE37D)]
          : const [Color(0xFFB9EA4E), Color(0xFF34C759)],
    Accent.lagoon =>
      b == Brightness.dark
          ? const [Color(0xFF5BE37D), Color(0xFF3CC8D8)]
          : const [Color(0xFF34C759), Color(0xFF1FB3C4)],
    Accent.sunset =>
      b == Brightness.dark
          ? const [Color(0xFFFF8A3D), Color(0xFFFFD23F)]
          : const [Color(0xFFFF7A1A), Color(0xFFFFC21A)],
  };

  /// Plná barva pro text, ikony a přepínače. Ve světlém režimu tmavší,
  /// aby měl text na bílém pozadí dost kontrastu.
  Color solid(Brightness b) => switch (this) {
    Accent.lime =>
      b == Brightness.dark ? const Color(0xFFB8F05A) : const Color(0xFF2E8B1E),
    Accent.lagoon =>
      b == Brightness.dark ? const Color(0xFF4CD9C0) : const Color(0xFF0E8A7E),
    Accent.sunset =>
      b == Brightness.dark ? const Color(0xFFFFA43A) : const Color(0xFFC85A00),
  };
}

/// Systémové barvy ve stylu iOS. Dostupné přes `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color grouped;
  final Color elevated;
  final Color separator;
  final Color label;
  final Color secondaryLabel;
  final Color tertiaryLabel;
  final Color fill;
  final Color accent;
  final Color onAccent;
  final List<Color> gradient;
  final Color positive;
  final Color negative;

  const AppPalette({
    required this.background,
    required this.grouped,
    required this.elevated,
    required this.separator,
    required this.label,
    required this.secondaryLabel,
    required this.tertiaryLabel,
    required this.fill,
    required this.accent,
    required this.onAccent,
    required this.gradient,
    required this.positive,
    required this.negative,
  });

  factory AppPalette.of(Brightness b, Accent accent) {
    final dark = b == Brightness.dark;
    return AppPalette(
      background: dark ? Colors.black : const Color(0xFFF2F2F7),
      grouped: dark ? const Color(0xFF1C1C1E) : Colors.white,
      elevated: dark ? const Color(0xFF2C2C2E) : Colors.white,
      separator: dark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
      label: dark ? Colors.white : Colors.black,
      secondaryLabel: dark ? const Color(0xFF98989F) : const Color(0xFF6C6C70),
      tertiaryLabel: dark ? const Color(0xFF5C5C61) : const Color(0xFFAEAEB2),
      fill: dark ? const Color(0xFF2C2C2E) : const Color(0xFFE9E9EE),
      accent: accent.solid(b),
      onAccent: Colors.black,
      gradient: accent.gradient(b),
      positive: dark ? const Color(0xFF30D158) : const Color(0xFF248A3D),
      negative: dark ? const Color(0xFFFF453A) : const Color(0xFFD70015),
    );
  }

  LinearGradient get linear => LinearGradient(
    colors: gradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      grouped: c(grouped, other.grouped),
      elevated: c(elevated, other.elevated),
      separator: c(separator, other.separator),
      label: c(label, other.label),
      secondaryLabel: c(secondaryLabel, other.secondaryLabel),
      tertiaryLabel: c(tertiaryLabel, other.tertiaryLabel),
      fill: c(fill, other.fill),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      gradient: [
        for (var i = 0; i < gradient.length; i++)
          c(gradient[i], other.gradient[i]),
      ],
      positive: c(positive, other.positive),
      negative: c(negative, other.negative),
    );
  }
}

/// Mezery a zaoblení – jinde se nepoužívají jiné hodnoty.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Okraj obsahu od kraje obrazovky.
  static const page = 16.0;
}

abstract final class Radii {
  static const control = 12.0;
  static const card = 16.0;
  static const hero = 22.0;
  static const sheet = 20.0;
}

/// Nejmenší dotyková plocha (Apple HIG).
const minTap = 44.0;

/// Čísla se stejnou šířkou číslic, aby hodnoty neposkakovaly.
const tabular = [FontFeature.tabularFigures()];

extension PaletteX on BuildContext {
  /// Paleta z motivu; bez ní (např. cizí MaterialApp v testu) výchozí.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        AppPalette.of(theme.brightness, Accent.lime);
  }
}
