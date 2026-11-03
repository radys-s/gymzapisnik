import 'package:flutter/material.dart';

/// Barvy aplikace: jeden vzhled, vždy tmavý. Dostupné přes
/// `context.palette`.
///
/// Šedá nese text a čísla (nejlepší kontrast s černou), zelená znamená
/// akci a hotovo, přechody odliší trénink (zelená → žlutá) od jídla
/// (zelená → azurová).
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
    background: Colors.black,
    grouped: Color(0xFF121214),
    elevated: Color(0xFF1A1A1D),
    separator: Color(0xFF26262A),
    label: gymGrey,
    secondaryLabel: Color(0xFF9A9AA2),
    tertiaryLabel: Color(0xFF80808A),
    fill: Color(0xFF1C1C1F),
    accent: green,
    onAccent: Colors.black,
    gradient: training,
    onGradient: Colors.black,
    cta: green,
    onCta: Colors.black,
    positive: green,
    negative: Color(0xFFFF5A4E),
  );

  /// Světle šedá: text, čísla sérií, vedlejší tlačítka.
  static const gymGrey = Color(0xFFE4E4E7);

  /// Hlavní zelená (NVIDIA): akce, hotovo, vybraná záložka.
  static const green = Color(0xFF76B900);
  static const yellow = Color(0xFFE6E600);
  static const cyan = Color(0xFF2AD1FF);

  /// Přechod tréninku a přechod jídla (kruhy ve Stravě).
  static const training = [green, Color(0xFFB0D400), yellow];
  static const food = [green, Color(0xFF3FC9A0), cyan];

  /// Staré názvy, které ještě používají grafy.

  /// Žlutá pro rekordy a odznaky.
  Color get gold => yellow;

  /// Zaoblení karty: skoro ostré rohy.
  BorderRadius cardRadius() => BorderRadius.circular(2);

  /// Tvar karty: zkosený pravý horní roh a tenká linka.
  ShapeBorder cardShape() => BeveledRectangleBorder(
    borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
    side: BorderSide(color: separator),
  );

  /// Zaoblení tlačítek a polí.
  double get controlRadius => 2;

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

/// Rovnoběžník se sklonem jako závodní grafika: hlavní tlačítka.
/// Hrany jsou skloněné o [slant] výšky (asi 12°).
class SkewBorder extends OutlinedBorder {
  final double slant;
  const SkewBorder({super.side, this.slant = 0.21});

  Path _path(Rect r) {
    final dx = r.height * slant;
    return Path()
      ..moveTo(r.left + dx, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right - dx, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  SkewBorder scale(double t) => SkewBorder(side: side.scale(t), slant: slant);

  @override
  SkewBorder copyWith({BorderSide? side}) =>
      SkewBorder(side: side ?? this.side, slant: slant);

  @override
  bool operator ==(Object other) =>
      other is SkewBorder && other.side == side && other.slant == slant;

  @override
  int get hashCode => Object.hash(side, slant);
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
  static const control = 14.0;
  static const card = 20.0;
  static const hero = 28.0;
  static const sheet = 24.0;
}

/// Nejmenší dotyková plocha (Apple HIG).
const minTap = 44.0;

/// Úzké tučné písmo Tensoru pro nadpisy, štítky a čísla.
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
