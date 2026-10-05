import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../coach/reminders.dart';
import 'notifier.dart';

/// Připomínky přes Android alarmy. Nepřesné plánování stačí (bez práva
/// na přesné budíky); oznámení může přijít o několik minut později.
class AndroidNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // zůstane UTC; čas se pak spočítá z posunu zařízení níže
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }();

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'training',
        'Připomínky tréninku',
        channelDescription: 'Připomene trénink v dny, které máš v plánu.',
      ),
    );
    for (var i = 0; i < reminders.length; i++) {
      final r = reminders[i];
      await _plugin.zonedSchedule(
        id: i,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }
}
