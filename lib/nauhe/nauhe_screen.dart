import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'anjuman_screen.dart';

class NauhaMenuPage extends StatefulWidget {
  @override
  _NauhaMenuPageState createState() => _NauhaMenuPageState();
}

class _NauhaMenuPageState extends State<NauhaMenuPage> {
  List<Map<String, dynamic>> menuItems = [];

  @override
  void initState() {
    super.initState();
    fetchMenuItems();
  }

  // Fetch main menu items from Firebase
  fetchMenuItems() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('nauheMenu') // ✅ CORRECT
          .orderBy('order')
          .get();

      setState(() {
        menuItems = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });

      print("✅nauheMenu loaded: ${menuItems.length} items");
    } catch (e) {
      print("❌ Error fetching NauheMenu: $e");
    }
  }

  // Fetch sub-menu items and navigate to a new page
  fetchSubMenuItems(String subMenuId) async {
    if (subMenuId.isEmpty) {
      print("❌ Invalid subMenuId: $subMenuId");
      return;
    }

    try {
      print("Fetching sub-menu for subMenuId: $subMenuId");

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection(subMenuId)
          .orderBy('order')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("❌ No sub-menu items found for subMenuId: $subMenuId");
      }

      List<Map<String, dynamic>> fetchedItems = querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      print("✅ SubMenu loaded: ${fetchedItems.length} items");

      // Navigate to SubMenuPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubMenuPage(
            subMenuTitle: subMenuId,
            items: fetchedItems,
          ),
        ),
      );
    } catch (e) {
      print("❌ Error fetching SubMenu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nauhe Menu ")),
      body: menuItems.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          var item = menuItems[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              title: Text(
                '${index + 1}. ${item['title'] ?? 'No Title'}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                String subMenuId = item['subMenuID'] ?? '';
                print("Tapped on item with subMenuId: $subMenuId");
                if (subMenuId.isNotEmpty) {
                  fetchSubMenuItems(subMenuId);
                } else {
                  print("❌ Invalid subMenuId: $subMenuId");
                }
              },
            ),
          );
        },
      ),
    );
  }
}

// 🆕 SubMenuPage Class with stylish numbered list
class SubMenuPage extends StatelessWidget {
  final String subMenuTitle;
  final List<Map<String, dynamic>> items;

  SubMenuPage({required this.subMenuTitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subMenuTitle)),
      body: items.isEmpty
          ? Center(child: Text("No items found."))
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.0),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 18.0),
              dense: true, // ✅ Less vertical height
              title: Text(
                '${index + 1}. ${item['title'] ?? 'No Title'}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                item['subtitle'] ?? 'No Subtitle', // Add subtitle here
                style: TextStyle(
                  fontSize: 16.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                String chapter = item['docID'] ?? ''; // `docID` Firebase document ID hai

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnjumanScreen(
                      title: item['title'] ?? '',
                      subtitle: item['subtitle'] ?? '', // Passing subtitle
                      detailsID: item['detailsID'] ?? '',
                      chapter: item['chapter'] ?? '', // 🔧 Add null safety
                      description: item['description'] ?? '',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
