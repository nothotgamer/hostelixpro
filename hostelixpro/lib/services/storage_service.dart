import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyToken = 'auth_token';


  /// Save theme mode preference (light/dark)
  static Future<void> saveThemeMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Get saved theme mode
  static Future<String?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyThemeMode);
    } catch (e) {
      debugPrint('Error getting theme mode: $e');
      return null;
    }
  }

  /// Save auth token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  /// Get auth token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  /// Delete auth token
  static Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }
}

