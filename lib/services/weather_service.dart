import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CityService {
  static const String key = "City";
  static const String latKey = "CityLat";
  static const String lonKey = "CityLon";

  static Future<void> saveCity(String name, {double? lat, double? lon}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, name);
    if (lat != null) {
      await prefs.setDouble(latKey, lat);
    } else {
      await prefs.remove(latKey);
    }
    if (lon != null) {
      await prefs.setDouble(lonKey, lon);
    } else {
      await prefs.remove(lonKey);
    }
  }

  static Future<Map<String, dynamic>> getCityInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(key),
      'lat': prefs.getDouble(latKey),
      'lon': prefs.getDouble(lonKey),
    };
  }

  static Future<String?> getCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}

// ================= WEATHER API =================
class WeatherService {
  static const String apiKey = "aaf10de736fe5c3690a1d341be26e920";

  static Future<List<Map<String, dynamic>>> fetchCitySuggestions(String query) async {
    if (query.length < 2) return [];
    final url = "https://api.openweathermap.org/geo/1.0/direct?q=$query,IN&limit=10&appid=$apiKey";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final seen = <String>{};
        final List<Map<String, dynamic>> uniqueSuggestions = [];

        for (var item in data) {
          final name = item['name'];
          final state = item['state'] ?? '';
          final key = "$name-$state".toLowerCase();

          if (!seen.contains(key)) {
            seen.add(key);
            uniqueSuggestions.add({
              'name': name,
              'country': item['country'],
              'state': state,
              'lat': item['lat'],
              'lon': item['lon'],
            });
          }
        }
        return uniqueSuggestions;
      }
    } catch (e) {
      debugPrint("Error fetching city suggestions: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchWeatherByCoords(double lat, double lon) async {
    final url = "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error fetching weather by coords: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchWeather(String city) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

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