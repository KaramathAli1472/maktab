import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Introduction')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ------------------ ENGLISH CONTENT ------------------
            Text(
              'English Version',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),

            _buildSection('Introduction',
                '👉 Maktab-e-Sidratul Muntaha is a distinguished Shia Islamic educational institution dedicated to nurturing young minds with the light of Islamic knowledge, values, and spirituality.'),
            _buildSection('Registered',
                '👉 Formally registered as Maktab-e-Sidratul Muntaha Private Limited on July 24, 2020, the organization is headquartered in Hyderabad, Telangana, India.'),
            _buildSection('Global Community',
                '👉 The Maktab caters to a diverse and growing student community from countries including India, Canada, the United Kingdom, the United States, Tanzania, the United Arab Emirates, and Oman, among others.'),
            _buildSection('Curriculum',
                '👉 The curriculum is thoughtfully designed to include: Quranic Studies, Islamic History, Akhlaq (Moral Education), Arabic Language, Daily Duas & Practices, and Islamic Storytelling and Lessons from the Lives of Masoomeen (a.s).'),
            _buildSection('Digital Outreach',
                '👉 Alongside formal classes, the Maktab actively engages in digital outreach through platforms like YouTube and Facebook, offering content such as Quran recitations, Majalis, Islamic story sessions, and audiobooks of important Islamic texts like Tahzeeb-ul-Islam and Gunaah-e-Kabira.'),
            _buildSection('Team',
                '👉 With a team of qualified teachers and scholars, Maktab-e-Sidratul Muntaha is not just an educational space — it\'s a spiritual journey for every student. It aims to build a strong foundation of faith, character, and community among children through regular classes, interactive sessions, and values-based education.'),
            _buildSection('1. Curriculum & Courses',
                '👉 The institution provides a structured curriculum covering Quranic studies, Islamic history, moral education, and Arabic language studies. Courses are tailored to various age groups and proficiency levels to ensure a personalized learning experience.'),
            _buildSection('2. Digital Outreach',
                '👉 Leveraging modern technology, Maktab-e-Sidratul Muntaha uses platforms such as Facebook and YouTube to share educational content, updates, and interactive resources. Its YouTube channel features a variety of playlists, including Quranic recitations, Islamic storytelling, Majalis, and audiobook versions of texts like Tahzeeb-ul-Islam and Gunaah-e-Kabira.'),
            _buildSection('3. Community Engagement',
                '👉 The organization actively connects with its audience through social media platforms and annual events. Its recent 5th Annual Day celebration in April 2025 showcased student achievements and highlighted the institution’s ongoing commitment to excellence in Islamic education.'),
            _buildSection('4. Local Impact',
                '👉 In Hyderabad, Maktab-e-Sidratul Muntaha serves the local community through its online school located in the Noor Khan Bazar, Hyderabad, offering a blend of traditional and contemporary Islamic education.'),
            _buildSection('Mission',
                '👉 The mission of Maktab-e-Sidratul Muntaha is to build a strong foundation in Islamic knowledge for Shia Muslim children worldwide. By bridging traditional religious education with modern digital tools, the institution strives to foster a deep connection to faith while promoting moral and ethical growth in its students.'),

            const SizedBox(height: 30),

            // ------------------ URDU CONTENT ------------------
            Text(
              'اردو ورژن',
              style: GoogleFonts.notoNaskhArabic(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),

            _buildUrduSection(
              'تعارف',
              '👈 مکتبِ سدرۃ المنتہیٰ ایک ممتاز شیعہ اسلامی تعلیمی ادارہ ہے جو نوجوان ذہنوں کو اسلامی علم، اقدار اور روحانیت کی روشنی سے منور کرنے کے لیے وقف ہے۔',
            ),
            _buildUrduSection(
              'رجسٹریشن',
              '👈 یہ ادارہ 24 جولائی 2020 کو مکتبِ سدرۃ المنتہیٰ پرائیویٹ لمیٹڈ کے طور پر باقاعدہ طور پر رجسٹر ہوا، جس کا صدر دفتر حیدرآباد، تلنگانہ (ہند) میں واقع ہے۔',
            ),
            _buildUrduSection(
              'عالمی کمیونٹی',
              '👈 مکتب ہندوستان، کینیڈا، برطانیہ، امریکہ، تنزانیہ، متحدہ عرب امارات اور عمان سمیت کئی ممالک کے متنوع طلبہ کی خدمت کر رہا ہے۔',
            ),
            _buildUrduSection(
              'نصاب',
              '👈 نصاب میں قرآنی تعلیمات، اسلامی تاریخ، اخلاقی تربیت (اخلاقیات)، عربی زبان، روزمرہ دعائیں و عبادات، اور معصومین (ع) کی حیات سے سبق آموز کہانیاں شامل ہیں۔',
            ),
            _buildUrduSection(
              'ڈیجیٹل رسائی',
              '👈 باضابطہ کلاسز کے ساتھ، مکتب یوٹیوب اور فیس بک جیسے پلیٹ فارمز پر ڈیجیٹل سرگرمیوں کے ذریعے قرآنی تلاوت، مجالس، اسلامی کہانیاں، اور اہم اسلامی کتب جیسے تہذیب الاسلام و گناہ کبیرہ کی آڈیو بکس پیش کرتا ہے۔',
            ),
            _buildUrduSection(
              'عملہ',
              '👈 اہل اور تجربہ کار اساتذہ و علمائے کرام کی ٹیم کے ساتھ، مکتبِ سدرۃ المنتہیٰ صرف ایک تعلیمی ادارہ نہیں بلکہ ہر طالب علم کے لیے روحانی سفر ہے جو ایمان، کردار اور معاشرتی شعور کو مضبوط بنیاد فراہم کرتا ہے۔',
            ),
            _buildUrduSection(
              '1. نصاب و کورسز',
              '👈 ادارہ ایک منظم نصاب فراہم کرتا ہے جس میں قرآنی تعلیمات، اسلامی تاریخ، اخلاقیات اور عربی زبان شامل ہیں۔ نصاب مختلف عمر اور صلاحیت کے طلبہ کے لحاظ سے تیار کیا گیا ہے تاکہ ہر طالب علم کو بہترین سیکھنے کا تجربہ ملے۔',
            ),
            _buildUrduSection(
              '2. ڈیجیٹل رسائی',
              '👈 مکتب جدید ٹیکنالوجی سے فائدہ اٹھاتے ہوئے یوٹیوب اور فیس بک کے ذریعے تعلیمی مواد، تازہ معلومات اور انٹرایکٹو وسائل فراہم کرتا ہے۔ یوٹیوب چینل میں قرآنی تلاوت، اسلامی کہانیاں، مجالس اور آڈیو بکس شامل ہیں۔',
            ),
            _buildUrduSection(
              '3. کمیونٹی انگیجمنٹ',
              '👈 ادارہ سوشل میڈیا پلیٹ فارمز اور سالانہ تقریبات کے ذریعے اپنی کمیونٹی سے مسلسل رابطے میں رہتا ہے۔ اپریل 2025 میں پانچویں سالانہ پروگرام میں طلبہ کی کامیابیوں کو سراہا گیا۔',
            ),
            _buildUrduSection(
              '4. مقامی اثرات',
              '👈 حیدرآباد میں مکتب نور خان بازار میں قائم اپنے آن لائن اسکول کے ذریعے مقامی برادری کو روایتی و جدید اسلامی تعلیم فراہم کر رہا ہے۔',
            ),
            _buildUrduSection(
              'مشن',
              '👈 مکتبِ سدرۃ المنتہیٰ کا مقصد دنیا بھر کے شیعہ مسلم بچوں میں اسلامی علم کی مضبوط بنیاد قائم کرنا ہے۔ یہ ادارہ روایتی تعلیم کو جدید ڈیجیٹل ذرائع کے ساتھ جوڑ کر ایمان، اخلاقی و روحانی ترقی کو فروغ دیتا ہے۔',
            ),
          ],
        ),
      ),
    );
  }

  // English Section Builder
  Widget _buildSection(String title, String content) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: GoogleFonts.roboto(
                fontSize: 17,
                height: 1.5,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Urdu Section Builder (Right Aligned)
  Widget _buildUrduSection(String title, String content) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end, // right alignment ✅
            children: [
              Align(
                alignment: Alignment.centerRight, // heading on right ✅
                child: Text(
                  title,
                  style: GoogleFonts.notoNaskhArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                textAlign: TextAlign.right, // paragraph right aligned ✅
                style: GoogleFonts.notoNaskhArabic(
                  fontSize: 18,
                  height: 1.5,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

