import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:maktab_e_sidratul_muntaha/quiz/dailyquiz_screen.dart';
import 'package:maktab_e_sidratul_muntaha/providers/pointer_provider.dart';
import 'package:maktab_e_sidratul_muntaha/widgets/spotlight_pointer.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'home/menu_screen.dart';
import 'update_checker.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background: ${message.messageId}');
}

FirebaseAnalytics analytics = FirebaseAnalytics.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.signInAnonymously();
      print("✅ Anonymous sign-in successful: ${auth.currentUser?.uid}");
    } catch (e) {
      print("❌ Anonymous sign-in failed: $e");
    }
  }
  await WakelockPlus.enable();
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ur'),
        Locale('hi'),
        Locale('ar'),
        Locale('fa'),
      ],
      path: 'assets/langs',
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: ChangeNotifierProvider(
        create: (_) => PointerProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool darkMode = false;
  @override
  void initState() {
    super.initState();
    _loadDarkMode();
  }
  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      darkMode = prefs.getBool('darkMode') ?? false;
    });
  }
  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      darkMode = value;
    });
  }

  // NEW: Responsive wrapper for desktop
  Widget _buildResponsiveWrapper({required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 1024;
        final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 1024;

        if (isDesktop) {
          // Desktop Layout with Sidebar
          return Scaffold(
            body: Row(
              children: [
                // Desktop Sidebar
                _buildDesktopSidebar(context),

                // Main Content Area (Centered with max width)
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 1200,
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (isTablet) {
          // Tablet Layout (Centered with max width)
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 800,
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: child,
            ),
          );
        } else {
          // Mobile Layout (Full width)
          return child;
        }
      },
    );
  }

  // NEW: Desktop Sidebar Widget
  Widget _buildDesktopSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: darkMode ? Colors.grey[900] : Color(0xFF2c3e50),
      child: Column(
        children: [
          SizedBox(height: 40),

          // App Logo/Title
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.transparent,
                  child: Image.asset('assets/logo.png', height: 70, width: 70),
                ),
                SizedBox(height: 16),
                Text(
                  'Maktab-e-Sidratul Muntaha',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Islamic Learning App',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white54),
          SizedBox(height: 20),

          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSidebarItem('Home', Icons.home, context),
                _buildSidebarItem('Quran', Icons.book, context),
                _buildSidebarItem('Hadith', Icons.library_books, context),
                _buildSidebarItem('Books', Icons.menu_book, context),
                _buildSidebarItem('Quiz', Icons.quiz, context),
                _buildSidebarItem('Notifications', Icons.notifications, context),
                _buildSidebarItem('Settings', Icons.settings, context),
              ],
            ),
          ),

          Divider(color: Colors.white54),

          // Dark Mode Toggle
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  darkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white70,
                ),
                SizedBox(width: 12),
                Text(
                  'Dark Mode',
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                Switch(
                  value: darkMode,
                  onChanged: _toggleDarkMode,
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // NEW: Sidebar Item Widget
  Widget _buildSidebarItem(String title, IconData icon, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title.tr(),
        style: TextStyle(color: Colors.white),
      ),
      onTap: () {
        // Navigation logic can be added here
        print('Navigate to: $title');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to $title...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      hoverColor: Colors.white.withOpacity(0.1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'app_name'.tr(),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: _buildResponsiveWrapper(
        child: AdmissionPopupScreen(toggleTheme: _toggleDarkMode),
      ),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            GlobalPointer(),
          ],
        );
      },
    );
  }
}

class AdmissionPopupScreen extends StatefulWidget {
  final Function(bool)? toggleTheme;
  const AdmissionPopupScreen({super.key, this.toggleTheme});

  @override
  State<AdmissionPopupScreen> createState() => _AdmissionPopupScreenState();
}

class _AdmissionPopupScreenState extends State<AdmissionPopupScreen> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
    _initVideoAndShowDialog();
  }

  Future<void> _initVideoAndShowDialog() async {
    _videoController = VideoPlayerController.network(
      'https://res.cloudinary.com/duq6pvkz6/video/upload/v1762836022/maktab_video1_l7tyxb.mp4',
    );
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: true,
      showControls: false,
      allowMuting: false,
      aspectRatio: _videoController.value.aspectRatio,
    );
    if (mounted) {
      _showAdmissionDialog();
    }
  }

  @override
  void dispose() {
    _chewieController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔐 Notification permission: ${settings.authorizationStatus}');
    String? token = await messaging.getToken();
    print("📱 FCM Token: $token");
    final currentUser = FirebaseAuth.instance.currentUser;
    if (token != null && currentUser != null) {
      await FirebaseFirestore.instance.collection('userTokens').doc(currentUser.uid).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("✅ Token saved to Firestore for user: ${currentUser.uid}");
    }
    await messaging.subscribeToTopic("allUsers");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _logNotificationEvent('foreground', message);
        _showFlutterLocalNotification(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
        );
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logNotificationEvent('background_tap', message);
      final screen = message.data['screen'];
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (screen == 'daily_quiz' && userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyquizScreen(userId: userId)),
        );
      } else if (message.notification != null && mounted) {
        _showNotificationDialog(
          message.notification!.title ?? 'Notification',
          message.notification!.body ?? '',
        );
      }
    });
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _logNotificationEvent('terminated_tap', initialMessage);
      final screen = initialMessage.data['screen'];
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (screen == 'daily_quiz' && userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyquizScreen(userId: userId)),
        );
      } else if (initialMessage.notification != null && mounted) {
        _showNotificationDialog(
          initialMessage.notification!.title ?? 'Notification',
          initialMessage.notification!.body ?? '',
        );
      }
    }
  }

  void _logNotificationEvent(String eventName, RemoteMessage message) {
    analytics.logEvent(
      name: eventName,
      parameters: {
        'message_id': message.messageId ?? '',
        'title': message.notification?.title ?? '',
        'body': message.notification?.body ?? '',
      },
    );
  }

  void _showNotificationDialog(String title, String body) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFlutterLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Used for important alerts.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  void _showAdmissionDialog() {
    if (!mounted) return;

    // NEW: Responsive dialog for desktop
    final isDesktop = MediaQuery.of(context).size.width > 1024;
    final dialogWidth = isDesktop ? 500.0 : 350.0;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Admission Dialog",
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              titlePadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              title: Column(
                children: [
                  Image.asset('assets/logo.png', height: 100, width: 100),
                  const SizedBox(height: 16),
                  Text('welcome'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Text('app_name'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('admissions_open'.tr(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.red)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: dialogWidth * 0.8,
                    height: 220,
                    child: Chewie(
                      controller: _chewieController,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('admission_info'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(
                            'https://docs.google.com/forms/d/e/1FAIpQLSeeVuofJ6-j66o1dHUrAHtPKJ63aPvZYPed4vvM3wCXLe2aqA/viewform');
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('form_open_error'.tr())),
                          );
                        }
                      },
                      child: Text('register'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        print("🚪 Closing admission dialog, going to main screen");
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MenuScreenWithUpdateCheck()),
                        );
                      },
                      child: Text('continue'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('loading'.tr())),
    );
  }
}

// MenuScreen with Update Check and Responsive Design
class MenuScreenWithUpdateCheck extends StatefulWidget {
  const MenuScreenWithUpdateCheck({super.key});

  @override
  State<MenuScreenWithUpdateCheck> createState() => _MenuScreenWithUpdateCheckState();
}

class _MenuScreenWithUpdateCheckState extends State<MenuScreenWithUpdateCheck> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      print("⏳ Menu screen loaded, checking for update...");
      await Future.delayed(Duration(seconds: 2));

      if (mounted && !_updateChecked) {
        print("🎯 Calling UpdateChecker from MenuScreen...");
        setState(() {
          _updateChecked = true;
        });
        await UpdateChecker.checkForUpdate(context);
      }
    } catch (e) {
      print("❌ Update check in MenuScreen error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // This will be wrapped by the responsive wrapper in MyApp
    return MenuScreen();
  }
}