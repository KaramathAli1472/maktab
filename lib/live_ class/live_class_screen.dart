// live_class_screen.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'call_screen.dart'; // ab use nahi ho raha to hata sakte ho
import 'call_screen_multi.dart';

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key});

  @override
  _LiveClassScreenState createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  final TextEditingController _meetingCodeController = TextEditingController();
  final TextEditingController _teacherNameController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();

  String _currentMeetingCode = '';
  bool _isTeacher = true;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _generateMeetingCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(
      6,
          (_) => chars[(DateTime.now().millisecond % chars.length)],
    );
    return random.join();
  }

  Future<void> _createMeeting() async {
    if (_teacherNameController.text.isEmpty ||
        _classNameController.text.isEmpty) {
      _showSnackBar("Please fill all fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _currentMeetingCode = _generateMeetingCode();

      await _firestore.collection('live_classes').doc(_currentMeetingCode).set({
        'teacherName': _teacherNameController.text,
        'className': _classNameController.text,
        'meetingCode': _currentMeetingCode,
        'createdAt': DateTime.now(),
        'teacherId': _auth.currentUser?.uid ?? 'anonymous',
        'status': 'active',
        'studentCount': 0,
      });

      _showSnackBar("Meeting created! Code: $_currentMeetingCode");

      // class create hote hi teacher ko CallScreenMulti par le jao
      _openLiveClass({
        'className': _classNameController.text,
        'teacherName': _teacherNameController.text,
        'meetingCode': _currentMeetingCode,
      });
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinMeeting() async {
    if (_meetingCodeController.text.isEmpty) {
      _showSnackBar("Please enter meeting code");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore
          .collection('live_classes')
          .doc(_meetingCodeController.text.toUpperCase())
          .get();

      if (!doc.exists) {
        _showSnackBar("Invalid meeting code");
        return;
      }

      final meetingData = doc.data()!;
      await _showJoinConfirmationDialog(meetingData);
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showJoinConfirmationDialog(
      Map<String, dynamic> meetingData) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Class Details"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Subject: ${meetingData['className']}"),
                Text("Teacher: ${meetingData['teacherName']}"),
                const SizedBox(height: 10),
                const Text(
                  "Do you want to join this class?",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text("Yes, Join"),
              onPressed: () {
                Navigator.of(context).pop();
                _openLiveClass(meetingData);
              },
            ),
          ],
        );
      },
    );
  }

  void _openLiveClass(Map<String, dynamic> meetingData) {
    final roomId = meetingData['meetingCode'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreenMulti(
          roomId: roomId,
          selfId: _auth.currentUser!.uid, // Firebase UID
          isTeacher: _isTeacher,
          userName: _isTeacher
              ? _teacherNameController.text
              : _auth.currentUser?.displayName ?? 'Student',
          className: meetingData['className'] ?? '',
        ),
      ),
    );
  }

  void _shareMeetingCode() {
    if (_currentMeetingCode.isEmpty) {
      _showSnackBar("No meeting created yet");
      return;
    }

    Share.share(
      'Join my live class!\n\n'
          'Subject: ${_classNameController.text}\n'
          'Teacher: ${_teacherNameController.text}\n'
          'Meeting Code: $_currentMeetingCode\n\n'
          'Open the app and enter this code to join.',
      subject: 'Live Class Invitation - ${_classNameController.text}',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Live Classroom"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          if (_currentMeetingCode.isNotEmpty)
            IconButton(
              onPressed: _shareMeetingCode,
              icon: const Icon(Icons.share),
              tooltip: "Share Meeting Code",
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading..."),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildRoleCard(),
            const SizedBox(height: 25),
            if (_isTeacher) _buildTeacherCard(),
            if (!_isTeacher) _buildStudentCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Your Role",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isTeacher = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color:
                        _isTeacher ? Colors.blue[50] : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isTeacher
                              ? Colors.blue
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.school,
                            size: 40,
                            color: _isTeacher ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Teacher",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                              _isTeacher ? Colors.blue : Colors.grey,
                            ),
                          ),
                          Text(
                            "Create new class",
                            style: TextStyle(
                              fontSize: 12,
                              color: _isTeacher
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isTeacher = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: !_isTeacher
                            ? Colors.green[50]
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_isTeacher
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            size: 40,
                            color: !_isTeacher ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Student",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                              !_isTeacher ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            "Join existing class",
                            style: TextStyle(
                              fontSize: 12,
                              color: !_isTeacher
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTeacherCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.school, color: Colors.blue, size: 30),
                SizedBox(width: 10),
                Text(
                  "Create New Class",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _teacherNameController,
              decoration: InputDecoration(
                labelText: "Your Name",
                hintText: "Enter teacher name",
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _classNameController,
              decoration: InputDecoration(
                labelText: "Subject / Class Name",
                hintText: "e.g., Quran, Arabic, Mathematics",
                prefixIcon: const Icon(Icons.menu_book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _createMeeting,
              icon: const Icon(Icons.video_call),
              label: const Text(
                "Create Class Meeting",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
            if (_currentMeetingCode.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildMeetingCreatedBox(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCreatedBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 50),
          const SizedBox(height: 10),
          const Text(
            "Meeting Created Successfully!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Share this code with students:",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: SelectableText(
              _currentMeetingCode,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 3,
                fontFamily: 'Monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Students will join using this code",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text(
                  "Join Class",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Enter the code provided by your teacher",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _meetingCodeController,
              decoration: InputDecoration(
                labelText: "Meeting Code",
                hintText: "e.g., ABC123",
                prefixIcon: const Icon(Icons.code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 2,
                fontFamily: 'Monospace',
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _joinMeeting,
              icon: const Icon(Icons.video_call),
              label: const Text(
                "Join Live Class",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
