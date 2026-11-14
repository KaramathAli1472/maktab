import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import '../marquee_bar/marquee_bar.dart';


class AiwaneurduScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const AiwaneurduScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  _AiwaneurduScreenState createState() => _AiwaneurduScreenState();
}

class _AiwaneurduScreenState extends State<AiwaneurduScreen> {
  int _highlightedIndex = 0;
  List<String> _imageUrls = [];
  bool _dataLoaded = false;

  late Future<void> _loadDataFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _pageInputController = TextEditingController();

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
        SnackBar(content: Text("Enter a valid page number (1 - ${_imageUrls.length})")),
      );
    }
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
                                )
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

              // ✅ Global Marquee from Firestore (bottom aligned)
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
