import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  Map<DateTime, List<Map<String, dynamic>>> _islamicEvents = {};

  @override
  void initState() {
    super.initState();
    _listenToEvents();
    _fetchIslamicCalendarData();
  }

  void _listenToEvents() {
    _firestore.collection('islamiccalendarMenu').snapshots().listen((snapshot) {
      Map<DateTime, List<Map<String, dynamic>>> eventMap = {};

      for (var doc in snapshot.docs) {
        try {
          String dateStr = doc['date'];
          DateTime date = DateTime.parse(dateStr);
          Map<String, dynamic> event = {
            'name': doc['name'],
            'description': doc['description'],
            'event_type': doc['event_type'],
            'is_important': doc['is_important'],
          };
          DateTime normalizedDate = DateTime(date.year, date.month, date.day);
          eventMap[normalizedDate] = eventMap[normalizedDate] ?? [];
          eventMap[normalizedDate]!.add(event);
        } catch (e) {
          print("❌ Error parsing Firestore data: $e");
        }
      }

      setState(() {
        _events = eventMap;
      });
    });
  }

  Future<void> _fetchIslamicCalendarData() async {
    final now = DateTime.now();
    final formattedDate = "${now.day}-${now.month}-${now.year}";
    final url = 'http://api.aladhan.com/v1/gToH?date=$formattedDate';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            _islamicEvents[DateTime(now.year, now.month, now.day)] = [
              {
                'name': 'Islamic Event (Aladhan)',
                'description': 'Converted Hijri Date: ${data['data']['hijri']['date']}',
                'event_type': 'info',
                'is_important': false,
              }
            ];
          });
        }
      } else {
        print("❌ Failed to load Aladhan data.");
      }
    } catch (e) {
      print("❌ Error fetching Islamic data: $e");
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return [
      ...?_events[d],
      ...?_islamicEvents[d],
    ];
  }

  String getHijriMonthName(int monthNumber) {
    const hijriMonths = [
      '', // index 0 placeholder
      'Muharram',
      'Safar',
      'Rabi al-Awwal',
      'Rabi al-Thani',
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      'Sha’ban',
      'Ramadan',
      'Shawwal',
      'Dhu l Qa’dah',
      'Dhu al Hajjah'
    ];
    return hijriMonths[monthNumber];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              List<Map<String, dynamic>> eventsForDay = _getEventsForDay(selectedDay);
              if (eventsForDay.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text("Events on ${selectedDay.toLocal().toString().split(' ')[0]}"),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: eventsForDay.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("📌 ${event['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("📖 ${event['description']}"),
                                if (event['is_important'] == true)
                                  Text("⭐ Important", style: TextStyle(color: Colors.red)),
                                Divider(),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Close"),
                      )
                    ],
                  ),
                );
              }
            },
            eventLoader: _getEventsForDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            rowHeight: 80,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.deepOrange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextFormatter: (date, locale) {
                final hijriDate = HijriCalendar.fromDate(date);
                final hijriMonth = getHijriMonthName(hijriDate.hMonth);
                final hijriYear = hijriDate.hYear;

                final gregorianMonth = "${DateFormat.MMMM().format(date)} ${date.year}";

                return "$gregorianMonth\n$hijriMonth $hijriYear"; // 🔥 New line
              },
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            daysOfWeekHeight: 40,
            daysOfWeekStyle: DaysOfWeekStyle(
              decoration: BoxDecoration(
                color: Colors.teal[50],
              ),
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
                fontSize: 16,
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final hijri = HijriCalendar.fromDate(day.subtract(Duration(days: 1)));
                final eventsForDay = _getEventsForDay(day);
                final hasShahadatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'shahadat');
                final hasWiladatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'wiladat');

                Color backgroundColor;
                if (hasShahadatEvent) {
                  backgroundColor = Colors.teal;
                } else if (hasWiladatEvent) {
                  backgroundColor = Color(0xFFFFCCCC);
                } else {
                  backgroundColor = Colors.transparent;
                }

                return Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text("${day.day}", style: TextStyle(fontWeight: FontWeight.bold, color: hasShahadatEvent ? Colors.white : Colors.black)),
                      Text("${hijri.hDay}", style: TextStyle(fontSize: 12, color: hasShahadatEvent ? Colors.white : Colors.black)),
                    ],
                  ),
                );
              },
              todayBuilder: (context, day, _) {
                final hijri = HijriCalendar.fromDate(day.subtract(Duration(days: 1)));
                final eventsForDay = _getEventsForDay(day);
                final hasShahadatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'shahadat');
                final hasWiladatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'wiladat');

                Color backgroundColor;
                if (hasShahadatEvent) {
                  backgroundColor = Colors.teal;
                } else if (hasWiladatEvent) {
                  backgroundColor = Color(0xFFFFCCCC);
                } else {
                  backgroundColor = Colors.teal[100]!;
                }

                return Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text("${day.day}", style: TextStyle(fontWeight: FontWeight.bold, color: hasShahadatEvent ? Colors.white : Colors.black)),
                      Text("${hijri.hDay}", style: TextStyle(fontSize: 12, color: hasShahadatEvent ? Colors.white : Colors.black)),
                    ],
                  ),
                );
              },
              selectedBuilder: (context, day, _) {
                final hijri = HijriCalendar.fromDate(day.subtract(Duration(days: 1)));
                final eventsForDay = _getEventsForDay(day);
                final hasShahadatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'shahadat');
                final hasWiladatEvent = eventsForDay.any((event) => (event['event_type'] ?? '').toString().toLowerCase() == 'wiladat');

                Color backgroundColor;
                if (hasShahadatEvent) {
                  backgroundColor = Colors.teal;
                } else if (hasWiladatEvent) {
                  backgroundColor = Color(0xFFFFCCCC);
                } else {
                  backgroundColor = Colors.teal[100]!;
                }

                return Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text("${day.day}", style: TextStyle(fontWeight: FontWeight.bold, color: hasShahadatEvent ? Colors.white : Colors.black)),
                      Text("${hijri.hDay}", style: TextStyle(fontSize: 12, color: hasShahadatEvent ? Colors.white : Colors.black)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
