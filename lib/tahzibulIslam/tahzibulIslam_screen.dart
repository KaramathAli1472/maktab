import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:marquee/marquee.dart';

class TahzibulIslamScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const TahzibulIslamScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _TahzibulIslamScreenState createState() => _TahzibulIslamScreenState();
}

class _TahzibulIslamScreenState extends State<TahzibulIslamScreen> {
  String? videoUrl;
  String _marqueeText = "Loading...";
  YoutubePlayerController? _youtubeController;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final DocumentReference chapterDoc = FirebaseFirestore.instance
        .collection(widget.detailsID)
        .doc(widget.chapter);

    try {
      var docSnapshot = await chapterDoc.get();

      if (!docSnapshot.exists) return;

      var chapterData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      // ✅ Load global marquee text
      final marqueeDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get();
      _marqueeText = marqueeDoc.data()?['marqueeText'] ?? "No marquee text available";

      setState(() {
        videoUrl = chapterData["video_url"];

        if (videoUrl != null && videoUrl!.isNotEmpty) {
          String? videoId = _extractVideoId(videoUrl!);

          if (videoId != null) {
            _youtubeController = YoutubePlayerController.fromVideoId(
              videoId: videoId,
              autoPlay: false,
              params: const YoutubePlayerParams(
                showControls: true,
                showFullscreenButton: true,
                enableCaption: true,
              ),
            );
            _youtubeController!.setFullScreenListener((isFullScreen) {
              if (mounted && _isFullScreen != isFullScreen) {
                setState(() {
                  _isFullScreen = isFullScreen;
                });
              }
            });
          }
        }
      });
    } catch (e) {
      print("❌ Error loading data: $e");
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
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          videoUrl != null && _youtubeController != null
              ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0), // ✅ Upar thoda space
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.8, // ✅ Thoda bada height
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                  if (!_isFullScreen)
                    Expanded(
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const SizedBox(), // marquee already at bottom
                      ),
                    ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),

          // ✅ Back Button — only show when not in fullscreen
          if (!_isFullScreen)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          // ✅ Marquee — show only when not in fullscreen
          if (!_isFullScreen)
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
