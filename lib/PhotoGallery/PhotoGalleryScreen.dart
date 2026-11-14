import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import '../marquee_bar/marquee_bar.dart';


class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({Key? key}) : super(key: key);

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<Map<String, dynamic>> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('photogallery_items')
          .doc('photogallery_doc')
          .get();

      print("📄 Document exists: ${doc.exists}");
      if (doc.exists) {
        final List fetchedList = doc.get('images') ?? [];
        print("🖼️ Fetched Images List: $fetchedList"); // ✅ Add this

        final formattedList = fetchedList
            .whereType<Map<String, dynamic>>()
            .map((e) => {
          'url': e['url'] ?? '',
          'caption': e['caption'] ?? '',
        })
            .toList();

        print("✅ Formatted List: $formattedList"); // ✅ Add this

        setState(() {
          images = formattedList;
          isLoading = false;
        });
      } else {
        print("⚠️ Document not found!");
        setState(() {
          images = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading images: $e");
      setState(() {
        images = [];
        isLoading = false;
      });
    }
  }

  void _openFullScreenImage(BuildContext context, Map<String, dynamic> image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text("Photo Gallery", style: TextStyle(color: Colors.white)),
          ),
          body: Stack(
            children: [
              PhotoView(
                imageProvider: NetworkImage(image['url']),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
              ),
              if ((image['caption'] ?? '').isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.black54,
                    child: Text(
                      image['caption'],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Photo Gallery"),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : images.isEmpty
            ? const Center(child: Text("No images found"))
            : Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return GestureDetector(
                    onTap: () => _openFullScreenImage(context, image),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image['url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30), // space for marquee
          ],
        ),
      ),
      bottomSheet: const SizedBox(
        height: 30,
        child: MarqueeBar(),
      ),
    );
  }
}
