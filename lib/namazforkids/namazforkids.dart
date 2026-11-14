import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:marquee/marquee.dart';

class NamazForKidsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const NamazForKidsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _NamazForKidsScreenState createState() => _NamazForKidsScreenState();
}

class _NamazForKidsScreenState extends State<NamazForKidsScreen> {
  String? videoUrl;
  String _marqueeText = "Loading...";
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoReady = false;

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

      if (!docSnapshot.exists) {
        print("❌ Chapter document not found for: ${widget.chapter}");
        return;
      }

      var chapterData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      final marqueeDoc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get();
      _marqueeText = marqueeDoc.data()?['marqueeText'] ?? '';
      print("✅ Marquee text loaded: $_marqueeText");

      videoUrl = chapterData["video_url"];

      if (videoUrl != null && videoUrl!.isNotEmpty) {
        print("✅ Video URL found: $videoUrl");

        _videoController = VideoPlayerController.network(videoUrl!);
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.red,
            handleColor: Colors.redAccent,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.lightGreen,
          ),
        );

        setState(() {
          _isVideoReady = true;
        });

        print("✅ Video initialized and ready");
      } else {
        print("⚠️ No video URL found in Firestore for chapter: ${widget.chapter}");
      }
    } catch (e) {
      print("❌ Error loading data: $e");
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          _isVideoReady && _chewieController != null
              ? Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),
          )
              : const Center(child: CircularProgressIndicator()),

          // ✅ Marquee at bottom
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
