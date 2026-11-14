// ✅ Full working code for AwardsPage with MarqueeBar

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';

import '../marquee_bar/marquee_bar.dart';


class AwardsPage extends StatefulWidget {
  const AwardsPage({Key? key}) : super(key: key);

  @override
  State<AwardsPage> createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  List<dynamic> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('awards_items')
          .doc('awards_doc')
          .get();

      if (doc.exists) {
        setState(() {
          images = doc.get('images') ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          images = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        images = [];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (images.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No images found")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Awards & Certificates")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 30), // space for marquee
            child: PageView.builder(
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.black,
                  child: PhotoView(
                    imageProvider: NetworkImage(images[index]),
                    backgroundDecoration: const BoxDecoration(color: Colors.black),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    enableRotation: false,
                  ),
                );
              },
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MarqueeBar(),
          ),
        ],
      ),
    );
  }
}
