import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'deeniyat_screen.dart';


class DeeniyatLoginScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String chapter;

  const DeeniyatLoginScreen({
    super.key,
    required this.item,
    required this.chapter,
  });

  @override
  State<DeeniyatLoginScreen> createState() => _DeeniyatLoginScreenState();
}

class _DeeniyatLoginScreenState extends State<DeeniyatLoginScreen> {
  final _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool rememberMe = true; // ✅ Remember Me by default

  // 🔹 Contact Info
  final String email = 'maktabesidratulmuntaha@gmail.com';
  final String whatsapp = '+919948869645';
  final String phone = '+919948869645';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // 🔹 Load saved email & password
  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedEmail = prefs.getString('saved_email');
    String? savedPassword = prefs.getString('saved_password');

    if (savedEmail != null) emailController.text = savedEmail;
    if (savedPassword != null) passwordController.text = savedPassword;
  }

  // 🔹 Save credentials if rememberMe is true
  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_email', emailController.text.trim());
      await prefs.setString('saved_password', passwordController.text.trim());
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    setState(() => isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ Save credentials if Remember Me is checked
      await _saveCredentials();

      // ✅ On success — go to AmmaDetailsScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeeniyatScreen(
            title: widget.item['title'] ?? 'No Title',
            subtitle: widget.item['subtitle'] ?? 'No Subtitle',
            imageUrl: widget.item['image_url'] ?? '',
            description:
            widget.item['description'] ?? 'No Description Available',
            detailsID: widget.item['detailsID'] ?? '',
            chapter: widget.chapter,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Login failed. Please try again.');
    } catch (e) {
      _showSnack('Something went wrong. Try again.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔹 Helpers to launch WhatsApp, Email, Phone
  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse("https://wa.me/${whatsapp.replaceAll('+', '')}");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack("WhatsApp not available");
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Login Help - Maktab App'},
    );
    if (!await launchUrl(emailUri)) {
      _showSnack("Email app not found");
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(phoneUri)) {
      _showSnack("Cannot make a call right now");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('User Login'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔹 Login Card with Lock Icon
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 60,
                        color: Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Login to Continue',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value ?? true;
                              });
                            },
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 Message below the card
              Column(
                children: [
                  const Text(
                    'If login is not working, please contact the Admin:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 10,
                    children: [
                      GestureDetector(
                        onTap: _launchWhatsApp,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            FaIcon(
                              FontAwesomeIcons.whatsapp,
                              color: Colors.green,
                              size: 28,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _launchEmail,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.email,
                              color: Colors.red,
                              size: 28,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Email',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _launchPhone,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.phone,
                              color: Colors.blue,
                              size: 28,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
