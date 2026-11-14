import 'package:flutter/material.dart';

import 'marquee_bar/marquee_bar.dart';


class SampleScreen extends StatelessWidget {
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Screen'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.flutter_dash, size: 80, color: Colors.teal),
                  SizedBox(height: 20),
                  Text(
                    'Welcome to the Sample Page!',
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
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
