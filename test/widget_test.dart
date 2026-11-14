// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:maktab_e_sidratul_muntaha/quranjuzz/juz_detail_screen.dart';

void main() {
  test('quran arabic area uses an image placeholder instead of text', () {
    final widget = buildArabicImagePlaceholder();

    expect(widget, isA<Container>());
    expect((widget as Container).child, isA<ClipRRect>());
  });
}
