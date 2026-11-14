import 'package:flutter/material.dart';

/// Shared dark colors and surfaces, available through `context.palette`.
///
/// Green marks key actions; each section adds its own accent and gradient.
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

  /// Jediná paleta aplikace: tmavý inkoust s barevnými akcenty.
  static const gym = AppPalette(
    background: Color(0xFF0B0C14),
    grouped: Color(0xFF141624),
    elevated: Color(0xFF1C1F31),
    separator: Color(0xFF2A2E45),
    label: Color(0xFFF4F5FA),
    secondaryLabel: Color(0xFFB6BBCE),
    tertiaryLabel: Color(0xFF8188A0),
    fill: Color(0xFF212438),
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
  static const lime = Color(0xFFB9F56A);
  static const teal = Color(0xFF4FE0C0);
  static const cyan = Color(0xFF4FD8E8);
  static const blue = Color(0xFF5AA9FF);
  static const violet = Color(0xFF8B7CFF);
  static const pink = Color(0xFFFF6FA5);
  static const orange = Color(0xFFFF8A5B);
  static const amber = Color(0xFFFFC857);
  static const yellow = Color(0xFFFFE08A);

  /// Workout, food, progress, and coach gradients.
  static const training = [lime, Color(0xFF8BEA7A), teal];
  static const food = [amber, orange, pink];
  static const progress = [violet, blue, cyan];
  static const coach = [pink, Color(0xFFC07CFF), violet];

  /// Superset colors A, B, C, D (then repeat).
  static const superset = [cyan, amber, orange, violet];

  /// Zlatá pro rekordy a odznaky.
  Color get gold => amber;

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

  /// Soft drop shadow that lifts a card off the page.
  List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x59000000),
      blurRadius: 24,
      spreadRadius: -10,
      offset: Offset(0, 12),
    ),
  ];

  /// Colored glow under a raised or selected element; [t] fades it in.
  List<BoxShadow> glow(Color color, [double t = 1]) => [
    BoxShadow(
      color: color.withValues(alpha: 0.34 * t),
      blurRadius: 24,
      spreadRadius: -8,
      offset: Offset(0, 10 * t),
    ),
  ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => this;
}

/// Color family of an app section, so each area has its own accent.
enum Tone {
  training(AppPalette.green, AppPalette.training),
  food(AppPalette.orange, AppPalette.food),
  progress(AppPalette.violet, AppPalette.progress),
  coach(AppPalette.pink, AppPalette.coach);

  final Color color;
  final List<Color> colors;
  const Tone(this.color, this.colors);

  LinearGradient get gradient => LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
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
