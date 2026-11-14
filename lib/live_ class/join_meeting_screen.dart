import 'package:flutter/material.dart';
import 'live_class_screen.dart';

class JoinMeetingScreen extends StatefulWidget {
  const JoinMeetingScreen({super.key});

  @override
  State<JoinMeetingScreen> createState() => _JoinMeetingScreenState();
}

class _JoinMeetingScreenState extends State<JoinMeetingScreen> {
  final _meetingIdCtrl = TextEditingController(text: "MaktabLiveClass");
  final _nameCtrl = TextEditingController(text: "Student");

  @override
  void dispose() {
    _meetingIdCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _join(bool cameraOn) {
    final channel = _meetingIdCtrl.text.trim();
    final name = _nameCtrl.text.trim().isEmpty ? "Student" : _nameCtrl.text.trim();
    if (channel.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveClassScreen(
          // channelName: channel,
          // role: name,      // abhi role me name bhej diya, chaho to "student" hi rakho
          
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a meeting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _meetingIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Meeting ID / Class code',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Your name',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _join(true),
              child: const Text('Join with video'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _join(false),
              child: const Text('Join without video'),
            ),
          ],
        ),
      ),
    );
  }
}
