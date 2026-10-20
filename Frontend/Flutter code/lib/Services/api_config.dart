import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _customHostKey = 'custom_api_host';

  // Production Render URL
  static const String productionUrl =
      'https://student-access-b0j9.onrender.com';

  /// Returns the base URL for the backend API.
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getString(_customHostKey);
    if (custom != null && custom.trim().isNotEmpty) {
      return custom.trim();
    }

    return productionUrl;
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
