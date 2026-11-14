import 'dart:math';
import 'package:flutter/material.dart';
import 'camera_preview_screen.dart';
import 'live_class_screen.dart';

// 9-digit random numeric meeting ID
String generateMeetingId() {
  final rand = Random();
  String id = '';
  for (int i = 0; i < 9; i++) {
    id += rand.nextInt(10).toString();
  }
  return id; // e.g. "567594354"
}

class StartMeetingScreen extends StatefulWidget {
  const StartMeetingScreen({super.key});

  @override
  State<StartMeetingScreen> createState() => _StartMeetingScreenState();
}

class _StartMeetingScreenState extends State<StartMeetingScreen> {
  bool _videoOn = true;
  bool _usePersonalId = false;

  late String _personalId; // auto generated

  @override
  void initState() {
    super.initState();
    _personalId = generateMeetingId();
  }

  void _startMeeting() {
    final channelName = _usePersonalId ? _personalId : "MaktabLiveClass";

    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const CameraPreviewScreen(
      channelName: "MaktabLiveClass",
      role: "teacher", // ya "student"
    ),
  ),
);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Start a meeting'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Video on'),
              value: _videoOn,
              onChanged: (v) => setState(() => _videoOn = v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Use personal meeting ID (PMI)'),
              subtitle: Text(_personalId),
              value: _usePersonalId,
              onChanged: (v) => setState(() => _usePersonalId = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,     // Button Color
                  foregroundColor: Colors.white,     // Text Color
                  padding: const EdgeInsets.symmetric(vertical: 14), // Height bada karne ke liye
                ),
                onPressed: _startMeeting,
                child: const Text(
                  'Start a meeting',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

