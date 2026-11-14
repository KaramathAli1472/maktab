import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:marquee/marquee.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView for Android
  if (WebViewPlatform.instance is! AndroidWebViewPlatform) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stories App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChahelhadeesScreen(
        title: 'Story Title',
        subtitle: 'Subtitle here',
        detailsID: 'stories_collection',
        chapter: 'chapter1',
        description: 'This is the story description',
      ),
    );
  }
}

class ChahelhadeesScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const ChahelhadeesScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _ChahelhadeesScreenState createState() => _ChahelhadeesScreenState();
}

class _ChahelhadeesScreenState extends State<ChahelhadeesScreen> {
  String? videoUrl;
  String? slideUrl;
  String _marqueeText = "Loading...";
  YoutubePlayerController? _youtubeController;
  bool _isLoading = true; // 🔄 For showing loading spinner

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print("📥 detailsID: ${widget.detailsID}");
    print("📥 chapter: ${widget.chapter}");

    final DocumentReference chapterDoc = FirebaseFirestore.instance
        .collection(widget.detailsID)
        .doc(widget.chapter);

    try {
      var docSnapshot = await chapterDoc.get();

      print("📄 Document exists: ${docSnapshot.exists}");

      if (!docSnapshot.exists) {
        setState(() {
          _marqueeText = "No data found";
          _isLoading = false;
        });
        return;
      }

      var chapterData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      print("📄 Data from Firestore: $chapterData");

      String? video = chapterData["video_url"];
      String? slide = chapterData["slideUrl"];

      final marqueeDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get();
      String marquee = marqueeDoc.data()?['marqueeText'] ?? 'No marquee text available';

      YoutubePlayerController? tempController;
      if (video != null && video.isNotEmpty) {
        String? videoId = _extractVideoId(video);
        print("🎥 YouTube Video ID: $videoId");

        if (videoId != null) {
          tempController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            autoPlay: false,
            params: const YoutubePlayerParams(enableCaption: false),
          );
        }
      }

      setState(() {
        _marqueeText = marquee;
        videoUrl = video;
        slideUrl = slide;
        _youtubeController = tempController;
        _isLoading = false; // ✅ Done loading
      });
    } catch (e) {
      print("❌ Error loading data: $e");
      setState(() {
        _marqueeText = "Error loading data";
        _isLoading = false;
      });
    }
  }

  String? _extractVideoId(String url) {
    RegExp regExp = RegExp(
      r"(?<=v=|/videos/|embed/|youtu.be/|/v/|/e/|watch\?v=|watch\?.+&v=)([^#&?]+)",
      caseSensitive: false,
    );
    return regExp.firstMatch(url)?.group(0);
  }

  @override
  void dispose() {
    _youtubeController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    } else if (videoUrl != null && _youtubeController != null) {
      content = Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: YoutubePlayer(
          controller: _youtubeController!,
          aspectRatio: 16 / 9,
        ),
      );
    } else if (slideUrl != null && slideUrl!.isNotEmpty) {
      content = WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(slideUrl!)),
      );
    } else {
      content = Center(
        child: Text(
          _marqueeText,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,

          // 🔙 Back Button
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 🎞 Marquee Text
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 40,
              color: Colors.black,
              child: Marquee(
                text: _marqueeText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                scrollAxis: Axis.horizontal,
                blankSpace: 50.0,
                velocity: 30.0,
                pauseAfterRound: const Duration(seconds: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
