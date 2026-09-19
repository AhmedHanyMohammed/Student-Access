import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _customHostKey = 'custom_api_host';
  
  // Default port configured in .NET backend
  static const int defaultPort = 5184;

  /// Returns the base URL for the backend API.
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customHostKey);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }

    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    }

    try {
      if (Platform.isAndroid) {
        // 10.0.2.2 is the special alias to your host loopback interface on Android Emulator
        return 'http://10.0.2.2:$defaultPort';
      } else if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return 'http://localhost:$defaultPort';
      }
    } catch (_) {}

    return 'http://10.0.2.2:$defaultPort';
  }

  /// Helper to allow setting a custom IP (e.g. "http://192.168.1.50:5184") for real phone testing
  static Future<void> setCustomBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_customHostKey);
    } else {
      await prefs.setString(_customHostKey, url.trim());
    }
  }
}
