import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const taskName = 'dailyAzanScheduleTask';

final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initializeBackgroundTask() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    'daily_azan_id',
    taskName,
    frequency: const Duration(hours: 24),
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == taskName) {
      await _setupTimezone();
      await _scheduleAzanNotifications();
    }
    return Future.value(true);
  });
}

Future<void> _setupTimezone() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // Set your local timezone
}

Future<void> _scheduleAzanNotifications() async {
  final prefs = await SharedPreferences.getInstance();

  final bool fajrEnabled = prefs.getBool('notifyFajr') ?? false;
  final bool zoharEnabled = prefs.getBool('notifyZohar') ?? false;
  final bool maghribEnabled = prefs.getBool('notifyMaghrib') ?? false;
  final String selectedAzan = prefs.getString('azanSound') ?? 'azan_default';

  final azanFiles = {
    'azan_default': 'azan_default',
    'azan_2': 'azan_2',
    'azan_3': 'azan_3',
  };

  final prayerAdjustments = {
    'Fajr': -1,
    'Zoharain': 0,
    'Maghribain': 14,
  };

  final notificationIds = {
    'Fajr': 101,
    'Zoharain': 102,
    'Maghribain': 103,
  };

  final pos = await _getLocation();
  if (pos == null) return;

  final timings = await _fetchPrayerTimes(pos);
  if (timings == null) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await notificationsPlugin.initialize(settings: initSettings);

  await notificationsPlugin.cancelAll();

  for (final entry in timings.entries) {
    final name = entry.key;
    final timeStr = entry.value;

    final enabled = (name == 'Fajr' && fajrEnabled) ||
        (name == 'Zoharain' && zoharEnabled) ||
        (name == 'Maghribain' && maghribEnabled);
    if (!enabled) continue;

    try {
      final now = DateTime.now();
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      int adjust = prayerAdjustments[name] ?? 0;

      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute)
          .add(Duration(minutes: adjust));

      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await notificationsPlugin.zonedSchedule(
        id: notificationIds[name]!,
        title: '$name Azan',
        body: 'It\'s time for $name prayer.',
        scheduledDate: tzTime,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'azan_channel',
            'Azan Notifications',
            channelDescription: 'Prayer time alerts',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(
              azanFiles[selectedAzan] ?? 'azan_default',
            ),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('❌ Error scheduling $name: $e');
    }
  }
}

Future<Position?> _getLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) return null;

  return Geolocator.getCurrentPosition();
}

Future<Map<String, String>?> _fetchPrayerTimes(Position pos) async {
  final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final url =
      'https://api.aladhan.com/v1/timings/$timestamp?latitude=${pos.latitude}&longitude=${pos.longitude}&method=14';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return null;

  final data = jsonDecode(response.body)['data']['timings'] as Map<String, dynamic>;
  return {
    'Fajr': data['Fajr'],
    'Zoharain': data['Dhuhr'],
    'Maghribain': data['Maghrib'],
  };
}
