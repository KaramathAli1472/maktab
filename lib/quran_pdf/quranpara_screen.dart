import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:marquee/marquee.dart';

class QuranparaScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String detailsID;
  final String chapter;
  final String description;

  const QuranparaScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.detailsID,
    required this.chapter,
    required this.description,
  });

  @override
  State<QuranparaScreen> createState() => _QuranparaScreenState();
}

class _QuranparaScreenState extends State<QuranparaScreen> {
  String _localFilePath = '';
  bool _dataLoaded = false;
  bool _pdfReady = false;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  String _marqueeText = "";

  final TextEditingController _pageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final DocumentReference chapterDoc = FirebaseFirestore.instance
        .collection(widget.detailsID)
        .doc(widget.chapter);

    try {
      var chapterData =
          (await chapterDoc.get()).data() as Map<String, dynamic>? ?? {};
      final pdfUrl = chapterData["pdfUrl"] ?? '';

      if (pdfUrl.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp.pdf');
        final response = await Dio().download(pdfUrl, file.path);
        if (response.statusCode == 200) {
          setState(() {
            _localFilePath = file.path;
            _dataLoaded = true;
            _marqueeText =
                chapterData["marqueeText"] ?? "Welcome to Quran Reader";
          });
        }
      } else {
        setState(() {
          _dataLoaded = true;
          _localFilePath = '';
          _marqueeText = "PDF URL not found.";
        });
      }
    } catch (e) {
      debugPrint("Error loading PDF data: $e");
      setState(() {
        _dataLoaded = true;
        _localFilePath = '';
        _marqueeText = "Failed to load PDF.";
      });
    }
  }

  void _jumpToPage(String input) {
    final page = int.tryParse(input);
    if (page != null && page > 0 && page <= _totalPages) {
      _pdfViewController?.setPage(page - 1);
      FocusScope.of(context).unfocus(); // hide keyboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid page number")),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: !_dataLoaded
          ? const Center(child: CircularProgressIndicator())
          : _localFilePath.isEmpty
          ? const Center(child: Text("PDF not found."))
          : Column(
        children: [
          // PDF View
          Expanded(
            child: PDFView(
              filePath: _localFilePath,
              enableSwipe: true,
              swipeHorizontal: true,
              autoSpacing: false,
              pageFling: true,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _pdfReady = true;
                });
                if (_pdfViewController != null && _totalPages > 0) {
                  _pdfViewController!.setPage(0);
                }
              },
              onViewCreated: (controller) {
                _pdfViewController = controller;
              },
              onPageChanged: (page, _) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              },
            ),
          ),

          // Page Controls (Above Marquee)
          if (_pdfReady)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pdfViewController!
                            .setPage(_currentPage - 1);
                      }
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (_currentPage < _totalPages - 1) {
                        _pdfViewController!
                            .setPage(_currentPage + 1);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 36,
                    child: TextField(
                      controller: _pageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Page',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: _jumpToPage,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () =>
                        _jumpToPage(_pageController.text),
                    child: const Text("Go"),
                  ),
                ],
              ),
            ),

          // Marquee (bottom)
          if (_marqueeText.isNotEmpty)
            Container(
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
        ],
      ),
    );
  }
}
