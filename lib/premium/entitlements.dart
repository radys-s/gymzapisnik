/// Co je v placené verzi Pro. Čistý Dart bez Flutteru.
///
/// Platba zatím neexistuje: dokud je [paywallEnabled] `false`, je všechno
/// odemčené (testeři). Pozdější paywall = přepnout konstantu a doplnit nákup,
/// obrazovky se nemění.
library;

import '../domain/profile.dart';

/// Přepnout na `true`, až bude hotový nákup Pro.
const paywallEnabled = false;

/// Funkce, které jsou v Pro. Záznam tréninků, historie, cviky, záloha, CSV
/// a import zůstávají zdarma navždy.
enum ProFeature {
  coach(
    'Kouč: návrh váhy',
    'Pro každý cvik navrhne váhu a opakování podle minula, včetně odlehčení.',
  ),
  mission(
    'Denní mise a streak',
    'Co dnes dělat, aby ses vešel do týdenního cíle, a týdny v řadě se žolíkem.',
  ),
  recap('Shrnutí týdne', 'Objem proti minulému týdnu a nové rekordy.'),
  progress(
    'Rychlý progres',
    'Graf síly nejčastěji cvičeného cviku přímo na úvodní obrazovce.',
  );

  final String title;
  final String description;
  const ProFeature(this.title, this.description);
}

abstract final class Entitlements {
  /// Je funkce dostupná? Bez zapnutého paywallu vždy ano.
  static bool has(
    Profile profile,
    ProFeature feature, {
    bool paywall = paywallEnabled,
  }) => !paywall || profile.isPro;
}
