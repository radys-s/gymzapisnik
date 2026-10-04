import 'package:flutter/foundation.dart';

import '../data/store.dart';
import '../domain/profile.dart';

/// Stav aplikace sdílený obrazovkami. UI nesahá přímo na úložiště.
class AppState extends ChangeNotifier {
  final LocalStore store;
  AppState(this.store);

  Profile profile = const Profile();

  Future<void> load() async {
    await store.open();
    final json = await store.get(Profile.id);
    profile = json == null ? const Profile() : Profile.fromJson(json);
    notifyListeners();
  }

  Future<void> acceptConsent({
    required bool adult,
    required bool guardianConsent,
  }) async {
    final next = profile.acceptConsent(
      adult: adult,
      guardianConsent: guardianConsent,
      now: DateTime.now(),
    );
    await store.put('profile', next.toJson());
    profile = next;
    notifyListeners();
  }

  /// Uloží rozepsaná data před aktualizací webové verze.
  Future<void> saveBeforeUpdate() async {}
}
