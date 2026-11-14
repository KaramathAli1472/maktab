      import 'package:flutter/material.dart';
      import 'package:cloud_firestore/cloud_firestore.dart';
      import 'package:just_audio/just_audio.dart';
      import 'package:marquee/marquee.dart';
      import 'package:flutter_local_notifications/flutter_local_notifications.dart';
      import 'package:timezone/data/latest.dart' as tz;
      import 'package:timezone/timezone.dart' as tz;
      import 'package:permission_handler/permission_handler.dart';


      class DuaDetailScreen extends StatefulWidget {
        final String title;
        final String subtitle;
        final String detailsID;
        final String chapter;
        final String description;

        const DuaDetailScreen({
          super.key,
          required this.title,
          required this.subtitle,
          required this.detailsID,
          required this.chapter,
          required this.description,
        });

        @override
        _DuaDetailScreenState createState() => _DuaDetailScreenState();
      }

      class _DuaDetailScreenState extends State<DuaDetailScreen> {
        final ScrollController _scrollController = ScrollController();
        late Future<void> _loadDataFuture;
        bool _dataLoaded = false;
        Map<String, Map<String, String>> translations = {};
        String currentLanguage = "arabic";
        String? audioUrl;
        bool isPlaying = false;
        late AudioPlayer _audioPlayer;
        String marqueeText = "";
        late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
        TimeOfDay? _selectedTime;

        @override
        void initState() {
          super.initState();
          _loadDataFuture = _loadData();
          _audioPlayer = AudioPlayer();
          tz.initializeTimeZones();
          _initializeNotifications();
          _requestNotificationPermission();
        }

        Future<void> _requestNotificationPermission() async {
          var status = await Permission.notification.status;
          if (!status.isGranted) {
            status = await Permission.notification.request();
          }
          print("🔔 Notification permission status: $status");
        }

        Future<void> _initializeNotifications() async {
          flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

          const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

          final InitializationSettings initializationSettings = InitializationSettings(
            android: initializationSettingsAndroid,
          );

          await flutterLocalNotificationsPlugin.initialize(
            settings: initializationSettings,
          );

          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'your_channel_id', // id
            'Your Channel Name', // name
            description: 'Description of your channel',
            importance: Importance.max,
          );

          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(channel);
        }

        Future<void> _scheduleNotification(TimeOfDay time, String title) async {
          // Initialize timezone if needed
          final now = tz.TZDateTime.now(tz.local);
          tz.TZDateTime scheduledDate = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          print('🕐 Device timezone: ${tz.local.name}');

          if (scheduledDate.isBefore(now)) {
            scheduledDate = scheduledDate.add(const Duration(days: 1));
          }

          print("📅 Scheduling notification at: ${scheduledDate.toLocal()}");

          // Check and request notification permission
          var status = await Permission.notification.status;
          if (!status.isGranted) {
            status = await Permission.notification.request();
          }

          print("🔔 Notification permission status: $status");

          if (!status.isGranted) {
            print("❌ Notification permission denied");
            return;
          }

          try {
            await flutterLocalNotificationsPlugin.zonedSchedule(
              id: 0,
              title: 'Dua Reminder',
              body: 'It\'s time for your dua: $title',
              scheduledDate: scheduledDate,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'dua_channel_id',
                  'Dua Notifications',
                  channelDescription: 'Reminders for dua timings',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            print("✅ Notification scheduled successfully");
          } catch (e) {
            print("❌ Error scheduling notification: $e");
          }
        }

        Future<void> _pickTime() async {
          final TimeOfDay? picked = await showTimePicker(
            context: context,
            initialTime: _selectedTime ?? TimeOfDay.now(),
          );
          if (picked != null) {
            setState(() => _selectedTime = picked);
            await _scheduleNotification(picked, 'Asr Dua');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Alarm set for ${picked.format(context)}')),
            );
          }
        }

        bool _isArabic(String input) {
          final arabicRegex = RegExp(r'[\u0600-\u06FF]');
          return arabicRegex.hasMatch(input);
        }

        Future<void> _loadData() async {
          if (!_dataLoaded) {
            final DocumentReference chapterDoc =
            FirebaseFirestore.instance.collection(widget.detailsID).doc(widget.chapter);

            try {
              var chapterData =
                  (await chapterDoc.get()).data() as Map<String, dynamic>? ?? {};
              if (chapterData["translations"] is Map<String, dynamic>) {
                Map<String, dynamic> translationsData = chapterData["translations"];
                translationsData.forEach((key, value) {
                  if (value is Map<String, dynamic>) {
                    translations[key] = Map<String, String>.from(value);
                    if (translations[key]?["text"] != null) {
                      translations[key]!["text"] = translations[key]!["text"]!.replaceAll("\\n", "\n");
                    }
                  }
                });
              }

              audioUrl = chapterData["audio_url"];
              final marqueeDoc = await FirebaseFirestore.instance
                  .collection('app_settings')
                  .doc('global')
                  .get();
              marqueeText = marqueeDoc.data()?['marqueeText'] ?? '';

              if (audioUrl != null && audioUrl!.isNotEmpty) {
                await _audioPlayer.setUrl(audioUrl!);
              }

              setState(() => _dataLoaded = true);
            } catch (e) {
              print("Error loading data: $e");
            }
          }
        }

        @override
        void dispose() {
          _audioPlayer.dispose();
          super.dispose();
        }

        @override
        Widget build(BuildContext context) {
          String title = translations[currentLanguage]?["title"] ?? "No Title";
          String text = translations[currentLanguage]?["text"] ?? "No Text";

          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              centerTitle: true,
              actions: [
                PopupMenuButton(
                  icon: const Icon(Icons.alarm),
                  onSelected: (value) {
                    if (value == 'set_alarm') {
                      _pickTime();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'set_alarm',
                      child: Text(
                        _selectedTime == null
                            ? 'Set Alarm for this Dua'
                            : 'Alarm set at ${_selectedTime!.format(context)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: FutureBuilder<void>(
              future: _loadDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load data.'));
                } else if (!_dataLoaded) {
                  return const Center(child: Text('Data not found.'));
                }

                return Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...["arabic", "transli"].map((language) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                      child: ChoiceChip(
                                        label: Text(
                                          language.toUpperCase(),
                                          style: TextStyle(
                                            color: currentLanguage == language ? Colors.white : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        selected: currentLanguage == language,
                                        selectedColor: Theme.of(context).primaryColor,
                                        backgroundColor: Colors.grey[300],
                                        showCheckmark: false,
                                        onSelected: (bool selected) {
                                          if (selected) {
                                            setState(() {
                                              currentLanguage = language;
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                if (_isArabic(title))
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'AlMushafQuran',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                if (!_isArabic(title))
                                  Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Roboto',
                                      color: Colors.black,
                                    ),
                                  ),
                                SizedBox(height: _isArabic(title) ? 20 : 8),
                                if (_isArabic(text))
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      text,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        height: 2.1,
                                        fontFamily: 'AlMushafQuran',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                if (!_isArabic(text))
                                  Text(
                                    text,
                                    textAlign: TextAlign.center,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.6,
                                      fontFamily: 'Roboto',
                                      color: Colors.black,
                                    ),
                                  ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_audioPlayer.playing) {
                                    await _audioPlayer.pause();
                                    setState(() => isPlaying = false);
                                  } else {
                                    await _audioPlayer.play();
                                    setState(() => isPlaying = true);
                                  }
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                    const SizedBox(width: 10),
                                    Text(
                                      isPlaying ? 'Pause Audio' : 'Play Audio',
                                      style: const TextStyle(
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (marqueeText.isNotEmpty)
                              Container(
                                color: Colors.black,
                                height: 40,
                                width: double.infinity,
                                child: Marquee(
                                  text: marqueeText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                  blankSpace: 100,
                                  velocity: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      }
