import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class TasbeehCounterPage extends StatefulWidget {
  @override
  _TasbeehCounterPageState createState() => _TasbeehCounterPageState();
}

class _TasbeehCounterPageState extends State<TasbeehCounterPage> {
  final List<Map<String, dynamic>> tasbeehList = [
    {"roman": "Allah-o-Akbar", "urdu": "ﷲُ أَكْبَرُ", "count": 34},
    {"roman": "Alhamdulillah", "urdu": "اَلْـحَمْـدُ للهِ", "count": 33},
    {"roman": "SubhanAllah", "urdu": "سُبْحَانَ اللّٰہ", "count": 33},
  ];

  int currentIndex = 0;
  int currentCount = 0;
  bool isEalTasbeehMode = true;

  // Unlimited mode variables
  int userLimitCount = 100; // default limit
  bool isVibrateOn = true;

  final TextEditingController _limitController = TextEditingController(text: '100');

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _incrementCounter() async {
    setState(() {
      currentCount++;
    });

    if (isEalTasbeehMode) {
      int targetCount = tasbeehList[currentIndex]['count'];
      if (currentCount >= targetCount) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }
        setState(() {
          currentCount = 0;
          currentIndex++;
          if (currentIndex >= tasbeehList.length) {
            currentIndex = 0;
          }
        });
      }
    } else {
      // Unlimited Mode with user limit & vibrate
      if (currentCount >= userLimitCount) {
        if (isVibrateOn && (await Vibration.hasVibrator() ?? false)) {
          Vibration.vibrate(duration: 1000);
        }
        setState(() {
          currentCount = 0;
        });
      }
    }
  }

  void _decrementCounter() {
    setState(() {
      if (currentCount > 0) currentCount--;
    });
  }

  void _resetCounter() {
    setState(() {
      currentCount = 0;
    });
  }

  void _setMode(bool ealTasbeehSelected) {
    setState(() {
      isEalTasbeehMode = ealTasbeehSelected;
      currentCount = 0;
      if (isEalTasbeehMode) {
        currentIndex = 0;
      }
    });
  }

  void _updateUserLimit(String value) {
    final int? parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      setState(() {
        userLimitCount = parsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentZikr = isEalTasbeehMode ? tasbeehList[currentIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tasbeeh Counter'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: _incrementCounter,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _setMode(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isEalTasbeehMode ? Colors.greenAccent.shade100 : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Tasbeeh Zehra(s)'),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton(
                    onPressed: () => _setMode(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      !isEalTasbeehMode ? Colors.greenAccent.shade100 : Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Unlimited Count'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.greenAccent.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isEalTasbeehMode
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          currentZikr!['roman'],
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 5),
                        Text(
                          currentZikr['urdu'],
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoNastaliqUrdu',
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        SizedBox(height: 20),
                        Text(
                          '$currentCount / ${currentZikr['count']}',
                          style: TextStyle(fontSize: 38),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Unlimited Count',
                          style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        Text(
                          '$currentCount',
                          style: TextStyle(fontSize: 60),
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

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show these inputs in Unlimited mode
            if (!isEalTasbeehMode)
              Row(
                children: [
                  // Limit Input Box styled like button
                  Expanded(
                    child: Container(
                      height: 50,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.shade100,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _limitController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          hintText: 'Count Limit',
                          hintStyle: TextStyle(color: Colors.black54),
                        ),
                        onChanged: _updateUserLimit,
                      ),
                    ),
                  ),

                  // Vibrate toggle styled like button
                  Container(
                    height: 50,
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade100,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Vibrate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Switch(
                          value: isVibrateOn,
                          onChanged: (val) {
                            setState(() {
                              isVibrateOn = val;
                            });
                          },
                          activeColor: Colors.greenAccent.shade100,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _decrementCounter,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.greenAccent.shade100,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove, color: Colors.black),
                        SizedBox(width: 8),
                        Text('Minus', style: TextStyle(fontSize: 20, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetCounter,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Reset',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
