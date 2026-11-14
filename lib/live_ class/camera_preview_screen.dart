import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'live_class_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({
    super.key,
    required this.channelName,
    required this.role,
  });

  final String channelName;
  final String role;

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _videoOn = true;
  bool _micOn = true;
  List<CameraDescription> _cameras = [];
  int _selectedIndex = 0; // 0 = back, 1 = front (agar available)

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras(); // list of cameras [web:407]
      // front camera ka index dhoondo
      final frontIndex = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
      );
      // default back rakho, front mile to usko use karo (optional)
      _selectedIndex = frontIndex != -1 ? frontIndex : 0;

      await _startController(_selectedIndex);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _startController(int index) async {
    try {
      _controller?.dispose();
      _controller = CameraController(
        _cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      _initFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Camera controller error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return; // sirf ek hi camera hai
    _selectedIndex = _selectedIndex == 0 ? 1 : 0;
    await _startController(_selectedIndex);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _startMeeting() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveClassScreen(
          // channelName: widget.channelName,
          // role: widget.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: close + flip camera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: _switchCamera,
                ),
              ],
            ),
            // Camera preview box
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _controller == null
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                      : FutureBuilder(
                    future: _initFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.done) {
                        return CameraPreview(_controller!);
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Mic/Video icons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _micOn ? Icons.mic : Icons.mic_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _micOn = !_micOn);
                  },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: Icon(
                    _videoOn ? Icons.videocam : Icons.videocam_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _videoOn = !_videoOn);
                    // yahan chaho to preview pause/resume kar sakte ho
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "${widget.role}'s Meeting",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Start button
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startMeeting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E72EC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Start',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
