import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool)? toggleTheme;
  const SettingsScreen({super.key, this.toggleTheme});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // MethodChannel for asking native to open exact alarm settings
  static const MethodChannel _alarmPermissionChannel =
  MethodChannel('alarm_permission_channel');

  bool darkMode = false;
  String selectedLanguage = 'English';
  String selectedAzan = 'Default';
  bool fajrEnabled = false;
  bool zoharEnabled = false;
  bool maghribEnabled = false;

  final Map<String, Locale> languageMap = {
    'English': const Locale('en'),
    'Urdu': const Locale('ur'),
    'Hindi': const Locale('hi'),
    'Arabic': const Locale('ar'),
    'Farsi': const Locale('fa'),
  };

  /// Place these mp3 files in: android/app/src/main/res/raw/
  final Map<String, String> azanFiles = {
    'Default': 'azan_default',
    'Azan 2': 'azan_2',
    'Azan 3': 'azan_3',
  };

  final Map<String, int> prayerAdjustments = {
    'Fajr': 0,
    'Zoharain': 0,
    'Maghribain': 15,
  };

  final Map<String, int> notificationIds = {
    'Fajr': 101,
    'Zoharain': 102,
    'Maghribain': 103,
  };

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin notif = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initTimezone();
    _initNotifications();
    _ensureRuntimePermissions();
    // Request exact alarm permission prompt (native) as early as possible
    _requestExactAlarmPermission();
    loadSettings();
  }

  Future<void> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _alarmPermissionChannel.invokeMethod('requestExactAlarmPermission');
    } on PlatformException catch (e) {
      debugPrint('⚠️ requestExactAlarmPermission failed: $e');
    }
  }

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notif.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (_) async {
        try {
          await _playAzanSample();
        } catch (_) {}
      },
    );
    await _ensureAndroidChannelForCurrentSound();
  }

  Future<void> _ensureAndroidChannelForCurrentSound() async {
    final androidImpl = notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final channelId = _channelIdForCurrentSound();
    final channelName = _channelNameForCurrentSound();

    final soundRes = azanFiles[selectedAzan]!;
    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Prayer time alerts with Azan',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundRes),
    );

    await androidImpl.createNotificationChannel(channel);
  }

  Future<void> _ensureRuntimePermissions() async {
    // POST_NOTIFICATIONS (Android 13+)
    try {
      final n = await Permission.notification.status;
      if (n.isDenied || n.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}

    // request scheduleExactAlarm via permission_handler if available (best-effort)
    try {
      final s = await Permission.scheduleExactAlarm.status;
      if (s.isDenied) await Permission.scheduleExactAlarm.request();
    } catch (_) {}
  }

  Future<String> _getPackageName() async {
    final info = await PackageInfo.fromPlatform();
    return info.packageName;
  }

  Future<Position?> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return null;
    return Geolocator.getCurrentPosition();
  }

  Future<Map<String, String>?> _fetchPrayerTimes(Position position) async {
    try {
      final timestamp =
      (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).toInt();
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$timestamp?latitude=${position.latitude}&longitude=${position.longitude}&method=14',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];
        return {
          'Fajr': _convertTo24HourFormat(timings['Fajr']),
          'Zoharain': _convertTo24HourFormat(timings['Dhuhr']),
          'Maghribain': _convertTo24HourFormat(timings['Maghrib']),
        };
      }
    } catch (e) {
      debugPrint('❌ Prayer time fetch failed: $e');
    }
    return null;
  }

  String _convertTo24HourFormat(String time) {
    try {
      final parsed = DateFormat('HH:mm').parse(time);
      return DateFormat('HH:mm').format(parsed);
    } catch (_) {
      return time;
    }
  }

  String _convertTo12HourFormat(String time24, [int adjustMinutes = 0]) {
    try {
      var parsedTime = DateFormat('HH:mm').parse(time24);
      parsedTime = parsedTime.add(Duration(minutes: adjustMinutes));
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      debugPrint('Time conversion error: $e');
      return time24;
    }
  }

  String _channelIdForCurrentSound() => 'azan_channel_${azanFiles[selectedAzan]}';
  String _channelNameForCurrentSound() => 'Azan ($selectedAzan)';

  Future<void> _schedulePrayerNotifications() async {
    await _ensureAndroidChannelForCurrentSound();

    await notif.cancelAll();

    final pos = await _getLocation();
    if (pos == null) return;

    final times = await _fetchPrayerTimes(pos);
    if (times == null) return;

    for (final entry in times.entries) {
      final name = entry.key;
      final timeStr = entry.value;

      final enabled = (name == 'Fajr' && fajrEnabled) ||
          (name == 'Zoharain' && zoharEnabled) ||
          (name == 'Maghribain' && maghribEnabled);
      if (!enabled) continue;

      try {
        final now = DateTime.now();
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final adjustment = prayerAdjustments[name] ?? 0;
        var adjustedTime = DateTime(now.year, now.month, now.day, hour, minute)
            .add(Duration(minutes: adjustment));

        if (adjustedTime.isBefore(now)) {
          adjustedTime = adjustedTime.add(const Duration(days: 1));
        }

        final scheduledTime = tz.TZDateTime.from(adjustedTime, tz.local);
        debugPrint('🔔 Scheduling $name at $scheduledTime');

        // First try exact scheduling (requires exact alarm permission)
        try {
          await notif.zonedSchedule(
            id: notificationIds[name]!,
            title: 'Azan Time',
            body: 'It\'s time for $name prayer.',
            scheduledDate: scheduledTime,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channelIdForCurrentSound(),
                _channelNameForCurrentSound(),
                channelDescription: 'Prayer time alerts with Azan',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound(azanFiles[selectedAzan]),
                category: AndroidNotificationCategory.alarm,
                fullScreenIntent: true,
                visibility: NotificationVisibility.public,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } on PlatformException catch (e) {
          debugPrint('⚠️ Exact alarms not permitted, falling back: $e');

          // Fallback: schedule inexact alarm so notification still appears (less accurate)
          try {
            await notif.zonedSchedule(
                id: notificationIds[name]!,
                title: 'Azan Time',
                body: 'It\'s time for $name prayer.',
                scheduledDate: scheduledTime,
                notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  _channelIdForCurrentSound(),
                  _channelNameForCurrentSound(),
                  channelDescription: 'Prayer time alerts with Azan',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  sound:
                  RawResourceAndroidNotificationSound(azanFiles[selectedAzan]),
                  category: AndroidNotificationCategory.alarm,
                  fullScreenIntent: true,
                  visibility: NotificationVisibility.public,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
            );
          } catch (ex) {
            debugPrint('❌ Fallback scheduling failed for $name: $ex');
          }
        } catch (e) {
          debugPrint('❌ Notification error for $name: $e');
        }
      } catch (e) {
        debugPrint('❌ Notification scheduling block error for $name: $e');
      }
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final sl = prefs.getString('language') ?? 'English';
    final dl = languageMap[sl] ?? const Locale('en');

    if (context.mounted && context.locale != dl) {
      await context.setLocale(dl);
    }

    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
      selectedLanguage = sl;
      selectedAzan = prefs.getString('azanSound') ?? 'Default';
      fajrEnabled = prefs.getBool('notifyFajr') ?? false;
      zoharEnabled = prefs.getBool('notifyZohar') ?? false;
      maghribEnabled = prefs.getBool('notifyMaghrib') ?? false;
    });

    await _schedulePrayerNotifications();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);

    if (key == 'azanSound') {
      await _ensureAndroidChannelForCurrentSound();
    }

    await _schedulePrayerNotifications();
  }

  Future<void> _playAzanSample() async {
    final path = 'assets/audio/${azanFiles[selectedAzan]}.mp3';
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Azan sample error: $e');
    }
  }

  Widget _bell(String name, bool val, VoidCallback onTap) => ListTile(
    leading: const Icon(Icons.notifications, color: Colors.teal, size: 30),
    title: Text(name,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
    trailing: IconButton(
      icon: Icon(
        val ? Icons.notifications_off_rounded : Icons.notifications_none,
        size: 38,
        color: Colors.purple,
      ),
      onPressed: onTap,
    ),
  );

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text('App Language'.tr()),
            subtitle: Text(selectedLanguage.tr()),
            trailing: DropdownButton<String>(
              value: selectedLanguage,
              onChanged: (newValue) async {
                if (newValue != null && languageMap.containsKey(newValue)) {
                  await context.setLocale(languageMap[newValue]!);
                  await updateSetting('language', newValue);
                  setState(() => selectedLanguage = newValue);
                }
              },
              items: languageMap.keys
                  .map((lang) =>
                  DropdownMenuItem<String>(value: lang, child: Text(lang.tr())))
                  .toList(),
            ),
          ),
          SwitchListTile(
            title: Text('Dark Mode'.tr()),
            value: darkMode,
            onChanged: (v) {
              setState(() => darkMode = v);
              widget.toggleTheme?.call(v);
              updateSetting('darkMode', v);
            },
          ),
          ListTile(
            title: Text('Azan Sound'.tr()),
            subtitle: Text(selectedAzan),
            trailing: DropdownButton<String>(
              value: selectedAzan,
              items: azanFiles.keys
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.tr())))
                  .toList(),
              onChanged: (v) async {
                if (v != null) {
                  setState(() => selectedAzan = v);
                  await updateSetting('azanSound', v);
                  await _playAzanSample();
                }
              },
            ),
          ),
          const Divider(),
          Text('Namaz Notifications'.tr()),
          _bell('Fajr', fajrEnabled, () {
            setState(() => fajrEnabled = !fajrEnabled);
            updateSetting('notifyFajr', fajrEnabled);
          }),
          _bell('Zoharain', zoharEnabled, () {
            setState(() => zoharEnabled = !zoharEnabled);
            updateSetting('notifyZohar', zoharEnabled);
          }),
          _bell('Maghribain', maghribEnabled, () {
            setState(() => maghribEnabled = !maghribEnabled);
            updateSetting('notifyMaghrib', maghribEnabled);
          }),
        ],
      ),
    );
  }
}
