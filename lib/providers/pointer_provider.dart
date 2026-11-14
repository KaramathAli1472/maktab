import 'package:flutter/material.dart';

class PointerProvider extends ChangeNotifier {
  Offset _position = Offset(100, 200);

  Offset get position => _position;

  void updatePosition(Offset newPosition) {
    _position = newPosition;
    notifyListeners();
  }
}
