import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import '../marquee_bar/marquee_bar.dart';


class AnjumanScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String detailsID;
  final String chapter;
  final String description;

  const AnjumanScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _AnjumanScreenState createState() => _AnjumanScreenState();
}

class _AnjumanScreenState extends State<AnjumanScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<void> _loadDataFuture;
  bool _dataLoaded = false;
  Map<String, Map<String, String>> translations = {};
  String currentLanguage = "urdu";
  String? audioUrl;
  bool isPlaying = false;
  late AudioPlayer _audioPlayer;
  String marqueeText = "";

  bool _isArabic(String input) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(input);
  }

  @override
  void initState() {
    super.initState();

    print("🔥 AnjumanScreen initialized!");
    print("✅ Title: ${widget.title}");
    print("✅ Subtitle: ${widget.subtitle}");
    print("✅ DetailsID: ${widget.detailsID}");
    print("✅ Chapter: ${widget.chapter}");

    _audioPlayer = AudioPlayer();
    _loadDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      final DocumentReference chapterDoc = FirebaseFirestore.instance
          .collection(widget.detailsID)
          .doc(widget.chapter);

      print("📥 Fetching data from collection: ${widget.detailsID}, doc: ${widget.chapter}");

      try {
        var snapshot = await chapterDoc.get();

        if (!snapshot.exists) {
          print("❌ Document does not exist in Firestore!");
          return;
        }

        var chapterData = snapshot.data() as Map<String, dynamic>? ?? {};
        print("📦 Fetched chapter data: $chapterData");

        if (chapterData["translations"] is Map<String, dynamic>) {
          Map<String, dynamic> translationsData =
          chapterData["translations"] as Map<String, dynamic>;

          translationsData.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              // Convert Map<String, dynamic> to Map<String, String>
              Map<String, String> mapValue = {};
              value.forEach((k, v) {
                if (v is String) {
                  // Replace literal "\n" with actual newline
                  mapValue[k] = v.replaceAll(r"\n", "\n");
                }
              });
              translations[key] = mapValue;
            }
          });
        }

        audioUrl = chapterData["audio_url"];

        final marqueeDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .get();
        marqueeText = marqueeDoc.get("marqueeText") ?? "";
        print("Marquee Text: $marqueeText");

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
                              String text = translations[language]?["text"] ?? "";
                              print('$language text: $text');

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                child: ChoiceChip(
                                  label: Text(
                                    language.toUpperCase(),
                                    style: TextStyle(
                                      color: currentLanguage == language
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: currentLanguage == language,
                                  selectedColor: Theme.of(context).primaryColor,
                                  backgroundColor: Colors.grey[300],
                                  showCheckmark: false,
                                  onSelected: text.trim().isEmpty
                                      ? null
                                      : (bool selected) {
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
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'JameelNooriNastaleeq',
                                color: Colors.black,
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
                          const SizedBox(height: 8),
                          if (_isArabic(text))
                            Text(
                              text,
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: const TextStyle(
                                fontSize: 24,
                                height: 1.8,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'JameelNooriNastaleeq',
                                color: Colors.black,
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
                              setState(() {
                                isPlaying = false;
                              });
                            } else {
                              if (audioUrl != null && audioUrl!.isNotEmpty) {
                                try {
                                  if (_audioPlayer.processingState ==
                                      ProcessingState.idle) {
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
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const MarqueeBar(
                        height: 40,
                        backgroundColor: Colors.black,
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
