import 'profile_keys.dart';
import 'strength.dart';

/// Aktuální verze podmínek. Zvýšení vynutí nový souhlas.
const currentConsentVersion = 1;

/// Uživatelský profil uložený v zařízení (jeden dokument `profile`).
/// Nabízené kroky tlačítek +/− u váhy.
const weightSteps = [1.0, 1.25, 2.5, 5.0];

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
  String? get splitId => extra[ProfileKey.split] as String?;

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

  /// Má zaplacené Pro. Platí jen při zapnutém paywallu
  /// (viz `premium/entitlements.dart`).
  bool get isPro => extra[ProfileKey.pro] == true;

  /// Vlastní týdenní cíl tréninků (1–7); `null` = podle splitu.
  int? get weekGoal {
    final v = extra[ProfileKey.weekGoal];
    return v is num ? v.toInt().clamp(1, 7) : null;
  }

  /// Dny tréninku (1 = pondělí, seřazené); `null` = kdykoli v týdnu.
  List<int>? get trainingDays {
    final v = extra[ProfileKey.trainingDays];
    if (v is! List) return null;
    final days = {
      for (final d in v)
        if (d is num && d >= 1 && d <= 7) d.toInt(),
    }.toList()..sort();
    return days.isEmpty ? null : days;
  }

  /// Čas připomínky v minutách od půlnoci; `null` = vypnuto.
  int? get reminderMinutes {
    final v = extra[ProfileKey.reminder];
    return v is num ? v.toInt().clamp(0, 1439) : null;
  }

  /// Uživatel prošel úvodem (ukazuje se jen jednou).
  bool get welcomeSeen => extra[ProfileKey.welcomeSeen] == true;

  /// Verze, jejíž novinky už uživatel viděl.
  String? get seenVersion => extra[ProfileKey.seenVersion] as String?;

  /// Naposledy otevřená záložka (0 = Domů, 1 = Trénink, 2 = Strava,
  /// 3 = Profil). Starší verze ukládaly `tab` (1 = Pokrok, 2 = Strava)
  /// a ještě starší `lastTab` (1 = Strava).
  int get lastTab {
    final t = extra[ProfileKey.tab];
    if (t is int && t >= 0 && t <= 3) return t;
    return switch (extra[ProfileKey.legacyTab]) {
      1 => 3,
      2 => 2,
      _
          when extra[ProfileKey.legacyTab] == null &&
              extra[ProfileKey.legacyLastTab] == 1 =>
        2,
      _ => 0,
    };
  }

  /// Výchozí pauza mezi sériemi v sekundách.
  int get restSeconds {
    final v = extra[ProfileKey.restSeconds];
    return v is num ? v.toInt().clamp(15, 600) : 120;
  }

  /// Vlastní pauza u cviku v sekundách; `null` = výchozí [restSeconds].
  int? restFor(String exerciseId) {
    final map = extra[ProfileKey.restByExercise];
    final v = map is Map ? map[exerciseId] : null;
    return v is num && v.isFinite ? v.toInt().clamp(15, 600) : null;
  }

  /// Připnutá poznámka ke cviku (nastavení stroje, úchop); ukazuje se
  /// v každém tréninku. `null` = žádná.
  String? exerciseNote(String exerciseId) {
    final map = extra[ProfileKey.exerciseNotes];
    final v = map is Map ? map[exerciseId] : null;
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  /// Tabulka pro úroveň síly; `null` = uživatel ještě nevybral.
  StrengthStandard? get strengthStandard =>
      StrengthStandard.parse(extra[ProfileKey.strengthStandard]);

  /// Krok tlačítek +/− u váhy v kg.
  double get weightStep {
    final v = extra[ProfileKey.weightStep];
    return v is num && weightSteps.contains(v.toDouble()) ? v.toDouble() : 2.5;
  }

  /// Nezletilým aplikace nikdy nenastaví kalorický deficit ani hubnutí.
  bool get restrictWeightLoss => !adult;

  static double? _num(Object? v, double min, double max) =>
      v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;

  /// Volitelný denní cíl bílkovin v gramech (nastavuje uživatel sám).
  double? get proteinTarget => _num(extra[ProfileKey.proteinTarget], 20, 400);

  /// Volitelný denní cíl energie v kcal; jen pro dospělé.
  double? get kcalTarget => restrictWeightLoss
      ? null
      : _num(extra[ProfileKey.kcalTarget], 1000, 6000);

  /// Uživatel viděl upozornění, kam jde fotka pro AI.
  bool get aiNoticeAccepted => extra[ProfileKey.aiNotice] == true;

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
