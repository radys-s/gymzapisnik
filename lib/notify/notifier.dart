import '../coach/reminders.dart';

/// Místní oznámení. Na Androidu skutečná, jinde (web, iPhone PWA) nic.
abstract class Notifier {
  /// Umí toto zařízení naplánovaná oznámení?
  bool get supported;

  /// Požádá o povolení; `true` = oznámení jsou povolená.
  Future<bool> requestPermission();

  /// Nahradí všechna naplánovaná oznámení těmito.
  Future<void> schedule(List<Reminder> reminders);

  Future<void> cancelAll();
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
