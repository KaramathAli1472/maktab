import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle; // ← YE IMPORT ADD KAREIN
import 'dart:convert'; // ← YE IMPORT ADD KAREIN

class UpdateChecker {
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      print("🔄 Starting update check...");

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      String latestVersion = await getLatestVersionFromServer();

      print("📱 Current Version: $currentVersion");
      print("📱 Latest Version: $latestVersion");
      print("📱 Update Needed: ${currentVersion != latestVersion}");

      if (currentVersion != latestVersion) {
        print("🚨 Showing update dialog...");
        _showUpdateDialog(context);
      } else {
        print("✅ App is up to date");
      }
    } catch (e) {
      print("❌ Update check error: $e");
    }
  }

  static Future<String> getLatestVersionFromServer() async {
    try {
      // ✅ JSON FILE SE VERSION READ KAREN
      String jsonString = await rootBundle.loadString('assets/app_version.json');
      Map<String, dynamic> versionData = json.decode(jsonString);

      String latestVersion = versionData['latest_version'] ?? "1.0.3+14";
      bool forceUpdate = versionData['force_update'] ?? false;
      String updateMessage = versionData['update_message'] ?? "";

      print("📦 JSON se version mila: $latestVersion");
      print("📦 Force Update: $forceUpdate");
      print("📦 Message: $updateMessage");

      return latestVersion;
    } catch (e) {
      print("❌ JSON version check error: $e");
      return "1.0.3+14"; // Fallback
    }
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Update Available",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          content: Text("Please update your app to the latest version"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
            ElevatedButton(
              onPressed: () {
                _launchAppStore();
                Navigator.pop(context);
              },
              child: Text("Update"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  static void _launchAppStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.maktabe.sidratul.muntaha&hl=en_IN';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('❌ Could not launch $url');
    }
  }
}