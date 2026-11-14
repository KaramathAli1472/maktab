import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../quran_digital/quran_screen.dart';
import 'surah_detail_screen.dart';

class QuranMenuScreen extends StatefulWidget {
  const QuranMenuScreen({super.key});

  @override
  State<QuranMenuScreen> createState() => _QuranMenuScreenState();
}

class _QuranMenuScreenState extends State<QuranMenuScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Separate search queries for Surah and Juz tabs
  String surahSearchQuery = "";
  String juzSearchQuery = "";

  @override
  void initState() {
    super.initState();
    debugPrint('[QURAN_JUZ] Quran menu opened');
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quran"),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            debugPrint('[QURAN_JUZ] Selected tab: ${index == 1 ? 'Juz' : 'Surah'}');
          },
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 20),
          labelPadding: const EdgeInsets.symmetric(horizontal: 44),
          tabs: const [
            Tab(text: "Surah"),
            Tab(text: "Juz"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Surah Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by Surah name...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (val) => setState(() => surahSearchQuery = val),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("quransurahs")
                      .orderBy("order")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading Surahs"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    final lower = surahSearchQuery.toLowerCase();
                    final surahs = docs
                        .map((doc) => {
                      "id": doc.id,
                      ...((doc.data() as Map<String, dynamic>? ?? {})),
                    })
                        .where((s) {
                      final name = (s["english"] as String? ?? "").toLowerCase();
                      return lower.isEmpty ? true : name.contains(lower);
                    })
                        .toList();
                    if (surahs.isEmpty) {
                      return const Center(child: Text("No Surahs Found"));
                    }
                    return ListView.builder(
                      itemCount: surahs.length,
                      itemBuilder: (context, index) {
                        final surah = surahs[index];
                        final numberText = surah["number"]?.toString() ?? "";
                        final english = surah["english"] as String? ?? "";
                        final origin = surah["origin"] as String? ?? "";
                        final count = surah["count"]?.toString() ?? "";
                        final arabic = surah["arabic"] as String? ?? "";
                        final surahIdFromChapter = surah['chapter'] ?? '';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                numberText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              english,
                              style: const TextStyle(fontSize: 17),
                            ),
                            subtitle: Text("$origin | $count"),
                            trailing: Text(
                              arabic,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'ScheherazadeNew',
                                fontSize: 28,
                              ),
                            ),
                            onTap: () {
                              debugPrint('Navigating to SurahDetailScreen with surahId: $surahIdFromChapter');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurahDetailScreen(
                                    title: english,
                                    description: origin,
                                    detailsID: numberText,
                                    chapter: arabic,
                                    surahId: surahIdFromChapter,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Juz Tab
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search by Juz name...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (val) => setState(() => juzSearchQuery = val),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("juz")    // Yahan Firestore collection ka sahi naam dalein
                      .orderBy("order")     // "order" field ka istemal ho raha hai
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Firestore error in Juz Tab: ${snapshot.error}');
                      return const Center(child: Text("Error loading Juz"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint('Waiting for Juz data...');
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data?.docs ?? [];
                    debugPrint('Total Juz docs fetched: ${docs.length}');
                    final lower = juzSearchQuery.toLowerCase();
                    final juzs = docs
                        .map((doc) => {
                      "id": doc.id,
                      ...((doc.data() as Map<String, dynamic>? ?? {})),
                    })
                        .where((s) {
                      final name = (s["english"] as String? ?? "").toLowerCase();
                      final match = lower.isEmpty ? true : name.contains(lower);
                      if (!match) {
                        debugPrint('Filtered out Juz: ${s["english"]}');
                      }
                      return match;
                    })
                        .toList();
                    debugPrint('Juz docs after filtering: ${juzs.length}');
                    if (juzs.isEmpty) {
                      return const Center(child: Text("No Juz Found"));
                    }
                    return ListView.builder(
                      itemCount: juzs.length,
                      itemBuilder: (context, index) {
                        final juz = juzs[index];
                        final numberText = juz["juz_number"]?.toString() ?? "";
                        final english = juz["english"] as String? ?? "";
                        final arabic = juz["arabic"] as String? ?? "";
                        final origin = juz["origin"] as String? ?? "";
                        final count = juz["count"]?.toString() ?? "";
                        final juzIdFromChapter = juz['chapter'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal,
                              child: Text(
                                numberText,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              english,
                              style: const TextStyle(fontSize: 17),
                            ),
                            subtitle: (origin.isNotEmpty || count.isNotEmpty)
                                ? Text(
                              origin.isNotEmpty && count.isNotEmpty
                                  ? "$origin | $count"
                                  : origin + count,
                            )
                                : null,
                            trailing: Text(
                              arabic,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'ScheherazadeNew',
                                fontSize: 28,
                              ),
                            ),
                            onTap: () {
                              debugPrint('[QURAN_JUZ] Selected Juz: $english, id: $juzIdFromChapter');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuranScreen(
                                    title: english,
                                    description: origin,
                                    detailsID: numberText,
                                    chapter: arabic,
                                    surahId: juzIdFromChapter,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}