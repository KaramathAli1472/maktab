// call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'signaling.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  final bool isTeacher;
  final String userName;
  final String className;

  const CallScreen({
    super.key,
    required this.roomId,
    required this.isTeacher,
    required this.userName,
    required this.className,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  final Signaling _signaling = Signaling();

  bool _micEnabled = true;
  bool _usingFrontCamera = true;
  bool _isLocalBig = false; // swap flag

  // small preview ki position (bottom-right se distance)
  Offset _smallViewOffset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    print(
        'CallScreen initState: roomId=${widget.roomId}, isTeacher=${widget.isTeacher}');
    _init();
  }

  Future<void> _init() async {
    print('CallScreen _init start');

    await _requestPermissions();

    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    print('Renderers initialized');

    // signaling callbacks
    _signaling.onLocalStream = (MediaStream stream) {
      print('CallScreen: onLocalStream ${stream.id}');
      _localRenderer.srcObject = stream;
      setState(() {});
    };

    _signaling.onAddRemoteStream = (MediaStream stream) {
      print('CallScreen: onAddRemoteStream ${stream.id}');
      _remoteRenderer.srcObject = stream;
      setState(() {});
    };

    _signaling.onRemoveRemoteStream = () {
      print('CallScreen: onRemoveRemoteStream');
      _remoteRenderer.srcObject = null;
      setState(() {});
    };

    _signaling.onDisconnect = () {
      print('CallScreen: onDisconnect called');
      if (mounted) Navigator.pop(context);
    };

    // Teacher / Student
    if (widget.isTeacher) {
      print('CallScreen: calling createRoom(${widget.roomId})');
      final id = await _signaling.createRoom(widget.roomId);
      print('CallScreen: createRoom done, roomId=$id');
    } else {
      print('CallScreen: calling joinRoomById(${widget.roomId})');
      await _signaling.joinRoomById(widget.roomId);
      print('CallScreen: joinRoomById done');
    }

    print('CallScreen _init end');
  }

  Future<void> _requestPermissions() async {
    print('CallScreen: requesting permissions');
    final statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      print('CallScreen: permissions NOT granted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera/Mic permission required')),
        );
      }
    } else {
      print('CallScreen: permissions granted');
    }
  }

  void _toggleMic() {
    print('CallScreen: toggleMic');
    _signaling.muteMic();
    _micEnabled = !_micEnabled;
    setState(() {});
  }

  Future<void> _toggleCamera() async {
    print('CallScreen: toggleCamera');
    final isFront = await _signaling.switchCamera();
    setState(() {
      _usingFrontCamera = isFront;
    });
  }

  Future<void> _hangUp() async {
    print('CallScreen: hangUp pressed');

    if (mounted) {
      Navigator.pop(context);
    }

    await _signaling.hungUp();
  }

  @override
  void dispose() {
    print('CallScreen dispose');
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // small preview ka widget (local/remote swap ke hisaab se)
  Widget _smallVideoContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: RTCVideoView(
        _isLocalBig ? _remoteRenderer : _localRenderer,
        mirror: !_isLocalBig && _usingFrontCamera,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Android ka back button: sirf screen se bahar, hungUp yahan nahi
      onWillPop: () async {
        // true = allow pop
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('${widget.className} (${widget.roomId})'),
        ),
        body: GestureDetector(
          // screen tap se local/remote swap
          onTap: () {
            setState(() {
              _isLocalBig = !_isLocalBig;
            });
          },
          child: Stack(
            children: [
              // Big view: ya to local ya remote
              Center(
                child: RTCVideoView(
                  _isLocalBig ? _localRenderer : _remoteRenderer,
                  objectFit:
                  RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  mirror: _isLocalBig && _usingFrontCamera,
                ),
              ),

              // Small preview: draggable
              Positioned(
                right: _smallViewOffset.dx,
                bottom: _smallViewOffset.dy,
                width: 120,
                height: 160,
                child: Draggable(
                  feedback: _smallVideoContainer(),
                  childWhenDragging: const SizedBox.shrink(),
                  onDragEnd: (details) {
                    final size = MediaQuery.of(context).size;

                    // naya right / bottom calculate karo (screen bounds ke andar)
                    final newRight = (size.width - details.offset.dx - 120)
                        .clamp(0, size.width - 120)
                        .toDouble();
                    final newBottom = (size.height - details.offset.dy - 160)
                        .clamp(0, size.height - 160)
                        .toDouble();

                    setState(() {
                      _smallViewOffset = Offset(newRight, newBottom);
                    });
                  },
                  child: _smallVideoContainer(),
                ),
              ),

              // bottom controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mic button
                    CircleAvatar(
                      radius: 28,
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

                    // Camera switch button
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: IconButton(
                        icon: const Icon(Icons.cameraswitch,
                            color: Colors.white),
                        onPressed: _toggleCamera,
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Hangup button
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
        ),
      ),
    );
  }
}
