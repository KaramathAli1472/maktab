import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';

const String videoSdkToken = '<YAHAN_APNA_TOKEN>'; // dashboard se
const String testRoomId = 'test-room-123';

class VideoSdkTestScreen extends StatefulWidget {
  const VideoSdkTestScreen({super.key});

  @override
  State<VideoSdkTestScreen> createState() => _VideoSdkTestScreenState();
}

class _VideoSdkTestScreenState extends State<VideoSdkTestScreen> {
  Room? _room;
  bool _joined = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  void _joinRoom() {
    _room = VideoSDK.createRoom(
      roomId: testRoomId,
      token: videoSdkToken,
      displayName: 'Teacher Test',
      micEnabled: true,
      camEnabled: true,
    );

    _room!.on(Events.roomJoined, (_) {
      setState(() => _joined = true);
    });

    _room!.on(Events.screenShareStarted, (_) {
      setState(() => _isSharing = true);
    });

    _room!.on(Events.screenShareStopped, (_) {
      setState(() => _isSharing = false);
    });

    _room!.join();
  }

  void _toggleScreenShare() {
    if (_isSharing) {
      _room?.disableScreenShare();
    } else {
      _room?.enableScreenShare();
    }
  }

  @override
  void dispose() {
    _room?.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VideoSDK Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_joined ? 'Joined: $testRoomId' : 'Joining...'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joined ? _toggleScreenShare : null,
              child: Text(_isSharing ? 'Stop Screen Share' : 'Start Screen Share'),
            ),
          ],
        ),
      ),
    );
  }
}
