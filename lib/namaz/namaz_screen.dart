import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class NamazDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const NamazDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _NamazDetailScreenState createState() => _NamazDetailScreenState();
}

class _NamazDetailScreenState extends State<NamazDetailScreen> {
  late Future<void> _loadDataFuture;
  bool _dataLoaded = false;
  Map<String, dynamic>? contentData;
  String? audioUrl;
  bool isPlaying = false;
  late AudioPlayer _audioPlayer;
  String marqueeText = "";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    if (_dataLoaded) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection(widget.detailsID)
          .doc(widget.chapter);

      var snapshot = await docRef.get();
      if (!snapshot.exists) {
        setState(() => _dataLoaded = false);
        return;
      }

      contentData = snapshot.data() as Map<String, dynamic>? ?? {};

      // Audio link
      audioUrl = contentData?["audio_url"]?.toString();

      // Marquee text
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
      setState(() => _dataLoaded = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Arabic text widget
  Widget arabicText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        softWrap: true,
        overflow: TextOverflow.visible,
        maxLines: null,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'KFGQPC Uthman', // ensure this matches pubspec family
          height: 1.6,
        ),
      ),
    );
  }

  /// English text widget
  Widget englishText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: 'Roboto',
          color: Colors.black,
          height: 1.5,
        ),
      ),
    );
  }

  /// Build content from JSON file (array of english/arabic blocks)
  Widget buildContentFromJson(Map<String, dynamic> data) {
    List<Widget> widgets = [];

    if (data.containsKey("content")) {
      List contents = data["content"];
      for (var item in contents) {
        if (item["type"] == "english" && item["text"] != null) {
          widgets.add(englishText(item["text"]));
        }
        if (item["type"] == "arabic" && item["text"] != null) {
          widgets.add(arabicText(item["text"]));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
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
                padding: const EdgeInsets.only(
                    left: 18, right: 18, top: 18, bottom: 130),
                child: buildContentFromJson(contentData ?? {}),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Play Audio',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (marqueeText.isNotEmpty)
                        Container(
                          height: 40,
                          width: double.infinity,
                          color: Colors.black,
                          child: Marquee(
                            text: marqueeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontFamily: 'Roboto',
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
