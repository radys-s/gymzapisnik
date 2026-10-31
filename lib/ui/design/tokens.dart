import 'package:flutter/material.dart';

/// Vzhled aplikace. `auto` = ve světlém režimu Aurora, v tmavém Studio.
/// `tensor` vyhrál finále testerů (3 ze 4 hlasů) a je výchozí: vždy
/// tmavý, NVIDIA zelená, data a telemetrie. `pitwall` (Závod) zůstává.
enum Look {
  tensor('Tensor', 'Vždy tmavý: data a telemetrie, zelená na černé'),
  pitwall('Závod', 'Vždy tmavý: závodní červená, telemetrie, velká čísla'),
  auto('Automaticky', 'Ve dne Aurora, v noci Studio'),
  aurora('Aurora', 'Světlé plochy a barevná hlavní karta'),
  studio('Studio', 'Kontrastní černobílý, barva jen na akcích');

  final String label;
  final String description;
  const Look(this.label, this.description);

  static Look parse(Object? value) =>
      Look.values.firstWhere((l) => l.name == value, orElse: () => Look.tensor);

  /// Vlastní pevná paleta a jen tmavý režim: barva motivu ani volba
  /// světlý / tmavý na něj nepůsobí.
  bool get fixed => this == Look.tensor || this == Look.pitwall;

  /// Konkrétní vzhled pro světlý nebo tmavý režim.
  Look resolve(Brightness b) => this == Look.auto
      ? (b == Brightness.dark ? Look.studio : Look.aurora)
      : this;
}

/// Podklad, na kterém leží obsah výrazné karty.
enum HeroSurface {
  /// Světlý barevný přechod (Aurora ve dne): tmavý text.
  bright,

  /// Tmavá karta s barevnou září (Studio a tmavý režim): bílý text.
  glow,
}

/// Barevný motiv, který si uživatel vybere při prvním spuštění.
enum Accent {
  lime('Limetka', 'Zeleno-žlutá'),
  lagoon('Laguna', 'Zeleno-modrá'),
  sunset('Západ', 'Oranžovo-žlutá'),
  neon('Neon', 'Oranžovo-růžovo-fialová');

  final String label;
  final String description;
  const Accent(this.label, this.description);

  static Accent parse(Object? value) => Accent.values.firstWhere(
    (a) => a.name == value,
    orElse: () => Accent.lime,
  );

  /// Přechod o třech barvách: tlačítka, kruhy a výrazné karty.
  /// Prostřední barva drží plynulý přechod bez šedého středu.
  List<Color> gradient(Brightness b) => switch (this) {
    Accent.lime =>
      b == Brightness.dark
          ? const [Color(0xFFD4F76B), Color(0xFF8FEC6E), Color(0xFF4FDD86)]
          : const [Color(0xFFC6F432), Color(0xFF6EDB5A), Color(0xFF2FC46A)],
    Accent.lagoon =>
      b == Brightness.dark
          ? const [Color(0xFF6BE88A), Color(0xFF44D8B0), Color(0xFF3CC3E0)]
          : const [Color(0xFF34C759), Color(0xFF1FBF9B), Color(0xFF14A9D0)],
    Accent.sunset =>
      b == Brightness.dark
          ? const [Color(0xFFFF8A3D), Color(0xFFFFAE3E), Color(0xFFFFD84A)]
          : const [Color(0xFFFF6A1A), Color(0xFFFF971C), Color(0xFFFFC21A)],
    // Tmavší tóny: bílý text musí být čitelný na celém přechodu.
    Accent.neon => const [
      Color(0xFFC2410C),
      Color(0xFFA21CAF),
      Color(0xFF6D28D9),
    ],
  };

  /// Barva textu a ikon na přechodu.
  Color get onGradient => this == Accent.neon ? Colors.white : Colors.black;

  /// Plná barva pro text, ikony a přepínače. Ve světlém režimu tmavší,
  /// aby měl text na bílém pozadí dost kontrastu.
  Color solid(Brightness b) => switch (this) {
    Accent.lime =>
      b == Brightness.dark ? const Color(0xFFB8F05A) : const Color(0xFF267A18),
    Accent.lagoon =>
      b == Brightness.dark ? const Color(0xFF4CD9C0) : const Color(0xFF0B7A70),
    Accent.sunset =>
      b == Brightness.dark ? const Color(0xFFFFA43A) : const Color(0xFFB04E00),
    Accent.neon =>
      b == Brightness.dark ? const Color(0xFFFF6FAE) : const Color(0xFFC2185B),
  };
}

/// Barvy aplikace podle režimu, vzhledu a motivu. Dostupné přes
/// `context.palette`.
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

  /// Barva odkazů, ikon a vybraných prvků (ve Studiu černá / bílá).
  final Color accent;
  final Color onAccent;
  final List<Color> gradient;
  final Color onGradient;

  /// Hlavní tlačítko: plná barva, nebo `null` = přechod motivu.
  final Color? cta;
  final Color onCta;
  final Color positive;
  final Color negative;

  /// Vybraný motiv a konkrétní vzhled (už bez `auto`).
  final Accent preset;
  final Look look;

  /// Obsah leží na výrazné kartě (jinak `null`).
  final HeroSurface? surface;

  /// Zlatá pro rekordy a odznaky (ikony, ne text).
  Color get gold => background.computeLuminance() < 0.2
      ? const Color(0xFFFFD60A)
      : const Color(0xFFB07800);

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
    required this.preset,
    required this.look,
    this.surface,
  });

  factory AppPalette.of(
    Brightness b,
    Accent accent, [
    Look look = Look.auto,
    HeroSurface? surface,
  ]) {
    final dark = b == Brightness.dark;
    final resolved = look.resolve(b);
    final gradient = accent.gradient(b);

    // Obsah výrazné karty: barvy podle podkladu, ne podle stránky.
    if (surface == HeroSurface.bright) {
      const ink = Color(0xFF0B0B0C);
      return AppPalette(
        background: Colors.transparent,
        grouped: Colors.white.withValues(alpha: 0.38),
        elevated: Colors.white,
        separator: ink.withValues(alpha: 0.12),
        label: ink,
        secondaryLabel: ink.withValues(alpha: 0.74),
        tertiaryLabel: ink.withValues(alpha: 0.42),
        fill: Colors.white.withValues(alpha: 0.42),
        accent: ink,
        onAccent: Colors.white,
        gradient: gradient,
        onGradient: accent.onGradient,
        cta: ink,
        onCta: Colors.white,
        positive: const Color(0xFF14612A),
        negative: const Color(0xFF9E0012),
        preset: accent,
        look: resolved,
        surface: surface,
      );
    }
    if (surface == HeroSurface.glow) {
      final glow = accent.gradient(Brightness.dark);
      return AppPalette(
        background: Colors.transparent,
        grouped: Colors.white.withValues(alpha: 0.1),
        elevated: const Color(0xFF2C2C2E),
        separator: Colors.white.withValues(alpha: 0.16),
        label: Colors.white,
        secondaryLabel: Colors.white.withValues(alpha: 0.74),
        tertiaryLabel: Colors.white.withValues(alpha: 0.5),
        fill: Colors.white.withValues(alpha: 0.14),
        // Odkazy a ikony na tmavé záři: světlý tón motivu.
        accent: _lift(glow.first),
        onAccent: Colors.black,
        gradient: glow,
        onGradient: accent.onGradient,
        cta: Colors.white,
        onCta: Colors.black,
        positive: const Color(0xFF30D158),
        negative: const Color(0xFFFF6961),
        preset: accent,
        look: resolved,
        surface: surface,
      );
    }

    if (resolved == Look.tensor) {
      // Tensor: černá jako displej, karty o stupeň světlejší s linkou,
      // zelená jen tam, kde se rozhoduje (akce, rekordy, postup).
      return AppPalette(
        background: Colors.black,
        grouped: const Color(0xFF0B0B0B),
        elevated: const Color(0xFF161616),
        separator: const Color(0xFF242424),
        label: Colors.white,
        secondaryLabel: const Color(0xFF8E8E8E),
        tertiaryLabel: const Color(0xFF5C5C5C),
        fill: const Color(0xFF1A1A1A),
        accent: tensorGreen,
        onAccent: Colors.black,
        gradient: const [tensorGreen, Color(0xFF9AD61C), Color(0xFFB6F23A)],
        onGradient: Colors.black,
        cta: tensorGreen,
        onCta: Colors.black,
        positive: tensorGreen,
        negative: const Color(0xFFFF5C5C),
        preset: accent,
        look: resolved,
      );
    }

    if (resolved == Look.pitwall) {
      // Závod: noční boxová zeď. Plochy do modré, hlavní akce plná
      // závodní červená s bílým textem, odkazy světlejší červenou.
      return AppPalette(
        background: const Color(0xFF15151E),
        grouped: const Color(0xFF1F1F2B),
        elevated: const Color(0xFF2A2A38),
        separator: const Color(0xFF2E2E3D),
        label: Colors.white,
        secondaryLabel: const Color(0xFFA9A9BC),
        tertiaryLabel: const Color(0xFF6E6E84),
        fill: const Color(0xFF2A2A38),
        accent: const Color(0xFFFF5545),
        onAccent: Colors.black,
        gradient: const [
          Color(0xFFE10600),
          Color(0xFFFF5A1F),
          Color(0xFFFFB000),
        ],
        onGradient: Colors.black,
        cta: raceRed,
        onCta: Colors.white,
        positive: const Color(0xFF00E676),
        negative: const Color(0xFFFF6961),
        preset: accent,
        look: resolved,
      );
    }

    final positive = dark ? const Color(0xFF30D158) : const Color(0xFF248A3D);
    final negative = dark ? const Color(0xFFFF453A) : const Color(0xFFD70015);

    if (resolved == Look.studio) {
      // Studio: bílé / grafitové plochy, černobílé ovládání. Tmavý
      // režim není čistě černý a víc pracuje s bílou.
      final ink = dark ? Colors.white : const Color(0xFF0A0A0A);
      return AppPalette(
        background: dark ? const Color(0xFF0E0E10) : Colors.white,
        grouped: dark ? const Color(0xFF1C1C1F) : const Color(0xFFF4F4F6),
        elevated: dark ? const Color(0xFF2A2A2E) : Colors.white,
        separator: dark ? const Color(0xFF2E2E33) : const Color(0xFFE8E8EB),
        label: ink,
        secondaryLabel: dark
            ? const Color(0xFFB4B4BC)
            : const Color(0xFF6E6E73),
        tertiaryLabel: dark ? const Color(0xFF7A7A82) : const Color(0xFFA3A3A8),
        fill: dark ? const Color(0xFF2A2A2E) : const Color(0xFFEBEBEE),
        accent: ink,
        onAccent: dark ? Colors.black : Colors.white,
        gradient: gradient,
        onGradient: accent.onGradient,
        cta: ink,
        onCta: dark ? Colors.black : Colors.white,
        positive: positive,
        negative: negative,
        preset: accent,
        look: resolved,
      );
    }

    // Aurora: šedé pozadí, bílé karty bez rámečků, barevný motiv.
    return AppPalette(
      background: dark ? Colors.black : const Color(0xFFF4F4F7),
      grouped: dark ? const Color(0xFF1C1C1E) : Colors.white,
      elevated: dark ? const Color(0xFF2C2C2E) : Colors.white,
      separator: dark ? const Color(0xFF38383A) : const Color(0xFFE3E3E8),
      label: dark ? Colors.white : const Color(0xFF0B0B0C),
      secondaryLabel: dark ? const Color(0xFFA1A1A8) : const Color(0xFF6C6C70),
      tertiaryLabel: dark ? const Color(0xFF636366) : const Color(0xFFAEAEB2),
      fill: dark ? const Color(0xFF2C2C2E) : const Color(0xFFEBEBF0),
      accent: accent.solid(b),
      // Světlé tóny motivu jsou tmavé, tmavé světlé.
      onAccent: dark ? Colors.black : Colors.white,
      gradient: gradient,
      onGradient: accent.onGradient,
      // Ve tmě bílé tlačítko: méně „tmavé“ a dobře čitelné.
      cta: dark ? Colors.white : null,
      onCta: dark ? Colors.black : accent.onGradient,
      positive: positive,
      negative: negative,
      preset: accent,
      look: resolved,
    );
  }

  bool get studio => look == Look.studio;

  /// Závodní vzhled (F1 + telemetrie).
  bool get pitwall => look == Look.pitwall;

  /// Datový vzhled (Tensor).
  bool get tensor => look == Look.tensor;

  /// Telemetrie: Tensor i Závod (tabule rekordů, velké nadpisy, ŽIVĚ).
  bool get telemetry => pitwall || tensor;

  /// Závodní červená: hlavní akce, pruhy karet a světla startu.
  static const raceRed = Color(0xFFE10600);

  /// Zelená Tensoru a druhá datová barva (sacharidy, únava).
  static const tensorGreen = Color(0xFF76B900);
  static const tensorCyan = Color(0xFF2AD1FF);

  /// Zaoblení karty; v Závodě ostrý levý okraj s pruhem a měkčí pravý,
  /// v Tensoru skoro ostré rohy.
  BorderRadius cardRadius([double r = Radii.card]) => pitwall
      ? const BorderRadius.horizontal(
          left: Radius.circular(4),
          right: Radius.circular(12),
        )
      : tensor
      ? BorderRadius.circular(2)
      : BorderRadius.circular(r);

  /// Tvar karty. Tensor: zkosený pravý horní roh a tenká linka.
  ShapeBorder cardShape([double r = Radii.card]) => tensor
      ? BeveledRectangleBorder(
          borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
          side: BorderSide(color: separator),
        )
      : RoundedRectangleBorder(borderRadius: cardRadius(r));

  /// Zaoblení tlačítek a polí.
  double get controlRadius => telemetry ? (tensor ? 2 : 4) : Radii.control;

  static Color _lift(Color c) {
    final h = HSLColor.fromColor(c);
    return h.lightness >= 0.72 ? c : h.withLightness(0.72).toColor();
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
    final from = cta, to = other.cta;
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
      onGradient: c(onGradient, other.onGradient),
      cta: from != null && to != null ? c(from, to) : (t < 0.5 ? from : to),
      onCta: c(onCta, other.onCta),
      positive: c(positive, other.positive),
      negative: c(negative, other.negative),
      preset: t < 0.5 ? preset : other.preset,
      look: t < 0.5 ? look : other.look,
      surface: t < 0.5 ? surface : other.surface,
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
    return theme.extension<AppPalette>() ??
        AppPalette.of(theme.brightness, Accent.lime);
  }
}
