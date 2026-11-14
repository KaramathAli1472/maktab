import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ScreenShareTestPage extends StatefulWidget {
  const ScreenShareTestPage({super.key});

  @override
  State<ScreenShareTestPage> createState() => _ScreenShareTestPageState();
}

class _ScreenShareTestPageState extends State<ScreenShareTestPage> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  MediaStream? _screenStream;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
  }

  Future<void> _startScreenShare() async {
    try {
      // sirf local screen capture test
      final stream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });

      setState(() {
        _screenStream = stream;
        _renderer.srcObject = stream;
        _sharing = true;
      });
    } catch (e, st) {
      debugPrint('getDisplayMedia error: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Screen share failed: $e')),
        );
      }
    }
  }

  Future<void> _stopScreenShare() async {
    try {
      _screenStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    setState(() {
      _screenStream = null;
      _renderer.srcObject = null;
      _sharing = false;
    });
  }

  @override
  void dispose() {
    try {
      _screenStream?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen Share TEST')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: RTCVideoView(
                _renderer,
                objectFit:
                RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sharing ? _stopScreenShare : _startScreenShare,
            child: Text(_sharing ? 'Stop Screen Share' : 'Start Screen Share'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
