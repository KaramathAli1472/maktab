import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marquee/marquee.dart';

class MarqueeBar extends StatefulWidget {
  final double height;
  final Color backgroundColor;
  final TextStyle textStyle;

  const MarqueeBar({
    super.key,
    this.height = 40,
    this.backgroundColor = Colors.black,
    this.textStyle = const TextStyle(color: Colors.white, fontSize: 20),
  });

  @override
  State<MarqueeBar> createState() => _MarqueeBarState();
}

class _MarqueeBarState extends State<MarqueeBar> {
  String marqueeText = "";
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchAndShuffleText();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5), // 🔁 Change interval as needed
          (_) => _fetchAndShuffleText(),
    );
  }

  Future<void> _fetchAndShuffleText() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('global')
          .get();

      if (doc.exists && doc.data() != null) {
        String rawText = doc.get('marqueeText') ?? "";

        // Split on 🤲 and clean up
        List<String> parts = rawText
            .split("🤲")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        parts.shuffle(Random());

        setState(() {
          marqueeText = "🤲 " + parts.join(" 🤲 ") + " 🤲";
          isLoading = false;
        });
      } else {
        setState(() {
          marqueeText = "";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        marqueeText = "";
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || marqueeText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 5), // move slightly up
      height: widget.height,
      color: widget.backgroundColor,
      child: Marquee(
        text: marqueeText,
        style: widget.textStyle,
        scrollAxis: Axis.horizontal,
        blankSpace: 20.0,
        velocity: 40.0,
        pauseAfterRound: const Duration(seconds: 1),
      ),
    );
  }
}
