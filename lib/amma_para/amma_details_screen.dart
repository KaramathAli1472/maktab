import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

import '../marquee_bar/marquee_bar.dart';

class AmmaDetailsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const AmmaDetailsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _AmmaDetailsScreenState createState() => _AmmaDetailsScreenState();
}

class _AmmaDetailsScreenState extends State<AmmaDetailsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {}; // 🟢 New: Key mapping

  int _highlightedIndex = -1;
  List<String> _audioUrls = [];
  List<String> _imageUrls = [];
  String _marqueeText = "";
  bool _isPlaying = false;
  int _currentAudioIndex = -1;
  bool _dataLoaded = false;
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      final DocumentReference chapterDoc = FirebaseFirestore.instance
          .collection(widget.detailsID)
          .doc(widget.chapter);

      try {
        var chapterData =
            (await chapterDoc.get()).data() as Map<String, dynamic>? ?? {};

        _imageUrls = List<String>.from(chapterData["images"] ?? []);
        _audioUrls = List<String>.from(chapterData["audio"] ?? []);
        _marqueeText = chapterData["marqueeText"] ?? "";
        setState(() {
          _dataLoaded = true;
        });
      } catch (e) {
        debugPrint("Error loading data: $e");
      }
    }
  }

  Future<void> _playAudio(int index, {bool fromButton = false}) async {
    if (!mounted || index >= _audioUrls.length) return;

    if (fromButton) {
      _currentAudioIndex = 0;
    } else {
      _currentAudioIndex = index;
    }

    setState(() {
      _highlightedIndex = index;
      _isPlaying = true;
    });

    _scrollToHighlighted(index);

    try {
      // Ensure previous audio is stopped before starting new one
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(_audioUrls[index]);
      await _audioPlayer.play();

      // Debugging: Print when audio starts
      debugPrint('Playing audio at index: $index');

      // Track audio position (for debugging purposes)
      _audioPlayer.positionStream.listen((position) {
        debugPrint("Current position: $position");
      });

      // Wait for audio to complete
      await _audioPlayer.processingStateStream.firstWhere(
            (state) => state == ProcessingState.completed,
      );

      debugPrint('Audio at index $index completed');

      // Optional: add delay to ensure smooth transition
      await Future.delayed(const Duration(milliseconds: 500));

      // Play next audio if required
      if (mounted && fromButton) {
        if (index + 1 < _audioUrls.length) {
          // Play next audio
          _playAudio(index + 1, fromButton: true);
        } else {
          setState(() {
            _isPlaying = false;
          });
        }
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _toggleAudio() {
    if (_isPlaying) {
      _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _playAudio(0, fromButton: true);
    }
  }

  void _scrollToHighlighted(int index) {
    if (index < 3 || !_itemKeys.containsKey(index)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemContext = _itemKeys[index]!.currentContext;
      final listContext = _scrollController.position.context.storageContext;

      if (itemContext != null &&
          listContext != null &&
          _scrollController.hasClients) {
        final itemBox = itemContext.findRenderObject() as RenderBox;
        final listBox = listContext.findRenderObject() as RenderBox;

        final itemOffset =
            itemBox.localToGlobal(Offset.zero, ancestor: listBox).dy;

        final targetScroll = _scrollController.offset + itemOffset - 16;

        // ✅ Clamp the scroll to prevent jumpiness at the end
        final maxScroll = _scrollController.position.maxScrollExtent;
        final safeScroll = targetScroll.clamp(0.0, maxScroll);

        _scrollController.animateTo(
          safeScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!_dataLoaded) {
            return const Center(child: Text('Data not found.'));
          }

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (widget.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            // ✅ 1. childAspectRatio hata diya hai
                            // ✅ 2. mainAxisExtent add kiya hai taake 2 line wali image bhi fit ho
                            mainAxisExtent: 140, 
                          ),
                          itemCount: _imageUrls.length,
                          itemBuilder: (context, index) {
                            _itemKeys.putIfAbsent(index, () => GlobalKey());

                            return KeyedSubtree(
                              key: _itemKeys[index],
                              child: GestureDetector(
                                onTap: () => _playAudio(index),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _highlightedIndex == index
                                          ? Colors.white
                                          : Colors.black,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12.0),
                                    boxShadow: _highlightedIndex == index
                                        ? [
                                      BoxShadow(
                                        color: const Color.fromARGB(
                                            255, 213, 235, 163)
                                            .withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                        : [],
                                  ),
                                  // ✅ 3. SizedBox(height: 120) hata diya hai
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      _imageUrls[index],
                                      fit: BoxFit.contain, // Image box ke andar fit hogi
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
              if (_audioUrls.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 4,
                  right: 4,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      size: 30,
                      color: Colors.black,
                    ),
                    label: Text(
                      _isPlaying ? "Pause Audio" : "Play Audio",
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    onPressed: _toggleAudio,
                  ),
                ),
              const Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: MarqueeBar(
                  height: 40,
                  backgroundColor: Colors.black,
                  textStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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