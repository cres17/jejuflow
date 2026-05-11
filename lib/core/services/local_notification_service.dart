import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/saved_route.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _routeChannelId = 'jejuflow_route_reminders';
  static const _legacyWeatherNotificationId = 9001;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
    return androidGranted && iosGranted;
  }

  static Future<void> scheduleRouteReminder(
    SavedRoute route, {
    String languageCode = 'en',
  }) async {
    if (kIsWeb) return;
    await initialize();
    final reminderAt = route.savedAt.subtract(const Duration(minutes: 30));
    if (reminderAt.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      return;
    }
    final (title, body) = _routeReminderText(route, languageCode);
    await _plugin.zonedSchedule(
      id: _routeNotificationId(route),
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _routeChannelId,
          'Route reminders',
          channelDescription: 'Reminders before saved JejuFlow route times',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> scheduleRouteReminders(
    Iterable<SavedRoute> routes, {
    String languageCode = 'en',
  }) async {
    for (final route in routes) {
      await scheduleRouteReminder(route, languageCode: languageCode);
    }
  }

  static Future<void> cancelRouteReminder(SavedRoute route) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: _routeNotificationId(route));
  }

  static Future<void> cancelRouteReminders(Iterable<SavedRoute> routes) async {
    for (final route in routes) {
      await cancelRouteReminder(route);
    }
  }

  static Future<void> cancelLegacyWeatherAlerts() async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancel(id: _legacyWeatherNotificationId);
  }

  static int _routeNotificationId(SavedRoute route) {
    return 100000 + (route.id.hashCode & 0x3fffffff) % 800000;
  }

  static (String, String) _routeReminderText(
      SavedRoute route, String languageCode) {
    return switch (languageCode) {
      'ko' => ('일정 알림', '${route.spotName} 출발 30분 전이에요.'),
      'ja' => ('ルート通知', '${route.spotName} 出発30分前です。'),
      'zh' => ('行程提醒', '${route.spotName} 将在30分钟后出发。'),
      _ => ('Route reminder', '${route.spotName} starts in 30 minutes.'),
    };
  }
}
