import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';
import 'package:photo_view/photo_view.dart';

class Nahajulbalagha_bookScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const Nahajulbalagha_bookScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _Nahajulbalagha_bookScreenState createState() => _Nahajulbalagha_bookScreenState();
}

class _Nahajulbalagha_bookScreenState extends State<Nahajulbalagha_bookScreen> {
  int _highlightedIndex = 0;
  List<String> _imageUrls = [];
  String _marqueeText = "";
  bool _dataLoaded = false;

  late Future<void> _loadDataFuture;
  late PageController _pageController;
  int _currentPage = 0;

  final TextEditingController _pageInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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

  void _jumpToPage(String input) {
    final int? page = int.tryParse(input);
    if (page != null && page > 0 && page <= _imageUrls.length) {
      _pageController.jumpToPage(page - 1);
      FocusScope.of(context).unfocus(); // hide keyboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid page number")),
      );
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

  @override
  void dispose() {
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

                  // PageView
                  SizedBox(
                    height: 530, // 👈 adjust height here
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openFullScreenImage(_imageUrls[index]),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 👈 thoda kam spacing
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _highlightedIndex == index ? Colors.green : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: _highlightedIndex == index
                                  ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 1,
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

                  // 👇 Go to Page Field + Page Indicator (NEECHE LAYA GAYA)
                  if (_imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${_currentPage + 1} of ${_imageUrls.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              ),
                              onSubmitted: _jumpToPage,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40), // spacing before marquee
                ],
              ),

              // 🔽 Marquee at the bottom
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
