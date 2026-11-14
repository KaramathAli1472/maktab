import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:cross_file/cross_file.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DrawnLine {
  DrawnLine(this.points, this.color, this.width);
  final List<Offset> points;
  final Color color;
  final double width;
}

class ActivityText {
  ActivityText(this.text, this.position, this.color, this.size);
  final String text;
  final Offset position;
  final Color color;
  final double size;
}

class ActivityViewScreen extends StatefulWidget {
  const ActivityViewScreen({
    Key? key,
    required this.activityIndex,
    required this.totalActivities,
    required this.imageProvider,
    this.imageUrls = const [],
  }) : super(key: key);

  final int activityIndex;
  final int totalActivities;
  final ImageProvider imageProvider;
  final List<String> imageUrls;

  @override
  State<ActivityViewScreen> createState() => _ActivityViewScreenState();
}

class _ActivityViewScreenState extends State<ActivityViewScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final GlobalKey _drawingAreaKey = GlobalKey();

  List<DrawnLine> _lines = [];
  List<DrawnLine> _undone = [];
  List<ActivityText> _texts = [];
  Offset? _currentPoint;

  Color _currentColor = Colors.red;
  double _currentWidth = 4.0;
  double _zoom = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  bool _isTextMode = false;
  bool _isImageDragging = false;
  final TextEditingController _nameController = TextEditingController();
  static const double _nameOverlayTop = 10;

  DrawnLine? _currentLine;

  void _startLine(Offset p) {
    _currentLine = DrawnLine([p], _currentColor, _currentWidth);
    setState(() {
      _currentPoint = p;
      _lines.add(_currentLine!);
    });
  }

  void _addPoint(Offset p) {
    setState(() {
      _currentPoint = p;
      _currentLine?.points.add(p);
    });
  }

  void _endLine() {
    _currentLine = null;
    _currentPoint = null;
    _undone.clear();
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undone.add(_lines.removeLast());
      });
    }
  }

  void _redo() {
    if (_undone.isNotEmpty) {
      setState(() {
        _lines.add(_undone.removeLast());
      });
    }
  }

  void _clear() {
    setState(() {
      _lines.clear();
      _undone.clear();
      _texts.clear();
    });
  }

  static Offset mapToImageArea(Offset point, Size containerSize, {double aspectRatio = 3 / 4}) {
    final size = containerSize;
    double drawWidth = size.width;
    double drawHeight = size.height;
    double offsetX = 0;
    double offsetY = 0;

    if (size.width / size.height > aspectRatio) {
      drawHeight = size.height;
      drawWidth = drawHeight * aspectRatio;
      offsetX = (size.width - drawWidth) / 2;
    } else {
      drawWidth = size.width;
      drawHeight = drawWidth / aspectRatio;
      offsetY = (size.height - drawHeight) / 2;
    }

    return Offset(
      (point.dx - offsetX).clamp(0.0, drawWidth),
      (point.dy - offsetY).clamp(0.0, drawHeight),
    );
  }

  static Offset _defaultTextPosition() => const Offset(0, 12);

  void _addText() {
    final text = _nameController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _texts.add(ActivityText(
        text,
        _defaultTextPosition(),
        _currentColor,
        24,
      ));
      _nameController.clear();
      _isTextMode = false;
    });
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.1).clamp(1.0, 3.0);
      if (_zoom <= 1.0) {
        _panX = 0.0;
        _panY = 0.0;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.1).clamp(1.0, 3.0);
      if (_zoom <= 1.0) {
        _panX = 0.0;
        _panY = 0.0;
      }
    });
  }

  Future<String> _saveToFile() async {
    try {
      RenderRepaintBoundary boundary = _repaintKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: ui.window.devicePixelRatio);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/MyActivities');
      if (!await folder.exists()) await folder.create(recursive: true);
      final file = File('${folder.path}/activity_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveAndShowSnack() async {
    try {
      final path = await _saveToFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved: $path')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save failed')));
    }
  }

  Future<void> _share() async {
    try {
      final path = await _saveToFile();
      await Share.shareXFiles([XFile(path)], text: 'My Activity');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share failed')));
    }
  }

  void _pickColor() async {
    final colors = [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.yellow];
    final picked = await showDialog<Color>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pick color'),
        content: Wrap(
          spacing: 8,
          children: colors
              .map((col) => GestureDetector(
                    onTap: () => Navigator.of(c).pop(col),
                    child: Container(width: 36, height: 36, color: col),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked != null) setState(() => _currentColor = picked);
  }

  void _pickSize() async {
    double size = _currentWidth;
    final picked = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pen size'),
        content: StatefulBuilder(builder: (c2, s) {
          return Slider(
            min: 1,
            max: 20,
            value: size,
            onChanged: (v) => s(() => size = v),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop(size), child: const Text('OK')),
        ],
      ),
    );
    if (picked != null) setState(() => _currentWidth = picked);
  }

  ImageProvider<Object> _currentImageProvider() {
    if (widget.imageUrls.isNotEmpty) {
      final index = widget.activityIndex.clamp(0, widget.imageUrls.length - 1);
      return NetworkImage(widget.imageUrls[index]);
    }
    return widget.imageProvider;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity ${widget.activityIndex + 1} / ${widget.totalActivities}'),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
            if (widget.activityIndex > 0) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActivityViewScreen(
                activityIndex: widget.activityIndex - 1,
                totalActivities: widget.totalActivities,
                imageProvider: widget.imageProvider,
                imageUrls: widget.imageUrls,
              )));
            }
          }),
          IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {
            if (widget.activityIndex < widget.totalActivities - 1) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ActivityViewScreen(
                activityIndex: widget.activityIndex + 1,
                totalActivities: widget.totalActivities,
                imageProvider: widget.imageProvider,
                imageUrls: widget.imageUrls,
              )));
            }
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _repaintKey,
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _texts.isEmpty ? 'Student Name' : _texts.last.text,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _texts.isEmpty ? Colors.black : _texts.last.color,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        top: 56,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (details) {
                            final box = _drawingAreaKey.currentContext?.findRenderObject() as RenderBox?;
                            if (box == null || _isTextMode) return;

                            if (_zoom > 1.0) {
                              _isImageDragging = true;
                              return;
                            }

                            _isImageDragging = false;
                            final local = box.globalToLocal(details.globalPosition);
                            _startLine(mapToImageArea(local, box.size));
                          },
                          onPanUpdate: (details) {
                            final box = _drawingAreaKey.currentContext?.findRenderObject() as RenderBox?;
                            if (box == null || _isTextMode) return;

                            if (_isImageDragging) {
                              _panX += details.delta.dx;
                              _panY += details.delta.dy;
                              setState(() {});
                              return;
                            }

                            if (_zoom <= 1.0) {
                              final local = box.globalToLocal(details.globalPosition);
                              _addPoint(mapToImageArea(local, box.size));
                            }
                          },
                          onPanEnd: (_) {
                            if (!_isImageDragging) {
                              _endLine();
                            }
                            _isImageDragging = false;
                          },
                          child: Transform.translate(
                            offset: Offset(_panX, _panY),
                            child: Transform.scale(
                              scale: _zoom,
                              alignment: Alignment.topCenter,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image(
                                    image: _currentImageProvider(),
                                    fit: BoxFit.contain,
                                  ),
                                  Container(
                                    key: _drawingAreaKey,
                                    child: Stack(
                                      children: [
                                        CustomPaint(
                                          painter: _DrawingPainter(_lines),
                                          size: Size.infinite,
                                        ),
                                        if (_currentPoint != null)
                                          Positioned(
                                            left: _currentPoint!.dx - 6,
                                            top: _currentPoint!.dy - 6,
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: _currentColor.withOpacity(0.7),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1.5),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Toolbar
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                if (_isTextMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Student name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _addText, child: const Text('Add')),
                      ],
                    ),
                  ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    IconButton(icon: const Icon(Icons.brush), onPressed: _pickColor),
                    IconButton(icon: const Icon(Icons.format_size), onPressed: _pickSize),
                    IconButton(icon: const Icon(Icons.text_fields), onPressed: () => setState(() => _isTextMode = !_isTextMode)),
                    IconButton(icon: const Icon(Icons.zoom_in), onPressed: _zoomIn),
                    IconButton(icon: const Icon(Icons.zoom_out), onPressed: _zoomOut),
                    IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
                    IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
                    IconButton(icon: const Icon(Icons.delete), onPressed: _clear),
                    IconButton(icon: const Icon(Icons.save), onPressed: _saveAndShowSnack),
                    IconButton(icon: const Icon(Icons.share), onPressed: _share),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.lines);
  final List<DrawnLine> lines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (line.points.length < 2) {
        if (line.points.isNotEmpty) {
          canvas.drawPoints(ui.PointMode.points, line.points, paint);
        }
      } else {
        final path = Path()..moveTo(line.points[0].dx, line.points[0].dy);
        for (int i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx, line.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
