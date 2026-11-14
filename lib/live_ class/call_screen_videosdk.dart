import 'package:flutter/material.dart';
import 'package:videosdk/videosdk.dart';

// JWT token (dashboard se)
const String videoSdkToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcGlrZXkiOiJiODNjMzE3Yi1jOWUzLTQ0ZTQtYTFmMy03ZjMzZjcxZDk0ZmIiLCJwZXJtaXNzaW9ucyI6WyJhbGxvd19qb2luIl0sInJvbGVzIjpbInJ0YyJdLCJpYXQiOjE3NjUyMTcwNTUsImV4cCI6MTc5Njc1MzA1NX0.Ap3hVPsovsTUCJT4Nn4HdycE7PPIxwPhTEVqdW-iljw';

class CallScreenVideoSdk extends StatefulWidget {
  final String roomId;
  final bool isTeacher;
  final String userName;
  final String className;

  const CallScreenVideoSdk({
    super.key,
    required this.roomId,
    required this.isTeacher,
    required this.userName,
    required this.className,
  });

  @override
  State<CallScreenVideoSdk> createState() => _CallScreenVideoSdkState();
}

class _CallScreenVideoSdkState extends State<CallScreenVideoSdk> {
  Room? _room;
  bool _joined = false;
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _joinRoom();
  }

  void _joinRoom() {
    _room = VideoSDK.createRoom(
      roomId: widget.roomId,
      token: videoSdkToken,
      displayName: widget.userName,
      micEnabled: true,
      camEnabled: true,
    );

    _room!.on(Events.roomJoined, () {
      debugPrint('roomJoined: ${_room!.id}');
      setState(() => _joined = true);
    });

    _room!.on(Events.error, (error) {
      debugPrint('VIDEOSDK ERROR: $error');
    });

    _room!.on(Events.participantJoined, (participant) {
      debugPrint('participantJoined: ${participant.id}');
    });

    _room!.on(Events.participantLeft, (participant) {
      debugPrint('participantLeft: ${participant.id}');
    });

    _room!.on(Events.streamEnabled, (stream) {
      debugPrint('streamEnabled: ${stream.kind}');
      if (stream.kind == 'share') {
        setState(() => _isSharing = true);
      }
    });

    _room!.on(Events.streamDisabled, (stream) {
      debugPrint('streamDisabled: ${stream.kind}');
      if (stream.kind == 'share') {
        setState(() => _isSharing = false);
      }
    });

    _room!.join();
  }

  void _toggleMic() {
    if (_micEnabled) {
      _room?.muteMic();
    } else {
      _room?.unmuteMic();
    }
    setState(() => _micEnabled = !_micEnabled);
  }

  void _toggleCam() {
    if (_camEnabled) {
      _room?.disableCam();
    } else {
      _room?.enableCam();
    }
    setState(() => _camEnabled = !_camEnabled);
  }

  void _toggleScreenShare() {
    if (_isSharing) {
      _room?.disableScreenShare();
      setState(() => _isSharing = false);
    } else {
      _room?.enableScreenShare();
      setState(() => _isSharing = true);
    }
  }

  Future<void> _hangUp() async {
    await _room?.leave();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _room?.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.className} (${widget.roomId})'),
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              _joined ? 'Joined: ${_room?.id ?? widget.roomId}' : 'Joining...',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      _micEnabled ? Colors.white24 : Colors.redAccent,
                  child: IconButton(
                    icon: Icon(
                      _micEnabled ? Icons.mic : Icons.mic_off,
                      color: Colors.white,
                    ),
                    onPressed: _joined ? _toggleMic : null,
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      _camEnabled ? Colors.white24 : Colors.redAccent,
                  child: IconButton(
                    icon: Icon(
                      _camEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.white,
                    ),
                    onPressed: _joined ? _toggleCam : null,
                  ),
                ),
                const SizedBox(width: 16),
                if (widget.isTeacher)
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        _isSharing ? Colors.blue : Colors.white24,
                    child: IconButton(
                      icon: Icon(
                        _isSharing
                            ? Icons.stop_screen_share
                            : Icons.screen_share,
                        color: Colors.white,
                      ),
                      onPressed: _joined ? _toggleScreenShare : null,
                    ),
                  ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: _hangUp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

