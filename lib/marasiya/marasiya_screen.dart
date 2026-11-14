import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:photo_view/photo_view.dart';

class MarasiyaScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const MarasiyaScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _MarasiyaScreenState createState() => _MarasiyaScreenState();
}

class _MarasiyaScreenState extends State<MarasiyaScreen> {
  int _highlightedIndex = 0;
  List<String> _imageUrls = [];
  String _marqueeText = "";
  bool _dataLoaded = false;

  late Future<void> _loadDataFuture;
  PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController _pageNumberController = TextEditingController(); // Added

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
    _pageController.addListener(() {
      int newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
          _highlightedIndex = newPage;
        });
      }
    });
  }

  Future<void> _loadData() async {
    if (!_dataLoaded) {
      try {
        final chapterDoc = FirebaseFirestore.instance
            .collection(widget.detailsID)
            .doc(widget.chapter);

        final docSnapshot = await chapterDoc.get();
        final data = docSnapshot.data() as Map<String, dynamic>? ?? {};

        final marqueeDoc = await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('global')
            .get();
        _marqueeText = marqueeDoc.data()?['marqueeText'] ?? '';

        setState(() {
          _imageUrls = List<String>.from(data["images"] ?? []);
          _dataLoaded = true;
        });
      } catch (e) {
        debugPrint("Error loading data: $e");
      }
    }
  }

  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              enableRotation: false,
            ),
          ),
        ),
      ),
    );
  }

  void _goToPage() {
    final input = _pageNumberController.text.trim();
    if (input.isNotEmpty) {
      final pageNumber = int.tryParse(input);
      if (pageNumber != null &&
          pageNumber > 0 &&
          pageNumber <= _imageUrls.length) {
        _pageController.jumpToPage(pageNumber - 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter valid page number between 1 and ${_imageUrls.length}'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageNumberController.dispose(); // Added
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
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openFullScreenImage(_imageUrls[index]),
                          child: Container(
                            margin: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _highlightedIndex == index
                                    ? Colors.green
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: _highlightedIndex == index
                                  ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                                  : [],
                            ),
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
                        );
                      },
                    ),
                  ),

                  if (_imageUrls.isNotEmpty)
                    Column(
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                            child: Text(
                              'Page ${_currentPage + 1} of ${_imageUrls.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pageNumberController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Enter page number',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _goToPage,
                                child: const Text('Go'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 50),
                ],
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

