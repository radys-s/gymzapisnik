/// Aktuální verze podmínek. Zvýšení vynutí nový souhlas.
const currentConsentVersion = 1;

/// Uživatelský profil uložený v zařízení (jeden dokument `profile`).
class Profile {
  static const id = 'profile';

  final int consentVersion;
  final DateTime? consentAt;

  /// Uživatel potvrdil, že je mu 18 let nebo víc.
  final bool adult;

  /// Nezletilý uživatel potvrdil souhlas zákonného zástupce.
  final bool guardianConsent;

  /// Klíče, které tato verze nezná, se při uložení zachovají.
  final Map<String, dynamic> extra;

  const Profile({
    this.consentVersion = 0,
    this.consentAt,
    this.adult = false,
    this.guardianConsent = false,
    this.extra = const {},
  });

  bool get hasValidConsent =>
      consentVersion >= currentConsentVersion &&
      consentAt != null &&
      (adult || guardianConsent);

  /// Zvolený split (ID šablony z `coach/splits.dart`), `null` = volné tréninky.
  String? get splitId => extra['split'] as String?;

  /// Kopie s jinými hodnotami v `extra` (`null` hodnotu klíč odstraní).
  Profile withExtra(Map<String, dynamic> changes) {
    final next = {...extra, ...changes}..removeWhere((_, v) => v == null);
    return Profile(
      consentVersion: consentVersion,
      consentAt: consentAt,
      adult: adult,
      guardianConsent: guardianConsent,
      extra: next,
    );
  }

  /// Výchozí pauza mezi sériemi v sekundách (nastavení přibude v M8).
  int get restSeconds {
    final v = extra['restSeconds'];
    return v is num ? v.toInt().clamp(15, 600) : 120;
  }

  /// Nezletilým aplikace nikdy nenastaví kalorický deficit ani hubnutí.
  bool get restrictWeightLoss => !adult;

  /// Nezletilý bez souhlasu zákonného zástupce souhlas udělit nemůže.
  Profile acceptConsent({
    required bool adult,
    required bool guardianConsent,
    required DateTime now,
  }) {
    if (!adult && !guardianConsent) {
      throw ArgumentError('Nezletilý potřebuje souhlas zákonného zástupce.');
    }
    return Profile(
      consentVersion: currentConsentVersion,
      consentAt: now,
      adult: adult,
      guardianConsent: !adult && guardianConsent,
      extra: extra,
    );
  }

  static const _known = {
    'id',
    'consentVersion',
    'consentAt',
    'adult',
    'guardianConsent',
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    consentVersion: (json['consentVersion'] as num?)?.toInt() ?? 0,
    consentAt: DateTime.tryParse(json['consentAt'] as String? ?? ''),
    adult: json['adult'] == true,
    guardianConsent: json['guardianConsent'] == true,
    extra: {
      for (final e in json.entries)
        if (!_known.contains(e.key)) e.key: e.value,
    },
  );

  Map<String, dynamic> toJson() => {
    ...extra,
    'id': id,
    'consentVersion': consentVersion,
    'consentAt': consentAt?.toUtc().toIso8601String(),
    'adult': adult,
    'guardianConsent': guardianConsent,
  };
}
