import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final AuthService _authService = AuthService();

  // State
  int minMoisture = 30;
  int maxMoisture = 70;
  String esp32Ip = "Not Set";
  String userName = "User";
  String userEmail = "user@example.com";

  Future<void> init() async {
    await loadSettings();
    await loadUserData();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    minMoisture = prefs.getInt("min_moisture") ?? 30;
    maxMoisture = prefs.getInt("max_moisture") ?? 70;
    esp32Ip = prefs.getString("esp_ip") ?? "Not Set";
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final userData = await _authService.getUserData();
    userName = userData['userName'] ?? "User";
    userEmail = userData['userEmail'] ?? "No Email";
    notifyListeners();
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
    
    // Refresh local state
    if (key == "min_moisture") minMoisture = value;
    if (key == "max_moisture") maxMoisture = value;
    if (key == "esp_ip") esp32Ip = value;
    
    notifyListeners();
  }

  bool isValidIp(String ip) {
    final regex = RegExp(r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$');
    return regex.hasMatch(ip);
  }

  Future<void> logout() async {
    await _authService.logout();
    // SharedPreferences is cleared in AuthService.logout()
  }

  String getInitials() {
    if (userName.isEmpty) return "US";
    List<String> parts = userName.trim().split(" ");
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (userName.length >= 2) {
      return userName.substring(0, 2).toUpperCase();
    }
    return userName.isNotEmpty ? userName[0].toUpperCase() : "U";
  }
}
