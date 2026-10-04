import 'package:flutter_test/flutter_test.dart';
import 'package:gymzapisnik/domain/profile.dart';

void main() {
  final now = DateTime.utc(2026, 10, 4, 12);

  test('new profile has no consent', () {
    expect(const Profile().hasValidConsent, isFalse);
  });

  test('adult consent is valid and allows weight-loss targets', () {
    final p = const Profile().acceptConsent(
      adult: true,
      guardianConsent: false,
      now: now,
    );
    expect(p.hasValidConsent, isTrue);
    expect(p.restrictWeightLoss, isFalse);
  });

  test('minor consent requires guardian and restricts weight loss', () {
    final p = const Profile().acceptConsent(
      adult: false,
      guardianConsent: true,
      now: now,
    );
    expect(p.guardianConsent, isTrue);
    expect(p.hasValidConsent, isTrue);
    expect(p.restrictWeightLoss, isTrue);
  });

  test('minor without guardian consent is rejected', () {
    expect(
      () => const Profile().acceptConsent(
        adult: false,
        guardianConsent: false,
        now: now,
      ),
      throwsArgumentError,
    );
  });

  test('older consent version is not valid', () {
    final p = Profile(
      consentVersion: currentConsentVersion - 1,
      consentAt: now,
      adult: true,
    );
    expect(p.hasValidConsent, isFalse);
  });

  test('json round trip keeps unknown keys', () {
    final p = const Profile().acceptConsent(
      adult: true,
      guardianConsent: false,
      now: now,
    );
    final json = {...p.toJson(), 'future': 42};
    final back = Profile.fromJson(json);
    expect(back.hasValidConsent, isTrue);
    expect(back.consentAt, now);
    expect(back.toJson()['future'], 42);
  });
}
