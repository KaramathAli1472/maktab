import 'package:flutter/material.dart';
import 'live_class_screen.dart';
import 'join_meeting_screen.dart';
import 'start_meeting_screen.dart'; // host options screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Maktab Live'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _zoomTopBar(context),
          const SizedBox(height: 16),
          const Expanded(
            child: Center(
              child: Text(
                'Select Host or Join to start',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoomTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // HOST = TEACHER
        _topButton(
          icon: Icons.videocam,
          label: 'Meet',
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StartMeetingScreen(), // Zoom-style host screen
              ),
            );
          },
        ),
        // STUDENT JOIN
        _topButton(
          icon: Icons.add,
          label: 'Join',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const JoinMeetingScreen(),
              ),
            );
          },
        ),
        _topButton(
          icon: Icons.calendar_month,
          label: 'Schedule',
          color: Colors.blue,
          onTap: () {
            // TODO: Schedule screen
          },
        ),
        _topButton(
          icon: Icons.arrow_upward,
          label: 'Share',
          color: Colors.blue,
          onTap: () {
            // TODO: Share screen
          },
        ),
      ],
    );
  }

  Widget _topButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
