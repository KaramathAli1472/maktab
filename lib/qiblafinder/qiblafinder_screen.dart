import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';

class QiblaFinderPage extends StatefulWidget {
  const QiblaFinderPage({super.key});

  @override
  State<QiblaFinderPage> createState() => _QiblaFinderPageState();
}

class _QiblaFinderPageState extends State<QiblaFinderPage> {
  double? _direction; // Compass direction
  double _qiblaDirection = 0.0; // Qibla angle
  Position? _currentPosition; // GPS Location

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _listenToCompass();
  }

  // Compass Listener
  void _listenToCompass() {
    FlutterCompass.events?.listen((event) {
      if (event != null && event.heading != null) {
        setState(() {
          _direction = event.heading;
        });
      }
    });
  }

  // Function to get GPS location
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("GPS disabled. Please enable location services.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar("Location permission permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _currentPosition = position;
      _qiblaDirection = _calculateQiblaAngle(
        position.latitude,
        position.longitude,
      );
    });
  }

  // Function to calculate Qibla direction
  double _calculateQiblaAngle(double latitude, double longitude) {
    const double makkahLatitude = 21.4225;
    const double makkahLongitude = 39.8262;

    double latRadians = _toRadians(latitude);
    double longRadians = _toRadians(longitude);
    double makkahLatRadians = _toRadians(makkahLatitude);
    double makkahLongRadians = _toRadians(makkahLongitude);

    double deltaLong = makkahLongRadians - longRadians;

    double angle = atan2(
      sin(deltaLong),
      (cos(latRadians) * tan(makkahLatRadians)) - (sin(latRadians) * cos(deltaLong)),
    );

    return (_toDegrees(angle) + 360) % 360;
  }

  // Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Convert radians to degrees
  double _toDegrees(double radians) {
    return radians * (180 / pi);
  }

  // Show Snackbar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        centerTitle: true,
        title: const Text(
          "Qibla Finder",
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white, // jaise pehle tha
        elevation: 0, // jaise pehle tha
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_direction != null)
              Transform.rotate(
                angle: ((_direction! - _qiblaDirection) * (pi / 180)) * -1,
                child: Image.asset(
                  'assets/compass.png',
                  width: 250,
                  height: 250,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Qibla: ${_qiblaDirection.toStringAsFixed(2)}°',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
