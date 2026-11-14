import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pointer_provider.dart';

class GlobalPointer extends StatelessWidget {
  final double size;
  final Color color;

  GlobalPointer({this.size = 40, this.color = Colors.red});

  @override
  Widget build(BuildContext context) {
    final pointerProvider = Provider.of<PointerProvider>(context);
    final position = pointerProvider.position;

    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: GestureDetector(
        onPanUpdate: (details) {
          final speedFactor = 2.0; // pointer movement speed adjust karne ke liye
          pointerProvider.updatePosition(position + details.delta * speedFactor);
        },
        child: CustomPaint(
          size: Size(size, size),
          painter: _ArrowPainter(color),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Color color;

  _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    path.moveTo(0, 0); // Pointer tip
    path.lineTo(size.width, size.height / 2); // Right middle
    path.lineTo(size.width * 0.3, size.height / 2);
    path.lineTo(size.width * 0.3, size.height);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}