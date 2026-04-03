import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

//-------------------------------------------------------- SettingsService Class ----------------------------------------------------------
class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  final AuthService _authService = AuthService();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // State
  int minMoisture = 30;
  int maxMoisture = 70;
  String esp32Ip = "Not Set";
  String userName = "User";
  String userEmail = "user@example.com";
  bool isLoading = false;

  Future<void> init() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      
      // Batch load data without multiple notifyListeners calls
      await Future.wait([
        _loadSettingsInternal(),
        _loadUserDataInternal(),
      ]);
    } catch (e) {
      debugPrint("SettingsService Init Error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSettings() async {
    if (!_isInitialized) await init();
    isLoading = true;
    notifyListeners();
    
    await _loadSettingsInternal();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadSettingsInternal() async {
    try {
      minMoisture = _prefs.getInt("min_moisture") ?? 30;
      maxMoisture = _prefs.getInt("max_moisture") ?? 70;
      esp32Ip = _prefs.getString("esp_ip") ?? "Not Set";
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> loadUserData() async {
    isLoading = true;
    notifyListeners();
    
    await _loadUserDataInternal();
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserDataInternal() async {
    try {
      final userData = await _authService.getUserData();
      userName = userData['userName'] ?? "User";
      userEmail = userData['userEmail'] ?? "No Email";
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  // Type-safe update methods with validation
  Future<void> updateMinMoisture(int value) async {
    if (value < 0 || value >= maxMoisture) {
      debugPrint("Invalid Min Moisture: $value. Must be >= 0 and < $maxMoisture");
      return;
    }
    await _saveInt("min_moisture", value);
    minMoisture = value;
    notifyListeners();
  }

  Future<void> updateMaxMoisture(int value) async {
    if (value <= minMoisture || value > 100) {
      debugPrint("Invalid Max Moisture: $value. Must be > $minMoisture and <= 100");
      return;
    }
    await _saveInt("max_moisture", value);
    maxMoisture = value;
    notifyListeners();
  }

  Future<void> updateEspIp(String value) async {
    if (!isValidIp(value)) {
      debugPrint("Invalid IP Address: $value");
      return;
    }
    await _saveString("esp_ip", value);
    esp32Ip = value;
    notifyListeners();
  }

  // Generic update for other settings if needed, but preferred typed methods
  Future<void> updateSetting(String key, dynamic value) async {
    if (key == "min_moisture" && value is int) {
      await updateMinMoisture(value);
    } else if (key == "max_moisture" && value is int) {
      await updateMaxMoisture(value);
    } else if (key == "esp_ip" && value is String) {
      await updateEspIp(value);
    } else {
      try {
        if (value is int) await _prefs.setInt(key, value);
        if (value is String) await _prefs.setString(key, value);
        if (value is bool) await _prefs.setBool(key, value);
        notifyListeners();
      } catch (e) {
        debugPrint("Error updating setting $key: $e");
      }
    }
  }

  Future<void> _saveInt(String key, int value) async {
    try {
      await _prefs.setInt(key, value);
    } catch (e) {
      debugPrint("Error saving int $key: $e");
    }
  }

  Future<void> _saveString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
    } catch (e) {
      debugPrint("Error saving string $key: $e");
    }
  }

  bool isValidIp(String ip) {
    if (ip.isEmpty || ip == "Not Set") return false;
    final regex = RegExp(r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$');
    return regex.hasMatch(ip);
  }

  Future<void> logout() async {
    try {
      await _authService.logout();

      // Reset local state to defaults
      minMoisture = 30;
      maxMoisture = 70;
      esp32Ip = "Not Set";
      userName = "User";
      userEmail = "";
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  String getInitials() {
    if (userName.isEmpty) return "US";
    try {
      List<String> parts = userName.trim().split(" ");
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (userName.length >= 2) {
        return userName.substring(0, 2).toUpperCase();
      }
      return userName.isNotEmpty ? userName[0].toUpperCase() : "U";
    } catch (e) {
      return "US";
    }
  }
}
