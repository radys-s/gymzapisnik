import 'package:flutter/material.dart';

/// Shared dark colors and surfaces, available through `context.palette`.
///
/// Green marks key actions, with separate gradients for workouts and food.
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

  /// Barva odkazů, ikon a vybraných prvků.
  final Color accent;
  final Color onAccent;

  /// Přechod tréninku: hotové série, postup, rekordy.
  final List<Color> gradient;
  final Color onGradient;

  /// Hlavní tlačítko.
  final Color cta;
  final Color onCta;
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
    required this.onGradient,
    required this.cta,
    required this.onCta,
    required this.positive,
    required this.negative,
  });

  /// Jediná paleta aplikace.
  static const gym = AppPalette(
    background: Color(0xFF0C1110),
    grouped: Color(0xFF141C19),
    elevated: Color(0xFF1B2521),
    separator: Color(0xFF293832),
    label: Color(0xFFF1F5F2),
    secondaryLabel: Color(0xFFB0BDB6),
    tertiaryLabel: Color(0xFF7E8D84),
    fill: Color(0xFF202B26),
    accent: green,
    onAccent: Colors.black,
    gradient: training,
    onGradient: Colors.black,
    cta: green,
    onCta: Colors.black,
    positive: green,
    negative: Color(0xFFFF5A4E),
  );

  /// Light neutral surface used by inverse Material components.
  static const gymGrey = Color(0xFFE4E4E7);

  /// Hlavní zelená: akce, hotovo, vybraná záložka.
  static const green = Color(0xFF9BE15D);
  static const yellow = Color(0xFFD5EBA4);
  static const cyan = Color(0xFF71D7C2);

  /// Workout and food progress gradients.
  static const training = [green, Color(0xFFB7E780), yellow];
  static const food = [green, Color(0xFF7FD4A9), cyan];

  /// Superset colors A, B, C, D (then repeat).
  static const superset = [cyan, yellow, Color(0xFFFF9F43), Color(0xFFC08BFF)];

  /// Staré názvy, které ještě používají grafy.

  /// Žlutá pro rekordy a odznaky.
  Color get gold => yellow;

  /// Card corner radius.
  BorderRadius cardRadius() => BorderRadius.circular(20);

  /// Rounded card with a subtle outline.
  ShapeBorder cardShape() => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(color: separator),
  );

  /// Zaoblení tlačítek a polí.
  double get controlRadius => 14;

  LinearGradient get linear => LinearGradient(
    colors: gradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => this;
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

  /// Keep mobile-first pages readable when the web app has a wide viewport.
  static const contentMax = 760.0;
}

abstract final class Radii {
  static const control = 14.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const sheet = 24.0;
}

/// Nejmenší dotyková plocha (Apple HIG).
const minTap = 44.0;

/// Condensed type reserved for decorative figures and compact labels.
const condensedFont = 'Barlow Condensed';

/// Čísla se stejnou šířkou číslic, aby hodnoty neposkakovaly.
const tabular = [FontFeature.tabularFigures()];

extension PaletteX on BuildContext {
  /// Paleta z motivu; bez ní (např. cizí MaterialApp v testu) výchozí.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ?? AppPalette.gym;
  }
}
