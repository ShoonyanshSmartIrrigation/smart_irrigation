import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

//-------------------------------------------------------- WeatherService Class ----------------------------------------------------------
class WeatherService {
  final String _apiKey = "aaf10de736fe5c3690a1d341be26e920";

  Future<Map<String, dynamic>?> fetchWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {"error": "Location Disabled. Please turn on GPS."};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {"error": "Location Permission Denied."};
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return {"error": "Location Permission Permanently Denied."};
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        )
      );
      
      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {"error": "Weather API failed: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": "Failed to get location."};
    }
  }
}


