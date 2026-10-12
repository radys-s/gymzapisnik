import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../coach/reminders.dart';
import 'notifier.dart';

/// Připomínky přes Android alarmy. Nepřesné plánování stačí (bez práva
/// na přesné budíky); oznámení může přijít o několik minut později.
class AndroidNotifier extends MobileNotifier {
  AndroidNotifier() : super(platform: TargetPlatform.android);
}

class MobileNotifier implements Notifier, RestNotifier {
  MobileNotifier({required this.platform});
  final TargetPlatform platform;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;
  bool _zoneKnown = false;

  Future<void> _init() => _ready ??= () async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      _zoneKnown = true;
    } catch (_) {
      // Bez známého pásma by se připomínky plánovaly v UTC, tak radši žádné.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  bool get supported => true;

  @override
  Future<bool> requestPermission() async {
    await _init();
    if (platform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true, badge: false) ??
          false;
    }
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(List<Reminder> reminders) async {
    await _init();
    await cancelAll();
    if (!_zoneKnown) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'training',
        'Připomínky tréninku',
        channelDescription: 'Připomene trénink v dny, které máš v plánu.',
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: 'training'),
    );
    for (var i = 0; i < reminders.length && i < 14; i++) {
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
    for (var i = 0; i < 14; i++) {
      await _plugin.cancel(id: i);
    }
  }

  @override
  Future<void> scheduleRest(DateTime end) async {
    await _init();
    await cancelRest();
    if (!_zoneKnown || !end.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: 9000,
      title: 'Pauza končí',
      body: 'Můžeš pokračovat další sérií.',
      scheduledDate: tz.TZDateTime.from(end, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'rest',
          'Pauza mezi sériemi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'rest'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancelRest() async {
    await _init();
    await _plugin.cancel(id: 9000);
  }
}
