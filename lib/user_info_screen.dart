import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:maktab_e_sidratul_muntaha/quiz/dailyquiz_screen.dart';


class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '', city = '', phone = '', country = '';

  @override
  void initState() {
    super.initState();
    checkUserData();
  }

  Future<void> checkUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      // User data already exists — skip this screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DailyquizScreen(userId: user.uid)),
      );
    }
    // else: show form to enter data
  }

  Future<void> submitUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in. Please restart the app.')),
      );
      return;
    }

    final userId = user.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'name': name,
      'city': city,
      'phone': phone,
      'country': country,
      'createdAt': Timestamp.now(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DailyquizScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'City'),
                onChanged: (val) => city = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Country'),
                onChanged: (val) => country = val,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                onChanged: (val) => phone = val,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    submitUserData();
                  }
                },
                child: const Text('Start Quiz'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
