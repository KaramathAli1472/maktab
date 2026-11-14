import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1024) {
          // Desktop
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1200),
              child: child,
            ),
          );
        } else if (constraints.maxWidth > 600) {
          // Tablet
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              child: child,
            ),
          );
        } else {
          // Mobile
          return child;
        }
      },
    );
  }
}