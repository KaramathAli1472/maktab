// ✅ Final integrated version: Global marquee loaded from Firebase
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

Widget buildArabicImagePlaceholder({double height = 120}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/image.png',
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    ),
  );
}

Widget buildArabicAyahImage(Ayah ayah, {double height = 110}) {
  final url = ayah.arabicImageUrl.trim();

  if (url.isEmpty) {
    return buildArabicImagePlaceholder(height: height);
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return buildArabicImagePlaceholder(height: height);
      },
    ),
  );
}

class Ayah {
  final int number;
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String arabicImageUrl;
  final String urdu;
  final String translation;
  final String transliteration;
  final String audioUrl;

  Ayah({
    required this.number,
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.arabicImageUrl,
    required this.urdu,
    required this.translation,
    required this.transliteration,
    required this.audioUrl,
  });

  factory Ayah.fromMap(Map<String, dynamic> data) {
    final imageUrl = data['arabicImageUrl'] ??
        data['arabicImage'] ??
        data['imageUrl'] ??
        data['image'] ??
        '';

    return Ayah(
      number: data['number'] is String ? int.tryParse(data['number']) ?? 0 : data['number'] ?? 0,
      surahNumber: data['surahNumber'] is String ? int.tryParse(data['surahNumber']) ?? 0 : data['surahNumber'] ?? 0,
      ayahNumber: data['ayahNumber'] is String ? int.tryParse(data['ayahNumber']) ?? 0 : data['ayahNumber'] ?? 0,
      arabic: data['arabic'] ?? '',
      arabicImageUrl: imageUrl is String ? imageUrl : imageUrl.toString(),
      urdu: data['urdu'] ?? '',
      translation: data['translation'] ?? '',
      transliteration: data['transliteration'] ?? '',
      audioUrl: data['audioUrl'] ?? '',
    );
  }
}

class SurahDetailScreen extends StatefulWidget {
  final String title;
  final String description;
  final String detailsID;
  final String chapter;
  final String surahId;

  const SurahDetailScreen({
    super.key,
    required this.title,
    required this.description,
    required this.detailsID,
    required this.chapter,
    required this.surahId,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  List<Ayah> _ayahs = [];
  List<GlobalKey> _ayahKeys = [];
  bool _loading = true;
  double _fontSizeArabic = 24;
  double _fontSizeUrdu = 19;
  double _fontSizeTranslation = 16;
  double _fontSizeTransliteration = 16;
  bool _isAutoPlaying = false;
  int _currentAyahIndex = -1;
  String? _autoPlayAudioUrl;
  String _marqueeText = '';
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    _fetchMarqueeText();
    _marqueeTimer = Timer.periodic(Duration(minutes: 5), (_) => _fetchMarqueeText());
  }

  Future<void> _fetchMarqueeText() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('global').get();
      if (doc.exists) {
        setState(() {
          _marqueeText = doc.data()?['marqueeText'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load marquee text: $e');
    }
  }

  Future<void> _loadSurahData() async {
    try {
      final surahDoc = await FirebaseFirestore.instance.collection('quransurahs_details').doc(widget.surahId).get();
      if (surahDoc.exists) {
        _autoPlayAudioUrl = surahDoc.data()?['audioUrl'] ?? '';
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('quransurahs_details')
          .doc(widget.surahId)
          .collection('ayahs')
          .orderBy('number')
          .get();

      final data = snapshot.docs.map((e) => Ayah.fromMap(e.data())).toList();

      // Debug print to check fetched data
      print('Fetched ayahs count: ${data.length}');
      print('First ayah data: ${data.isNotEmpty ? data[0].arabic : "No ayah"}');

      setState(() {
        _ayahs = data;
        _ayahKeys = List.generate(_ayahs.length, (_) => GlobalKey());
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading surah data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  void _highlightAndScrollToAyah(int index) {
    setState(() {
      _currentAyahIndex = index;
    });
    final context = _ayahKeys[index].currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
  }

  Future<void> _playAyah(Ayah ayah, int index) async {
    try {
      await _player.setUrl(ayah.audioUrl);
      await _player.play();
      _highlightAndScrollToAyah(index);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_isAutoPlaying && index + 1 < _ayahs.length) {
            _playAyah(_ayahs[index + 1], index + 1);
          } else {
            setState(() {
              _isAutoPlaying = false;
              _currentAyahIndex = -1;
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  Future<void> _startAutoPlay() async {
    if (_ayahs.isEmpty) return;
    setState(() => _isAutoPlaying = true);
    await _playAyah(_ayahs[0], 0);
  }

  @override
  void dispose() {
    _player.dispose();
    _scrollController.dispose();
    _marqueeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ayahs.isEmpty
          ? const Center(child: Text('No ayahs found.'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _ayahs.length,
              itemBuilder: (context, index) {
                final ayah = _ayahs[index];
                final showSurahTitle = (index == 0 || ayah.surahNumber != _ayahs[index - 1].surahNumber) && widget.surahId == 'chapter_01';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      key: _ayahKeys[index],
                      color: _currentAyahIndex == index ? Colors.teal.shade50 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildArabicAyahImage(ayah, height: 110),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                ayah.urdu,
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: _fontSizeUrdu,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'JameelNooriNastaleeq',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ayah.translation,
                              style: TextStyle(
                                fontSize: _fontSizeTranslation,
                                fontWeight: FontWeight.w500,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ayah.transliteration,
                              style: TextStyle(
                                fontSize: _fontSizeTransliteration,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  iconSize: 36,
                                  color: Colors.teal,
                                  icon: Icon(
                                    _currentAyahIndex == index && _player.playing ? Icons.pause_circle : Icons.play_circle,
                                  ),
                                  onPressed: () {
                                    if (_currentAyahIndex == index && _player.playing) {
                                      _player.pause();
                                    } else {
                                      _playAyah(ayah, index);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            height: 55,
            width: double.infinity,
            color: Colors.teal.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  color: Colors.teal,
                  icon: Icon(
                    _isAutoPlaying && _player.playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  ),
                  onPressed: () {
                    if (_isAutoPlaying && _player.playing) {
                      _player.pause();
                    } else {
                      _startAutoPlay();
                    }
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Play Surah Audio",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          if (_marqueeText.isNotEmpty)
            Container(
              height: 40,
              width: double.infinity,
              color: Colors.black,
              child: Marquee(
                text: _marqueeText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                blankSpace: 80.0,
                velocity: 50.0,
                pauseAfterRound: const Duration(seconds: 1),
              ),
            ),
        ],
      ),
    );
  }
}
