import 'package:flutter/material.dart';

/// Shared dark colors and surfaces, available through `context.palette`.
///
/// One accent (ember) marks actions; green marks completed sets; gold marks
/// records. Everything else is neutral.
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

  /// Jediná paleta aplikace: neutrální skoro černá, jeden akcent (žár),
  /// zelená jen pro hotové série, zlatá jen pro rekordy.
  static const gym = AppPalette(
    background: Color(0xFF0A0A0B),
    grouped: Color(0xFF151517),
    elevated: Color(0xFF1E1E21),
    separator: Color(0xFF2A2A2E),
    label: Color(0xFFF5F5F4),
    secondaryLabel: Color(0xFFA1A1A8),
    tertiaryLabel: Color(0xFF6B6B73),
    fill: Color(0xFF242428),
    accent: ember,
    onAccent: ink,
    gradient: training,
    onGradient: ink,
    cta: ember,
    onCta: ink,
    positive: done,
    negative: Color(0xFFFF5A5F),
  );

  /// Light neutral surface used by inverse Material components.
  static const gymGrey = Color(0xFFEDEDEC);

  /// Text on the accent.
  static const ink = Color(0xFF0A0A0B);

  /// Brand accent: actions, selection, current state.
  static const ember = Color(0xFFFF6B2C);

  /// Completed sets and positive change. Never used for actions.
  static const done = Color(0xFF3DD68C);

  /// Data colors for charts and muscle groups; never for actions.
  static const green = done;
  static const lime = Color(0xFFB4E44D);
  static const teal = Color(0xFF2EC4B6);
  static const cyan = Color(0xFF4CC9F0);
  static const blue = Color(0xFF5B8CFF);
  static const violet = Color(0xFF9D8CFF);
  static const pink = Color(0xFFF472B6);
  static const orange = ember;
  static const amber = Color(0xFFFFC53D);
  static const yellow = Color(0xFFFDE68A);

  /// Section "gradients" are flat now: one accent everywhere.
  static const training = [ember, ember];
  static const food = [ember, ember];
  static const progress = [ember, ember];
  static const coach = [ember, ember];

  /// Superset colors A, B, C, D (then repeat).
  static const superset = [cyan, amber, pink, violet];

  /// Zlatá pro rekordy a odznaky.
  Color get gold => amber;

  /// Card corner radius.
  BorderRadius cardRadius() => BorderRadius.circular(Radii.card);

  /// Flat card, no outline: surfaces separate by tone.
  ShapeBorder cardShape() =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card));

  /// Zaoblení tlačítek a polí.
  double get controlRadius => Radii.control;

  LinearGradient get linear => LinearGradient(colors: [accent, accent]);

  /// Card fill. Flat; kept as a gradient so callers need no change.
  LinearGradient surface([Tone? tone]) =>
      LinearGradient(colors: [grouped, grouped]);

  /// No shadows: depth comes from surface tone.
  List<BoxShadow> get cardShadow => const [];

  /// No glows.
  List<BoxShadow> glow(Color color, [double t = 1]) => const [];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) => this;
}

/// Color family of an app section, so each area has its own accent.
enum Tone {
  training(AppPalette.ember, AppPalette.training),
  food(AppPalette.ember, AppPalette.food),
  progress(AppPalette.ember, AppPalette.progress),
  coach(AppPalette.ember, AppPalette.coach);

  final Color color;
  final List<Color> colors;
  const Tone(this.color, this.colors);

  LinearGradient get gradient => LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// The section a subtree belongs to. Pages set it once; icons, rings and
/// charts below read it, so a section keeps one color family without
/// every widget being told.
class ToneScope extends InheritedWidget {
  final Tone tone;
  const ToneScope({super.key, required this.tone, required super.child});

  /// The section tone here; training (the brand green) outside any page.
  static Tone of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToneScope>()?.tone ??
      Tone.training;

  @override
  bool updateShouldNotify(ToneScope old) => old.tone != tone;
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
  static const control = 12.0;
  static const card = 16.0;
  static const hero = 20.0;
  static const sheet = 20.0;
}

/// Nejmenší dotyková plocha (Apple HIG).
const minTap = 44.0;

/// Condensed type reserved for big figures (timers, totals, records).
const condensedFont = 'Barlow Condensed';

/// Text face for everything else.
const textFont = 'Inter';

/// Čísla se stejnou šířkou číslic, aby hodnoty neposkakovaly.
const tabular = [FontFeature.tabularFigures()];

extension PaletteX on BuildContext {
  /// Paleta z motivu; bez ní (např. cizí MaterialApp v testu) výchozí.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ?? AppPalette.gym;
  }
}
