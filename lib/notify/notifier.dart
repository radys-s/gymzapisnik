import '../coach/reminders.dart';

/// Místní připomínky tréninku v nativních mobilních aplikacích.
abstract class Notifier {
  /// Umí toto zařízení naplánovaná oznámení?
  bool get supported;

  /// Požádá o povolení; `true` = oznámení jsou povolená.
  Future<bool> requestPermission();

  /// Nahradí připomínky tréninku; oznámení pauzy zachová.
  Future<void> schedule(List<Reminder> reminders);

  Future<void> cancelAll();
}

abstract interface class RestNotifier {
  Future<void> scheduleRest(DateTime end);
  Future<void> cancelRest();
}

class NoopNotifier implements Notifier {
  const NoopNotifier();

  @override
  bool get supported => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(List<Reminder> reminders) async {}

  @override
  Future<void> cancelAll() async {}
}
