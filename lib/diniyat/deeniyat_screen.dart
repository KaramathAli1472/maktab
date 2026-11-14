import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:photo_view/photo_view.dart';

class DeeniyatScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const DeeniyatScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _DeeniyatScreenState createState() => _DeeniyatScreenState();
}

class _DeeniyatScreenState extends State<DeeniyatScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _pageInputController = TextEditingController();

  int _highlightedIndex = 0;
  List<String> _audioUrls = [];
  List<String> _imageUrls = [];
  String _marqueeText = "";
  bool _isPlaying = false;
  bool _dataLoaded = false;
  late Future<void> _loadDataFuture;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _highlightedIndex) {
        setState(() {
          _highlightedIndex = newPage;
        });
      }
    });
    _loadDataFuture = _loadData();
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      final DocumentReference chapterDoc = FirebaseFirestore.instance
          .collection(widget.detailsID)
          .doc(widget.chapter);
      try {
        final chapterData =
            (await chapterDoc.get()).data() as Map<String, dynamic>? ?? {};
        _imageUrls = List<String>.from(chapterData["images"] ?? []);
        _audioUrls = List<String>.from(chapterData["audio"] ?? []);

        final marqueeDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .get();
        _marqueeText = marqueeDoc.data()?['marqueeText'] ?? "";

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

    setState(() {
      _highlightedIndex = index;
      _isPlaying = true;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(_audioUrls[index]);
      await _audioPlayer.play();

      await _audioPlayer.processingStateStream
          .firstWhere((state) => state == ProcessingState.completed);

      await Future.delayed(const Duration(milliseconds: 500));

      if (fromButton) {
        int nextIndex = (index + 1) % _audioUrls.length;
        _playAudio(nextIndex, fromButton: true);
      } else {
        setState(() {
          _isPlaying = false;
        });
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _toggleAudio() {
    if (_isPlaying) {
      _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } else {
      _playAudio(_highlightedIndex >= 0 ? _highlightedIndex : 0, fromButton: true);
    }
  }

  void _jumpToPage(String input) {
    final int? page = int.tryParse(input);
    if (page != null && page > 0 && page <= _imageUrls.length) {
      _pageController.jumpToPage(page - 1);
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid page number")),
      );
    }
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    _pageInputController.dispose();
    super.dispose();
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
                  // 🔻 Minimized top image section to push content up
                  if (widget.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.imageUrl,
                        width: double.infinity,
                        height: 100, // Reduced height
                        fit: BoxFit.cover,
                      ),
                    ),
                  // 🔻 PageView is now closer to top
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _openFullScreenImage(_imageUrls[index]);
                            _playAudio(index, fromButton: true);
                          },
                          onDoubleTap: () {
                            _playAudio(index, fromButton: true);
                          },
                          child: Container(
                            margin: const EdgeInsets.all(22.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _highlightedIndex == index
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                _imageUrls[index],
                                fit: BoxFit.fill,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 🔻 Go to page control
                  if (_imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${_highlightedIndex + 1} of ${_imageUrls.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _pageInputController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: "Go to page",
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () => _jumpToPage(_pageInputController.text),
                                ),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding:
                                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                              onSubmitted: _jumpToPage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),

              // 🔻 Audio control
              if (_audioUrls.isNotEmpty)
                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
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

              // 🔻 Marquee
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
