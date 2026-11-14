import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DailyquizScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    );
  }
}

class DailyquizScreen extends StatefulWidget {
  final String userId;
  const DailyquizScreen({super.key, required this.userId});
  @override
  State<DailyquizScreen> createState() => _DailyquizScreenState();
}

class _DailyquizScreenState extends State<DailyquizScreen> {
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;
  Map<String, String> answers = {};
  late String todayId;
  String? userId;
  int currentTab = 0;  // 0 = Quiz, 1 = Leaderboard
  int secondsLeft = 60; // Timer seconds
  Timer? quizTimer;

  @override
  void initState() {
    super.initState();
    todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
      setupFCM();
      loadQuiz();

      quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (secondsLeft > 0) {
          setState(() {
            secondsLeft--;
          });
        } else {
          timer.cancel();
          // Optionally call submitQuiz() here if you want auto submit on timer end
        }
      });

      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          _handleMessage(message);
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    } else {
      setState(() {
        isLoading = false;
      });
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${message.notification!.title ?? ''}: ${message.notification!.body ?? ''}')),
        );
      }
    });
  }

  @override
  void dispose() {
    quizTimer?.cancel();
    super.dispose();
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data['screen'] == 'daily_quiz') {
      setState(() {
        currentTab = 0;
      });
    }
  }

  void saveTokenToFirestore(String token) async {
    if (userId == null) return;
    try {
      await FirebaseFirestore.instance.collection('userTokens').doc(userId).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to save token: $e");
    }
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      if (token != null) saveTokenToFirestore(token);
      await messaging.subscribeToTopic('allUsers');
    }
  }

  Future<void> loadQuiz() async {
    try {
      final docRef = FirebaseFirestore.instance.collection('dailyquizMenu').doc(todayId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists && docSnapshot.data()?['questions'] is List) {
        final List<dynamic> rawQuestions = docSnapshot['questions'];
        final convertedQuestions = rawQuestions.map((q) => Map<String, dynamic>.from(q as Map)).toList();
        setState(() {
          questions = convertedQuestions;
          isLoading = false;
          answers.clear();
          secondsLeft = 60; // Reset timer on new quiz load
        });
      } else {
        await docRef.set({
          'questions': [
            {
              'id': 'q1',
              'questionText': 'What is the capital of France?',
              'options': ['Paris', 'London', 'Berlin', 'Rome'],
              'correctAnswer': 'Paris',
            },
          ],
        });
        setState(() {
          questions = [
            {
              'id': 'q1',
              'questionText': 'What is the capital of France?',
              'options': ['Paris', 'London', 'Berlin', 'Rome'],
              'correctAnswer': 'Paris',
            },
          ];
          isLoading = false;
          answers.clear();
          secondsLeft = 60;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitQuiz() async {
    if (userId == null) return;
    int correctAnswers = 0;
    List<Map<String, String>> results = [];
    for (var question in questions) {
      final qid = question['id'];
      final correctAnswer = question['correctAnswer'];
      final userAnswer = answers[qid];
      if (userAnswer == correctAnswer) {
        correctAnswers++;
      }
      results.add({
        'question': question['questionText'],
        'userAnswer': userAnswer ?? 'No answer',
        'correctAnswer': correctAnswer,
        'isCorrect': (userAnswer == correctAnswer) ? 'true' : 'false',
      });
    }
    final docId = "${userId}_$todayId";
    await FirebaseFirestore.instance.collection('quizResults').doc(docId).set({
      'userId': userId,
      'date': todayId,
      'score': correctAnswers,
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Quiz Results"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final res = results[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${index + 1}. ${res['question']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("Your answer: ${res['userAnswer']}", style: TextStyle(
                      color: res['isCorrect'] == 'true' ? Colors.green : Colors.red,
                    )),
                    if (res['isCorrect'] == 'false')
                      Text("Correct answer: ${res['correctAnswer']}", style: const TextStyle(color: Colors.green)),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); },
            child: const Text("Close"),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You scored $correctAnswers out of ${questions.length}")),
    );
  }

  Widget buildQuizContent() {
    if (questions.isEmpty) return Container();
    final q = questions.first;
    final qid = q['id'] ?? '';
    final options = q['options'] as List<dynamic>? ?? [];
    final selectedAnswer = answers[qid];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 18),
        // LIVE TIMER PROGRESS BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Container(
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                ),
              ),
              FractionallySizedBox(
                widthFactor: secondsLeft / 60,
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B266D), Color(0xFFF4956F)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(
                        "${secondsLeft}s",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 45),
                      child: Icon(Icons.schedule, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Question of the day",
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7B266D)),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            q['questionText'] ?? '',
            style: TextStyle(fontSize: 16, color: Colors.grey[900]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 25),
        ...options.map((opt) {
          bool checked = selectedAnswer == opt;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              onTap: () => setState(() => answers[qid] = opt),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                  border: checked
                      ? Border.all(color: const Color(0xFF7B266D), width: 2)
                      : Border.all(color: Colors.white, width: 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(opt,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    Icon(
                      checked ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: checked ? const Color(0xFF7B266D) : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: const Color(0xFF7B266D),
            ),
            onPressed: answers.length == questions.length ? submitQuiz : null,
            child: const Text("Submit Quiz",
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      SingleChildScrollView(
        child: isLoading
            ? Center(
                child: Padding(
                padding: const EdgeInsets.only(top: 160),
                child: const CircularProgressIndicator(),
              ))
            : buildQuizContent(),
      ),
      LeaderboardScreen(date: todayId),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Daily Quiz",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: const Icon(Icons.arrow_back, color: Colors.black),
      ),
      body: screens[currentTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTab,
        onTap: (index) => setState(() => currentTab = index),
        selectedItemColor: const Color(0xFF7B266D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
        ],
      ),
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  final String date;
  const LeaderboardScreen({super.key, required this.date});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboardData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('quizResults')
          .where('date', isEqualTo: widget.date)
          .orderBy('score', descending: true)
          .get();
      final List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        final resultData = doc.data();
        final uid = resultData['userId'];
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final userData = userDoc.data();
        if (userData != null) {
          users.add({
            'name': userData['name'] ?? 'Unknown',
            'city': userData['city'] ?? '',
            'country': userData['country'] ?? '',
            'score': resultData['score'] ?? 0,
          });
        }
      }
      setState(() {
        leaderboardData = users;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching leaderboard: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboardData.length,
      itemBuilder: (context, index) {
        final user = leaderboardData[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text("${index + 1}")),
            title: Text(user['name']),
            subtitle: Text("${user['city']}, ${user['country']}"),
            trailing: Text("Score: ${user['score']}"),
          ),
        );
      },
    );
  }
}

