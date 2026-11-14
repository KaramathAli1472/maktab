import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import '../PhotoGallery/PhotoGalleryScreen.dart';
import '../amal/amal_screen.dart';
import '../awards/awards_page.dart';
import '../calender/calender_screen.dart';
import '../contact/contact_us.dart';
import '../introduction/IntroductionPage.dart';
import '../live_ class/home_screen.dart';
import '../live_ class/join_meeting_screen.dart';
import '../live_ class/live_class_screen.dart';
import '../nauhe/nauhe_screen.dart';
import '../qiblafinder/qiblafinder_screen.dart';
import '../quranjuzz/quran_menu_screen.dart';
import '../settings_screen.dart';
import '../slate/slate_screen.dart';
import '../sub_menu/sub_menu_screen.dart';
import '../tasbeehcounter./tasbeehcounter.dart';
import '../user_info_screen.dart';
import '../activity_book/activity_book.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late HijriCalendar hijriDate;
  late String gregorianDate;
  Timer? _timer;
  final Map<String, String> prayerTimes = {};
  final CollectionReference menuCollection =
      FirebaseFirestore.instance.collection('menuItems');

  final Map<String, IconData> prayerIcons = {
    'Fajr': Icons.brightness_2,
    'Sunrise': Icons.wb_sunny,
    'Zohar': Icons.wb_incandescent,
    'Sunset': Icons.bedtime,
    'Maghrib': Icons.nightlight_round,
    'Midnight': Icons.dark_mode,
  };

  String userName = "Guest User";
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal("en");
    hijriDate = HijriCalendar.fromDate(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    gregorianDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    loadUserName();
    fetchPrayerTimes();
    startAutoUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newLocale = context.locale;
    if (_currentLocale != newLocale) {
      _currentLocale = newLocale;
      setState(() {});
    }
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Guest User';
    });
  }

  void startAutoUpdate() {
    _timer = Timer.periodic(const Duration(minutes: 30), (Timer t) {
      fetchPrayerTimes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> checkLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> fetchPrayerTimes() async {
    try {
      await checkLocationPermission();
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final timestamp =
          (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).toInt();
      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/$timestamp?latitude=${position.latitude}&longitude=${position.longitude}&method=14',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];
        if (timings == null) throw Exception('Invalid timing data');

        setState(() {
          prayerTimes.clear();
          prayerTimes.addAll({
            'Fajr': _convertTo12HourFormat(timings['Fajr'], -1),
            'Sunrise': _convertTo12HourFormat(timings['Sunrise']),
            'Zohar': _convertTo12HourFormat(timings['Dhuhr']),
            'Sunset': _convertTo12HourFormat(timings['Sunset'], 0),
            'Maghrib': _convertTo12HourFormat(timings['Maghrib'], 14),
            'Midnight': _convertTo12HourFormat(timings['Midnight'], -36),
          });
        });
      } else {
        throw Exception('Failed to load prayer times');
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
    }
  }

  String _convertTo12HourFormat(String time24, [int adjustMinutes = 0]) {
    try {
      DateTime parsedTime = DateFormat('HH:mm').parse(time24);
      parsedTime = parsedTime.add(Duration(minutes: adjustMinutes));
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
      print('Time conversion error: $e');
      return time24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 300,
            color: Colors.white,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset('assets/image.png', fit: BoxFit.cover),
                ),
                Positioned(
                  top: 25,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                ),
                Positioned(
                  top: 25,
                  right: 5,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.white,
                        size: 30,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${hijriDate.hDay} ${hijriDate.longMonthName} ${hijriDate.hYear}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        gregorianDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 20,
                  right: 10,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: prayerTimes.entries.map((entry) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _namazItem(
                            prayerIcons[entry.key] ?? Icons.access_alarm,
                            entry.key.tr(),
                            entry.value,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _buildMenuGrid(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: StreamBuilder<QuerySnapshot>(
          stream: menuCollection.orderBy('order').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('no_menu_items'.tr()));
            }

            final menuItems = snapshot.data!.docs;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                var item =
                    menuItems[index].data() as Map<String, dynamic>;
                String subMenuID = item['subMenuID'] ?? '';
                String title = item['title'] ?? '';

                return GestureDetector(
                  onTap: () => _navigateToMenu(title, subMenuID, context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 8,
                          spreadRadius: 1,
                          color: Colors.cyanAccent,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            item['image_url'] ??
                                'default_image_url_here',
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToMenu(String title, String subMenuID, BuildContext context) {
    if (title == 'Camera') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
      return;
    }
    // Accept either a title of "Activity Book" (case-insensitive)
    // or a Firestore `subMenuID` value of `activity_book` to open the Activity Book screen.
    final normalizedTitle = title.toLowerCase().trim();
    if (normalizedTitle == 'activity book' ||
        subMenuID == 'activity_book' ||
        subMenuID == 'activitybookMenu') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ActivityBookScreen()),
      );
      return;
    }

    final routes = {
      'Introduction': const IntroductionPage(),
      'Aamal': AamalMenuPage(),
      'Nauhe': NauhaMenuPage(),
      'Calendar': CalendarScreen(),
      'Qibla Finder': QiblaFinderPage(),
      'Tasbeeh Counter': TasbeehCounterPage(),
      'Daily Quiz': UserInfoScreen(),
      'Awards & Certificate': const AwardsPage(),
      'Contact': const ContactUsPage(),
      'Maktab Slate': const SlateScreen(),
      'Photo Gallery': const PhotoGalleryScreen(),
      'Quran Digital': const QuranMenuScreen(),
    };

    if (routes.containsKey(title)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => routes[title]!),
      );
    } else if (subMenuID.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubMenuScreen(
            title: title.tr(),
            subMenuID: subMenuID,
          ),
        ),
      );
    }
  }

  Widget _namazItem(IconData icon, String label, String time) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Colors.black),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 10.5,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

