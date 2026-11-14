import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class SalamDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const SalamDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _SalamDetailScreenState createState() => _SalamDetailScreenState();
}

class _SalamDetailScreenState extends State<SalamDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<void> _loadDataFuture;
  bool _dataLoaded = false;
  Map<String, Map<String, String>> translations = {};
  String currentLanguage = "urdu";
  String? audioUrl;
  bool isPlaying = false;
  late AudioPlayer _audioPlayer;
  String marqueeText = ""; // ✅ Marquee variable

  bool _isArabic(String input) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(input);
  }

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
    _audioPlayer = AudioPlayer();
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      final DocumentReference chapterDoc = FirebaseFirestore.instance
          .collection(widget.detailsID)
          .doc(widget.chapter);

      try {
        var chapterData =
            (await chapterDoc.get()).data() as Map<String, dynamic>? ?? {};

        if (chapterData["translations"] is Map<String, dynamic>) {
          Map<String, dynamic> translationsData =
          chapterData["translations"] as Map<String, dynamic>;
          translationsData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              translations[key] = Map<String, String>.from(value);
              if (translations[key]?["text"] != null) {
                translations[key]!["text"] =
                    translations[key]!["text"]!.replaceAll("\\n", "\n");
              }
            }
          });
        }

        audioUrl = chapterData["audio_url"];

        // ✅ Load marquee text from global settings
        final marqueeDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .get();
        marqueeText = marqueeDoc.data()?['marqueeText'] ?? '';
        print("✅ Global Marquee Text: $marqueeText");

        if (audioUrl != null && audioUrl!.isNotEmpty) {
          await _audioPlayer.setUrl(audioUrl!);
        }

        setState(() {
          _dataLoaded = true;
        });
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

          String title = translations[currentLanguage]?["title"] ?? "No Title";
          String text = translations[currentLanguage]?["text"] ?? "No Text";

          return Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 70),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...["urdu", "transli"].map((language) {
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                  fontFamily: 'JameelNooriNastaleeq',
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
// Yahan condition ke sath SizedBox lagayenge
                          SizedBox(height: _isArabic(title) ? 20 : 8),
                          if (_isArabic(text))
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: () {
                                  final lines = text.split('\n');
                                  List<Widget> styledLines = [];
                                  for (int i = 0; i < lines.length; i += 2) {
                                    final color = ((i ~/ 2) % 2 == 0) ? Colors.black : Colors.green;
                                    String lineGroup = lines[i];
                                    if (i + 1 < lines.length) {
                                      lineGroup += '\n${lines[i + 1]}';
                                    }
                                    styledLines.add(
                                      Text(
                                        lineGroup,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          height: 2.0,
                                          fontFamily: 'JameelNooriNastaleeq',
                                          color: color,
                                        ),
                                      ),
                                    );
                                  }
                                  return styledLines;
                                }(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
              // Bottom: Audio Player + Marquee
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_audioPlayer.playing) {
                              await _audioPlayer.pause();
                              setState(() {
                                isPlaying = false;
                              });
                            } else {
                              if (audioUrl != null && audioUrl!.isNotEmpty) {
                                try {
                                  if (_audioPlayer.processingState == ProcessingState.idle) {
                                    await _audioPlayer.setUrl(audioUrl!);
                                  }
                                  await _audioPlayer.play();
                                  setState(() {
                                    isPlaying = true;
                                  });
                                } catch (e) {
                                  print("Error playing audio: $e");
                                }
                              } else {
                                print("Audio URL is null or empty!");
                              }
                            }
                          },
                          child: Text(
                            isPlaying ? "Pause" : "Play",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      // Marquee Text
                      Container(
                        height: 40,
                        width: double.infinity,
                        color: Colors.black,
                        child: Marquee(
                          text: marqueeText,
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
