import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import '../marquee_bar/marquee_bar.dart';

class QasidaScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const QasidaScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _QasidaScreenState createState() => _QasidaScreenState();
}

class _QasidaScreenState extends State<QasidaScreen> {
  int _highlightedIndex = 0;
  List<String> _imageUrls = [];
  bool _dataLoaded = false;

  late Future<void> _loadDataFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _pageInputController = TextEditingController();

  // 24 items ke page numbers (1-based).
  // Sirf YAHI LIST me numbers change karne hain.
  final List<int> itemPages = [
    3,  // index 1  -> page 3
    4,  // index 2  -> page 4
    5,  // index 3  -> page 5
    6,  // index 4  -> page 6
    7,  // index 5  -> page 7
    8,  // index 6  -> page 8
    9,  // index 7  -> page 9
    10, // index 8  -> page 10
    11, // index 8
    12, // index 9
    13, // index 10
    14, // index 11
    15, // index 12
    16, // index 13
    17, // index 14
    18, // index 15
    19, // index 16
    20, // index 17
    21, // index 18
    22, // index 19
    23, // index 20
    24, // index 21
    25, // index 22
    26, // index 23
  ];

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadData();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
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

  void _jumpToPage() {
    final input = _pageInputController.text.trim();
    final page = int.tryParse(input);

    if (page != null && page >= 1 && page <= _imageUrls.length) {
      _pageController.jumpToPage(page - 1);
      FocusScope.of(context).unfocus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Enter a valid page number (1 - ${_imageUrls.length})",
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageInputController.dispose();
    super.dispose();
  }

  Widget _buildPageContainer(Widget child, int index) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: _highlightedIndex == index ? Colors.green : Colors.transparent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: _highlightedIndex == index
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: child,
      ),
    );
  }

  // Rectangular tappable area
  Widget _menuHotspot({
    required double left,
    required double top,
    required double width,
    required double height,
    required int targetPageIndex, // 0-based
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('HOTSPOT TAP -> index $targetPageIndex');
          if (targetPageIndex >= 0 &&
              targetPageIndex < _imageUrls.length) {
            _pageController.jumpToPage(targetPageIndex);
          }
        },
        child: const SizedBox.expand(),
      ),
    );
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        const double rowHeight = 40.0;
                        const double rowGap = 10.0;
                        const double startTop = 40.0;

                        return PageView.builder(
                          controller: _pageController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _imageUrls.length,
                          itemBuilder: (context, index) {
                            final baseImage = Image.network(
                              _imageUrls[index],
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            );

                            // First page: 24 menu items with mapping
                            if (index == 0) {
                              final List<Widget> children = [
                                Positioned.fill(child: baseImage),
                              ];

                              for (int i = 0; i < itemPages.length; i++) {
                                final bool isRight = i < 12; // 0–11 right, 12–23 left
                                final int row = i % 12;
                                final double top =
                                    startTop + row * (rowHeight + rowGap);
                                final double left = isRight ? w / 2 : 0.0;

                                final int pageNumber = itemPages[i]; // 1-based
                                final int targetIndex =
                                    pageNumber - 1; // 0-based

                                children.add(
                                  _menuHotspot(
                                    left: left,
                                    top: top,
                                    width: w / 2,
                                    height: rowHeight,
                                    targetPageIndex: targetIndex,
                                  ),
                                );
                              }

                              return _buildPageContainer(
                                Stack(children: children),
                                index,
                              );
                            }

                            // Other pages: tap to open fullscreen
                            return GestureDetector(
                              onTap: () =>
                                  _openFullScreenImage(_imageUrls[index]),
                              child: _buildPageContainer(baseImage, index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_imageUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Page ${_currentPage + 1} of ${_imageUrls.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pageInputController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Enter Page Number ...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _jumpToPage,
                          child: const Text("Go"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
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

