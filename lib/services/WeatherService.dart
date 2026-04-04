import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartirrigation/entity/WeatherModel.dart';
import 'dart:convert';

class WeatherService {
  static const String apiKey = "aaf10de736fe5c3690a1d341be26e920";

  Future<WeatherModel?> fetchWeather(double lat, double lon) async {
    try {
      final url =
          "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Weather fetch error: $e");
    }
    return null;
  }
}
