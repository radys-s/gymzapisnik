import 'package:flutter/services.dart';

/// Hmatová odezva podle významu, ne podle síly.
///
/// Každá událost má jeden vzorec, ať se uživatel naučí, co cítí.
abstract final class Haptics {
  /// Výběr, krok, posun hodnoty.
  static void tick() => HapticFeedback.selectionClick();

  /// Stisk hlavního tlačítka.
  static void tap() => HapticFeedback.lightImpact();

  /// Potvrzená série.
  static void confirm() => HapticFeedback.mediumImpact();

  /// Nový rekord.
  static void record() => HapticFeedback.heavyImpact();

  /// Dokončený trénink.
  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.heavyImpact();
  }

  /// Konec pauzy, upozornění.
  static void alert() => HapticFeedback.vibrate();
}
