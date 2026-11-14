import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'activity_view.dart';

class ActivityBookScreen extends StatefulWidget {
  const ActivityBookScreen({Key? key}) : super(key: key);

  @override
  State<ActivityBookScreen> createState() => _ActivityBookScreenState();
}

class _ActivityBookScreenState extends State<ActivityBookScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      final menuCollections = ['activitybookMenu', 'activity_book'];
      QuerySnapshot? snapshot;
      for (final collectionName in menuCollections) {
        snapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('order')
            .get();

        if (snapshot.docs.isNotEmpty) {
          break;
        }
      }

      final docs = snapshot?.docs ?? const [];
      final loadedItems = await Future.wait(docs.map((doc) async {
        final rawData = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
        final data = <String, dynamic>{'id': doc.id};
        data.addAll(rawData);

        final chapter = (data['chapter'] ?? '').toString();
        final detailsID = (data['detailsID'] ?? '').toString();

        if (chapter.isNotEmpty && detailsID.isNotEmpty) {
          final chapterDoc = await FirebaseFirestore.instance
              .collection(detailsID)
              .doc(chapter)
              .get();

          if (chapterDoc.exists) {
            final chapterData = chapterDoc.data() ?? {};
            final images = List<String>.from(chapterData['images'] ?? []);
            data['images'] = images;

            if ((data['image_url'] ?? '').toString().isEmpty && images.isNotEmpty) {
              data['image_url'] = images.first;
            }
          }
        }

        return data;
      }));

      setState(() {
        _items = loadedItems;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading activity book: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Book')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final title = item['title'] ?? 'Activity ${index + 1}';
            final chapterImages = List<String>.from(item['images'] ?? []);
            final imageUrl = (item['image_url'] ?? '').toString();
            final previewImageUrl = imageUrl.isNotEmpty
                ? imageUrl
                : (chapterImages.isNotEmpty ? chapterImages.first : '');

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityViewScreen(
                    activityIndex: 0,
                    totalActivities: chapterImages.isNotEmpty ? chapterImages.length : 1,
                    imageProvider: previewImageUrl.isNotEmpty
                        ? NetworkImage(previewImageUrl)
                        : const AssetImage('assets/image.png'),
                    imageUrls: chapterImages,
                  ),
                ),
              ),
              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child: previewImageUrl.isNotEmpty
                          ? Image.network(
                              previewImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                            )
                          : Image.asset(
                              'assets/image.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(title, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
