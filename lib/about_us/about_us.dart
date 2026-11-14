import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Maktab e Sidratul Muntaha',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '– Nurturing Souls, Enlightening Minds',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Maktab e Sidratul Muntaha is a humble yet dedicated Islamic educational institution committed to nurturing young minds and hearts with the light of Qur’an, Hadith, and the teachings of Ahlul Bayt (a.s). Located in Hyderabad, our Maktab is a safe and spiritually enriching space where children grow in Islamic knowledge, values, and character.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Our Classes Cover:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                BulletPoint(text: '👉 Qur’an recitation with Tajweed'),
                BulletPoint(text: '👉 Islamic beliefs and Fiqh (practical laws)'),
                BulletPoint(text: '👉 Akhlaaq (Islamic manners & ethics)'),
                BulletPoint(text: '👉 Life stories of Prophets and the Ahlul Bayt (a.s)'),
                BulletPoint(text: '👉 Dua memorization and understanding'),
                SizedBox(height: 16),
                Text(
                  '👉 Classes are conducted by qualified Alim and Alima, ensuring authentic knowledge, deep insight, and proper guidance.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Mobile App Features:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                BulletPoint(text: '👉 Full Maktab syllabus'),
                BulletPoint(text: '👉 Recorded lessons'),
                BulletPoint(text: '👉 Daily learning material'),
                BulletPoint(text: '👉 Announcements and updates'),
                SizedBox(height: 16),
                Text(
                  '👉 We also organize engaging activities like drawing competitions, Islamic quizzes, and storytelling sessions to build confidence and participation.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  '👉 Our dedicated teachers and volunteers work with sincerity, love, and patience — because at Maktab e Sidratul Muntaha, every child is an Amanat (trust) from Allah.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 24),

                // ✅ 📞 Contact section moved above download info
                Divider(thickness: 1),
                SizedBox(height: 12),
                Text(
                  '📞 Contact for Alim and Alima:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'For more information or to schedule a session with our respected Alim and Alima, please reach out via email or WhatsApp:\n\n📧 maktabsm3@gmail.com\n📱 +91 9948869645',
                  style: TextStyle(fontSize: 16),
                ),

                SizedBox(height: 24),
                Text(
                  '📍 Hyderabad\n📱 +91 9948869645\n📲 Download our App from Play Store',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'Join us in shaping tomorrow’s leaders—with knowledge, piety, and love for the Ahlul Bayt (a.s).',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;
  const BulletPoint({required this.text, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
