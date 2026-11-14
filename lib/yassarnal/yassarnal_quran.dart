import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class Yassarnal_quranScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const Yassarnal_quranScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _Yassarnal_quranScreenState createState() => _Yassarnal_quranScreenState();
}

class _Yassarnal_quranScreenState extends State<Yassarnal_quranScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};

  int _highlightedIndex = -1;
  List<String> _audioUrls = [];
  List<String> _imageUrls = [];
  String _marqueeText = "";
  String _heading = "";
  String _subtitle = "";
  String _instructionText = "";
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
        var snapshot = await chapterDoc.get();
        var chapterData = snapshot.data() as Map<String, dynamic>?;

        if (chapterData == null) return;

        _imageUrls = List<String>.from(chapterData["images"] ?? []);
        _audioUrls = List<String>.from(chapterData["audio"] ?? []);
        final marqueeDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .get();

        _marqueeText = marqueeDoc.data()?['marqueeText'] ?? "";

        _subtitle = chapterData["subtitle"] ?? "";
        _instructionText = chapterData["text"] ?? "";

        if (chapterData["heading"] != null && chapterData["heading"] is Map) {
          Map<String, dynamic> headingMap = Map<String, dynamic>.from(chapterData["heading"]);
          _heading = headingMap["title"] ?? "";
          _instructionText = headingMap["text"] ?? "";
        }

        setState(() {
          _dataLoaded = true;
        });
      } catch (e) {
        debugPrint("🚨 Error loading data: $e");
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
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(_audioUrls[index]);
      await _audioPlayer.play();

      await _audioPlayer.processingStateStream.firstWhere(
              (state) => state == ProcessingState.completed);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && fromButton) {
        if (index + 1 < _audioUrls.length) {
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
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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

                  // Heading
                  if (_heading.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _heading,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                  // Subtitle
                  if (_subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Text(
                        _subtitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),

                  // 🟢 Instruction Text only in Portrait
                  if (_instructionText.isNotEmpty && !isLandscape)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 100,
                        child: SingleChildScrollView(
                          child: Text(
                            _instructionText,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.3,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),

                  if (widget.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 100,
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
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 1.8,
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
                                  child: SizedBox(
                                    height: 120,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        _imageUrls[index],
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
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
              if (_marqueeText.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    color: Colors.black,
                    child: Marquee(
                      text: _marqueeText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      scrollAxis: Axis.horizontal,
                      blankSpace: 50.0,
                      velocity: 50.0,
                      pauseAfterRound: const Duration(seconds: 1),
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
