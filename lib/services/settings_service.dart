import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "min_moisture": prefs.getInt("min_moisture") ?? 30,
      "max_moisture": prefs.getInt("max_moisture") ?? 70,
      "timer_minutes": prefs.getInt("timer_minutes") ?? 5,
      "esp_ip": prefs.getString("esp_ip") ?? "Not Set",
    };
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
  }

  bool isValidIp(String ip) {
    final regex = RegExp(r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$');
    return regex.hasMatch(ip);
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
  }
}
