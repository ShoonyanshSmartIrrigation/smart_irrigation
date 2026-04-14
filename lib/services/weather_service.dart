import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CityService {
  static const String key = "City";

  static Future<void> saveCity(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, name);
  }

  static Future<String?> getCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}

// ================= WEATHER API =================
class WeatherService {
  static const String apiKey = "aaf10de736fe5c3690a1d341be26e920";

  static Future<Map<String, dynamic>?> fetchWeather(String City) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$City&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching weather: $e");
    }
    return null;
  }
}