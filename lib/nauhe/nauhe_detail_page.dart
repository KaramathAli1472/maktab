import 'package:flutter/material.dart';

class NauhaDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  // Constructor to accept the item data (from Firebase)
  NauhaDetailPage({required this.item});

  @override
  Widget build(BuildContext context) {
    // Print the entire item data for debugging
    print('Item data: $item');

    return Scaffold(
      appBar: AppBar(
        title: Text(item['title'] ?? 'No Title'), // Show title if available
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0), // Padding around the content
        child: ListView(
          children: [
            // Title of the item
            Text(
              item['title'] ?? 'No Title',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6), // Space between title and description

            // Description of the item (if available)
            Text(
              'Description: ${item['description'] ?? 'No description available'}', // More user-friendly fallback
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 6), // Space between description and image

            // Show the image if available
            item['image_url'] != null && item['image_url'].isNotEmpty
                ? Image.network(
              item['image_url'],
              errorBuilder: (context, error, stackTrace) {
                return Center(child: Text("Failed to load image"));
              },
            )
                : Center(child: Text("No image available")), // More user-friendly fallback
          ],
        ),
      ),
    );
  }
}
