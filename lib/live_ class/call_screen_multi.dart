import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'signaling_multi.dart';

class CallScreenMulti extends StatefulWidget {
  final String roomId;
  final String selfId; // Firebase UID
  final bool isTeacher;
  final String userName;
  final String className;

  const CallScreenMulti({
    super.key,
    required this.roomId,
    required this.selfId,
    required this.isTeacher,
    required this.userName,
    required this.className,
  });

  @override
  State<CallScreenMulti> createState() => _CallScreenMultiState();
}

class _CallScreenMultiState extends State<CallScreenMulti> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

  // peerId -> renderer
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};

  late SignalingMulti _signaling;

  bool _micEnabled = true;
  bool _usingFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();

    await _localRenderer.initialize();

    _signaling = SignalingMulti(
      roomId: widget.roomId,
      selfId: widget.selfId,
    );

    // callbacks
    _signaling.onLocalStream = (MediaStream stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    };

    _signaling.onAddRemoteStream = (String peerId, MediaStream stream) async {
      if (!_remoteRenderers.containsKey(peerId)) {
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        _remoteRenderers[peerId] = renderer;
      }
      _remoteRenderers[peerId]!.srcObject = stream;
      setState(() {});
    };

    _signaling.onRemoveRemoteStream = (String peerId) {
      final renderer = _remoteRenderers.remove(peerId);
      if (renderer != null) {
        renderer.dispose();
      }
      setState(() {});
    };

    _signaling.onDisconnect = () {
      if (mounted) Navigator.pop(context);
    };

    await _signaling.joinRoom();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera/Mic permission required')),
        );
      }
    }
  }

  void _toggleMic() {
    _signaling.localStream.getAudioTracks().forEach((t) {
      t.enabled = !t.enabled;
      _micEnabled = t.enabled;
    });
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    try {
      final videoTracks = _signaling.localStream.getVideoTracks();
      if (videoTracks.isEmpty) return;
      final track = videoTracks[0];
      final isFront = await Helper.switchCamera(track);
      setState(() {
        _usingFrontCamera = isFront;
      });
    } catch (e) {
      debugPrint('toggleCamera error: $e');
    }
  }

  Future<void> _hangUp() async {
    if (mounted) {
      Navigator.pop(context);
    }
    await _signaling.leaveRoom();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remoteList = _remoteRenderers.entries.toList();

    return WillPopScope(
      onWillPop: () async {
        await _signaling.leaveRoom();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('${widget.className} (${widget.roomId})'),
        ),
        body: Stack(
          children: [
            // REMOTE video(s) – full screen area
            Positioned.fill(
              child: remoteList.isEmpty
                  ? Center(
                child: Text(
                  widget.isTeacher
                      ? 'Waiting for students...'
                      : 'Connecting to teacher...',
                  style: const TextStyle(color: Colors.white54),
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 5,
                  bottom: 100, // space for bottom controls
                ),
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: remoteList.length == 1 ? 1 : 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: remoteList.length,
                itemBuilder: (context, index) {
                  final entry = remoteList[index];
                  final peerId = entry.key;
                  final renderer = entry.value;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RTCVideoView(
                            renderer,
                            objectFit: RTCVideoViewObjectFit
                                .RTCVideoViewObjectFitCover,
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              peerId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // LOCAL preview – thoda bada PiP bottom-right
            Positioned(
              bottom: 110, // controls ke thoda upar
              right: 12,
              width: 170,  // yahan size badhaya
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: _usingFrontCamera,
                  objectFit:
                  RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                    _micEnabled ? Colors.white24 : Colors.redAccent,
                    child: IconButton(
                      icon: Icon(
                        _micEnabled ? Icons.mic : Icons.mic_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMic,
                    ),
                  ),
                  const SizedBox(width: 24),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white24,
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                      ),
                      onPressed: _toggleCamera,
                    ),
                  ),
                  const SizedBox(width: 24),
                  CircleAvatar(
                    radius: 30,
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
      ),
    );
  }
}
