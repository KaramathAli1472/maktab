import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutter = FlutterLocalNotificationsPlugin();

  /// ✅ Call this in main() or at app startup
  Future<void> init() async {
    // Timezone initialization
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Notification init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    await _flutter.initialize(settings: initializationSettings);
  }

  /// ✅ Call this to schedule one-time Azan notifications (per day)
  Future<void> scheduleAzanNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required String sound, // e.g. 'azan_default'
  }) async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(dateTime, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      // 🔁 Skip scheduling past time
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'azan_channel', // must match your AndroidManifest
      'Azan Alerts',
      channelDescription: 'Prayer time alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound), // Don't include .mp3
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _flutter.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null, // ❗ Don't repeat — one-time schedule
    );
  }

  /// 🔁 Call this to cancel all scheduled notifications (before rescheduling)
  Future<void> cancelAll() async {
    await _flutter.cancelAll();
  }
}
