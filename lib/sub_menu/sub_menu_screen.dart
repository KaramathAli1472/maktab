import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../adeebeasr/adeebeasr_screen.dart';
import '../aiwaneurdu/aiwaneurdu_screen.dart';
import '../akhlaq/akhlaq_screen.dart';
import '../amma_para/amma_details_screen.dart';
import '../amma_para/ammaparagraphics_screen.dart';
import '../amma_para/ammalogin_screen.dart';
import '../annualday/annualday_screen.dart';
import '../ayats/ayats_screen.dart';
import '../chahelhadees/chahelhadees_screen.dart';
import '../diniyat/deeniyat_screen.dart';
import '../diniyat/deeniyatlogin_screen.dart';
import '../diniyat/diniyatgraphics_screen.dart';
import '../dua/dua_screen.dart';
import '../gunahekabira/gunahekabira_screen.dart';
import '../historyofmasumeen/historyofmasumeen_screen.dart';
import '../islamicbooks/islamicbooks_screen.dart';
import '../marasiya/marasiya_screen.dart';
import '../nahajulbalaghabook/nahajulbalaghabook_screen.dart';
import '../nahajulbalaghabook/nahjulbalagha_screen.dart';
import '../namaz/namaz_screen.dart';
import '../namazforkids/namazforkids.dart';
import '../noorani_qaida/details_screen.dart';
import '../noorani_qaida/login_screen.dart';
import '../noorani_qaida/nooraniqaidagraphics_screen.dart';
import '../qasida/qasida_screen.dart';
import '../quiz/quiz_screen.dart';
import '../quran_pdf/quranpara_screen.dart';
import '../salam/salam_screen.dart';
import '../stories/stories_screen.dart';
import '../tahzibulIslam/tahzibulIslam_screen.dart';
import '../tauzeehulmasail/tauzeehulmasail_screen.dart';
import '../tohfatulawam/tohfatulawam_screen.dart';
import '../urdustan/urdustan_screen.dart';
import '../yassarnal/yassarnal_quran.dart';
import '../yassarnal/yassarnallogin_screen.dart';
import '../ziyarat/ziyarat_screen.dart';

class SubMenuScreen extends StatefulWidget {
  final String subMenuID;
  final String title;
  const SubMenuScreen({
    super.key,
    required this.subMenuID,
    required this.title,
  });

  @override
  State<SubMenuScreen> createState() => _SubMenuScreenState();
}

class _SubMenuScreenState extends State<SubMenuScreen> {
  bool userIsLoggedIn = false;

  void setUserLoggedIn(bool value) {
    setState(() {
      userIsLoggedIn = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CollectionReference subMenuCollection =
    FirebaseFirestore.instance.collection(widget.subMenuID);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: subMenuCollection.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items found'));
          }

          final subMenuItems = snapshot.data!.docs;
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView.builder(
              itemCount: subMenuItems.length,
              itemBuilder: (context, index) {
                var item = subMenuItems[index].data() as Map<String, dynamic>;
                String detailsID = item['detailsID'] ?? '';
                String chapter = item['chapter'] ?? '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: ListTile(
                    leading: SizedBox(
                      width: 30,
                      child: Text(
                        '${index + 1}.',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Text(
                      item['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      print('Tapped on item: ${item['title']}');

                      if (widget.subMenuID == 'ammaParaMenu' || widget.subMenuID == 'ammaParas') {
                        if (userIsLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmmaDetailsScreen(
                                title: item['title'] ?? 'No Title',
                                subtitle: item['subtitle'] ?? 'No Subtitle',
                                imageUrl: item['image_url'] ?? '',
                                description: item['description'] ?? 'No Description Available',
                                detailsID: detailsID,
                                chapter: chapter,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmmaLoginScreen(
                                item: item,
                                chapter: chapter,
                              ),
                            ),
                          );
                        }
                      }
                      else if (widget.subMenuID == 'deeniyatMenu' || widget.subMenuID == 'deeniyat') {
                        if (userIsLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeeniyatScreen(
                                title: item['title'] ?? 'No Title',
                                subtitle: item['subtitle'] ?? 'No Subtitle',
                                imageUrl: item['image_url'] ?? '',
                                description: item['description'] ?? 'No Description Available',
                                detailsID: detailsID,
                                chapter: chapter,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeeniyatLoginScreen(
                                item: item,
                                chapter: chapter,
                              ),
                            ),
                          );
                        }
                      } else if (widget.subMenuID == 'nahajulbalaghaMenu' || widget.subMenuID == 'nahjulbalagha') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NahjulBalaghaScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '',
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'nahajulbalaghabookMenu' || widget.subMenuID == 'nahajulbalaghabook') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Nahajulbalagha_bookScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'adeebeasrMenu' || widget.subMenuID == 'adeebeasr') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdeebeasrScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'tauzeehulmasailMenu' || widget.subMenuID == 'tauzeehulmasail') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TauzeehulmasailScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'yassarnal_quran_Menu' || widget.subMenuID == 'yassarnal_quran') {
                        if (userIsLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Yassarnal_quranScreen(
                                title: item['title'] ?? 'No Title',
                                subtitle: item['subtitle'] ?? 'No Subtitle',
                                imageUrl: item['image_url'] ?? '',
                                description: item['description'] ?? 'No Description Available',
                                detailsID: detailsID,
                                chapter: chapter,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => YassarnalLoginScreen( // 🔐 login screen like Amma Para
                                item: item,
                                chapter: chapter,
                              ),
                            ),
                          );
                        }
                      } else if (widget.subMenuID == 'islamicbooksMenu' || widget.subMenuID== 'islamicbooks') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IslamicbooksScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );

                      } else if (widget.subMenuID == 'annualdayMenu' || widget.subMenuID== 'annualday') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnnualdayScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'tahzibulIslamMenu' || widget.subMenuID== 'tahzibulIslam') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TahzibulIslamScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'gunahekabiraMenu' || widget.subMenuID== 'gunahekabira') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GunahekabiraScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'storiesMenu' || widget.subMenuID== 'stories') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoriesScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'quizMenu' || widget.subMenuID== 'quiz') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'chahelhadeesMenu' || widget.subMenuID== 'chahelhadees') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChahelhadeesScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'urdustanMenu' || widget.subMenuID== 'urdustan') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UrdustanScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'duasMenu' || widget.subMenuID== 'duas') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DuaDetailScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'ziyaratMenu' || widget.subMenuID== 'ziyarat') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ziyaratDetailScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'salamMenu' || widget.subMenuID== 'salam') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalamDetailScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'marasiyaMenu' || widget.subMenuID== 'marasiya') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MarasiyaScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'namazMenu' || widget.subMenuID== 'namaz') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NamazDetailScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'nooraniqaidagraphicsMenu' || widget.subMenuID== 'nooraniqaidagraphics') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NooraniqaidagraphicsScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'ammaparagraphicsMenu' || widget.subMenuID== 'ammaparagraphics') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AmmaparagraphicsScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'diniyatgraphicsMenu' || widget.subMenuID== 'diniyatgraphics') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DiniyatgraphicsScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'ayatsMenu' || widget.subMenuID== 'ayats') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AyatsScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'akhlaqMenu' || widget.subMenuID== 'akhlaq') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AkhlaqScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'quranparaMenu' || widget.subMenuID== 'quranpara') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranparaScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'historyofmasumeenMenu' || widget.subMenuID== 'historyofmasumeen') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryofmasumeenScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'tohfatulawamMenu' || widget.subMenuID== 'tohfatulawam') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TohfatulawamScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'aiwaneurduMenu' || widget.subMenuID== 'aiwaneurdu') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiwaneurduScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'qasidaMenu' || widget.subMenuID== 'qasida_details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QasidaScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'aamalMenu' || widget.subMenuID== 'aamal_rajabMenu') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranparaScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              imageUrl: item['image_url'] ?? '',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: detailsID,
                              chapter: chapter,
                            ),
                          ),
                        );
                      } else if (widget.subMenuID == 'namazforkidsMenu' || widget.subMenuID== 'namazforkids') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NamazForKidsScreen(
                              title: item['title'] ?? 'No Title',
                              subtitle: item['subtitle'] ?? 'No Subtitle',
                              description: item['description'] ?? 'No Description Available',
                              detailsID: item['detailsID'] ?? '', // ✅ Ensure detailsID is passed
                              chapter: chapter,
                            ),
                          ),
                        );

                      } else {
                        if (userIsLoggedIn) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailsScreen(
                                title: item['title'] ?? 'No Title',
                                subtitle: item['subtitle'] ?? 'No Subtitle',
                                imageUrl: item['image_url'] ?? '',
                                description: item['description'] ?? 'No Description Available',
                                detailsID: item['detailsID'] ?? '',
                                chapter: chapter,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                item: item,
                                chapter: chapter,
                              ),
                            ),
                          );
                        }
                      }
                    },
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
