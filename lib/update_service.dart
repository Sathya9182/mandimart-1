
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const String _remoteConfigKey = 'latest_version';

  static Future<void> checkForUpdate(BuildContext context) async {
    // Prevent this from running in debug mode
    if (const bool.fromEnvironment('dart.vm.product')) {
      try {
        final remoteConfig = FirebaseRemoteConfig.instance;
        await remoteConfig.fetchAndActivate();

        final String latestVersion = remoteConfig.getString(_remoteConfigKey);
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final String currentVersion = packageInfo.version;

        if (latestVersion.isNotEmpty && _isUpdateAvailable(currentVersion, latestVersion)) {
          _showUpdateDialog(context);
        }
      } catch (e) {
        debugPrint("Error checking for update: $e");
      }
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    final List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
    final List<int> latestParts = latestVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: const Text('A new version of the app is available. Please update to continue.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Update Now'),
              onPressed: () {
                _launchURL('https://play.google.com/store/apps/details?id=com.mandimart.app'); // Replace with your app's store URL
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
