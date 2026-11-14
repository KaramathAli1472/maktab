import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../about_us/about_us.dart';


class ContactUsPage extends StatelessWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  final String email = 'maktabesidratulmuntaha@gmail.com';
  final String whatsappNumber = "+919948869645";

  final String privacyPolicyUrl =
      'https://karamathali1472.github.io/maktab_privacypolicy/';

  void _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Inquiry from App'},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showSnackBar(context, 'No email app found. Please install one.');
    }
  }

  void _launchWhatsApp(BuildContext context) async {
    final whatsappUri =
    Uri.parse("https://wa.me/${whatsappNumber.replaceAll('+', '')}");

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      _showSnackBar(context, 'WhatsApp is not available on this device.');
    }
  }

  void _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(context, 'Could not open the link.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildOptionTile(String title, VoidCallback onTap, Widget icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          _buildOptionTile(
            'Recommend to Others - Email',
                () => _launchEmail(context),
            const Icon(Icons.email, color: Colors.teal),
          ),
          _buildOptionTile(
            'Chat on WhatsApp',
                () => _launchWhatsApp(context),
            const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
          ),
          _buildOptionTile(
            'Ideas & Suggestions',
                () => _launchEmail(context),
            const Icon(Icons.lightbulb_outline, color: Colors.orange),
          ),
          _buildOptionTile(
            'About Us',
                () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutUs()),
            ),
            const Icon(Icons.info_outline, color: Colors.blue),
          ),
          _buildOptionTile(
            'Privacy Policy',
                () => _launchUrl(context, privacyPolicyUrl),
            const Icon(Icons.privacy_tip, color: Colors.purple),
          ),
        ],
      ),
    );
  }
}
