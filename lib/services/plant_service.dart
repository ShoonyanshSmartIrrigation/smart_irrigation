import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data_manager.dart';

class PlantService {
  static final PlantService _instance = PlantService._internal();
  factory PlantService() => _instance;
  PlantService._internal();

  final DataManager _dataManager = DataManager();

  // Fetch moisture data from ESP32
  Future<bool> fetchMoistureData() async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    
    if (ip == null || ip.isEmpty) {
      print("Moisture Sync: No ESP32 IP configured.");
      return false;
    }

    try {
      final res = await http
          .get(Uri.parse("http://$ip:$port/api/moisture"))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        for (var plant in _dataManager.plants) {
          String sensorKey = "sensor_${plant.id}";
          if (data.containsKey(sensorKey)) {
            plant.moistureLevel = data[sensorKey]["percent"];
          }
        }
        return true;
      }
    } catch (e) {
      // Avoid printing the error every few seconds if it's the same unreachable network
    }
    return false;
  }

  // Individual motor control
  Future<bool> togglePlantMotor(int id, bool isOn) async {
    return await _dataManager.togglePlantMotorApi(id, isOn);
  }

  // Master toggle for all motors
  Future<bool> toggleAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url = "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";

    try {
      final response = await http
          .post(Uri.parse(url))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print("Toggle All Error: $e");
      return false;
    }
  }

  List<Plant> getPlants() => _dataManager.plants;

  int getActiveMotors() => _dataManager.activeMotors;
  int getTotalMotors() => _dataManager.totalMotors;
  int getAvgMoisture() => _dataManager.avgMoisture;
}
