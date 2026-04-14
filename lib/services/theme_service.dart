import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  late SharedPreferences _prefs;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    _initialized = true;
    notifyListeners();
  }

  void toggleTheme(bool value) {
    _isDarkMode = value;
    _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}
