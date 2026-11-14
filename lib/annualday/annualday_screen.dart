import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../marquee_bar/marquee_bar.dart';


class AnnualdayScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const AnnualdayScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _AnnualdayScreenState createState() => _AnnualdayScreenState();
}

class _AnnualdayScreenState extends State<AnnualdayScreen> {
  String? videoUrl;
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
    try {
      Uri uri = Uri.parse(url);

      if (uri.queryParameters.containsKey("v")) {
        return uri.queryParameters["v"];
      }

      if (uri.host.contains("youtu.be")) {
        return uri.pathSegments.first;
      }

      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (e) {
      print("❌ Error parsing video URL: $e");
    }

    return null;
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
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height:
                      MediaQuery.of(context).size.height * 0.8,
                      child: YoutubePlayer(
                        controller: _youtubeController!,
                        aspectRatio: 16 / 9,
                      ),
                    ),
                  ),
                  if (!_isFullScreen)
                    const Expanded(
                      child: SizedBox(), // Placeholder
                    ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),

          if (!_isFullScreen)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          // ✅ Global MarqueeBar used here
          if (!_isFullScreen)
            const Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: MarqueeBar(),
            ),
        ],
      ),
    );
  }
}
