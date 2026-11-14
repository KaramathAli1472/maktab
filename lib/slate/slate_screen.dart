import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ColoredStroke {
  final List<ui.Offset> pts;
  final Color clr;
  final double width;

  ColoredStroke({required this.pts, required this.clr, required this.width});
}

class SlateScreen extends StatefulWidget {
  const SlateScreen({Key? key}) : super(key: key);

  @override
  State<SlateScreen> createState() => _SlateScreenState();
}

class _SlateScreenState extends State<SlateScreen> {
  Color selectedColor = Colors.white;
  double selectedStrokeWidth = 12.0;
  Offset? pointerPosition;
  bool isEraser = false;
  List<ColoredStroke> strokes = [];
  List<ColoredStroke> undoneStrokes = [];
  List<ui.Offset> currentPoints = [];

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _changeColor(Color color) {
    setState(() {
      selectedColor = color;
      isEraser = false;
    });
  }

  void _changeStrokeWidth(double width) {
    setState(() {
      selectedStrokeWidth = width.clamp(1.0, 50.0);
    });
  }

  void _toggleEraser() {
    setState(() {
      isEraser = !isEraser;
    });
  }

  void _incrementSize() => _changeStrokeWidth(selectedStrokeWidth + 1);
  void _decrementSize() => _changeStrokeWidth(selectedStrokeWidth - 1);

  void _undoStroke() {
    setState(() {
      if (strokes.isNotEmpty) {
        undoneStrokes.add(strokes.removeLast());
      }
    });
  }

  Future<void> _shareDrawing() async {
    try {
      if (strokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Canvas is empty")),
        );
        return;
      }

      final renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
      final size = renderBox.size;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final bgPaint = Paint()..color = Colors.black;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      for (var stroke in strokes) {
        final paint = Paint()
          ..color = stroke.clr
          ..strokeWidth = stroke.width
          ..strokeCap = ui.StrokeCap.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < stroke.pts.length - 1; i++) {
          canvas.drawLine(stroke.pts[i], stroke.pts[i + 1], paint);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/drawing.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes!);

      await Share.shareXFiles([XFile(file.path)], text: 'Check out my drawing!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sharing failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Maktab Drawing Board", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLandscape
            ? Row(
          children: [
            _buildLeftPanel(),
            Expanded(child: _buildCanvas()),
            _buildRightPanel(),
          ],
        )
            : Column(
          children: [
            Expanded(child: _buildCanvas()),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          pointerPosition = details.localPosition;
          currentPoints = [pointerPosition!];
        });
      },
      onPanUpdate: (details) {
        setState(() {
          pointerPosition = details.localPosition;
          currentPoints.add(pointerPosition!);
        });
      },
      onPanEnd: (_) {
        setState(() {
          pointerPosition = null;
          if (currentPoints.isNotEmpty) {
            strokes.add(ColoredStroke(
              pts: List.from(currentPoints),
              clr: isEraser ? Colors.black : selectedColor,
              width: selectedStrokeWidth,
            ));
            undoneStrokes.clear();
          }
          currentPoints.clear();
        });
      },
      child: RepaintBoundary(
        key: _canvasKey,
        child: Container(
          color: Colors.black,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(
            painter: _SlatePainter(
              strokes: strokes,
              currentPoints: currentPoints,
              color: selectedColor,
              strokeWidth: selectedStrokeWidth,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 60,
      color: Colors.grey[300],
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildToolButton(Icons.edit, "Pen", !isEraser, () => setState(() => isEraser = false)),
            const SizedBox(height: 20),
            _buildToolButton(Icons.square, "Eraser", isEraser, _toggleEraser),
            const SizedBox(height: 20),
            _buildToolButton(Icons.undo, "Undo", false, _undoStroke),
            const SizedBox(height: 20),
            _buildToolButton(Icons.delete, "Clear", false, () => setState(() => strokes.clear())),
            const SizedBox(height: 20),
            _buildToolButton(Icons.share, "Share", false, _shareDrawing),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 70,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Stroke Size Controls (vertical layout)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _incrementSize,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                child: const Text("+", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 6),
              Text(
                "${selectedStrokeWidth.toInt()}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _decrementSize,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                child: const Text("-", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Vertical Color Palette
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var color in [
                  Colors.white,
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.yellow,
                ])
                  GestureDetector(
                    onTap: () => _changeColor(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color && !isEraser
                              ? Colors.orange
                              : Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildSizeButton("-", _decrementSize),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  selectedStrokeWidth.toInt().toString(),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              _buildSizeButton("+", _incrementSize),
              const SizedBox(width: 12),
              Expanded(child: _buildColorPalette()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolButton(Icons.edit, "Pen", !isEraser, () => setState(() => isEraser = false)),
              _buildToolButton(Icons.square, "Eraser", isEraser, _toggleEraser),
              _buildToolButton(Icons.undo, "Undo", false, _undoStroke),
              _buildToolButton(Icons.delete, "Clear", false, () => setState(() => strokes.clear())),
              _buildToolButton(Icons.share, "Share", false, _shareDrawing),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _buildColorPalette() {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.yellow,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: colors
            .map((color) => GestureDetector(
          onTap: () => _changeColor(color),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selectedColor == color && !isEraser ? Colors.orange : Colors.black,
                width: 2,
              ),
            ),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, bool selected, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 22,
            backgroundColor: selected ? Colors.orange : Colors.blue,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _SlatePainter extends CustomPainter {
  final List<ColoredStroke> strokes;
  final List<ui.Offset> currentPoints;
  final Color color;
  final double strokeWidth;

  _SlatePainter({
    required this.strokes,
    required this.currentPoints,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.clr
        ..strokeWidth = stroke.width
        ..strokeCap = ui.StrokeCap.round;

      for (int i = 0; i < stroke.pts.length - 1; i++) {
        canvas.drawLine(stroke.pts[i], stroke.pts[i + 1], paint);
      }
    }

    final currentPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = ui.StrokeCap.round;

    for (int i = 0; i < currentPoints.length - 1; i++) {
      canvas.drawLine(currentPoints[i], currentPoints[i + 1], currentPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
