/// App language. Czech is the source text, English the translation.
///
/// Texts are written in pairs at the call site: `tr('Uložit', 'Save')`.
/// The pair keeps both languages next to each other, so a missing or stale
/// translation is visible in review, and it also works outside widgets
/// (labels in the domain layer). [GymApp] sets [appLang] from the profile
/// and rebuilds the whole tree when it changes.
library;

enum AppLang {
  cs('Čeština'),
  en('English');

  /// Name of the language in that language.
  final String native;
  const AppLang(this.native);

  /// Stored code; unknown or retired codes (Slovak) fall back to Czech.
  static AppLang parse(Object? code) => switch (code) {
    'en' => AppLang.en,
    _ => AppLang.cs,
  };
}

/// Current language. Changed only by the app frame.
AppLang appLang = AppLang.cs;

bool get isEnglish => appLang == AppLang.en;

/// The text in the current language.
String tr(String cs, String en) => isEnglish ? en : cs;
