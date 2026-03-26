// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import '../data_manager.dart';
//
// class PlantService {
//   static final PlantService _instance = PlantService._internal();
//   factory PlantService() => _instance;
//   PlantService._internal();
//
//   final DataManager _dataManager = DataManager();
//
//   Future<bool> fetchMoistureData() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? espIp = prefs.getString("esp_ip");
//     if (espIp == null || espIp.isEmpty) return false;
//
//     try {
//       final res = await http.get(Uri.parse("http://$espIp/api/moisture"))
//           .timeout(const Duration(seconds: 3));
//
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         for (var sensor in data["sensors"]) {
//           int id = sensor["sensor_id"];
//           int moisture = sensor["moisture"];
//
//           int index = _dataManager.plants.indexWhere((p) => p.id == id);
//           if (index != -1) {
//             _dataManager.plants[index].moistureLevel = moisture;
//           }
//         }
//         return true;
//       }
//     } catch (e) {
//       print("PlantService: Moisture Sync Error: $e");
//     }
//     return false;
//   }
//
//   Future<bool> togglePlantMotor(int id, bool isOn) async {
//     return await _dataManager.togglePlantMotorApi(id, isOn);
//   }
//
//   Future<bool> toggleAllMotors(bool isOn) async {
//     final prefs = await SharedPreferences.getInstance();
//     String? ip = prefs.getString("esp_ip");
//     int port = prefs.getInt("esp_port") ?? 80;
//
//     if (ip == null || ip.isEmpty) return false;
//
//     String url = "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";
//
//     try {
//       final response = await http
//           .post(Uri.parse(url))
//           .timeout(const Duration(seconds: 3));
//
//       return response.statusCode == 200; // ✅ ONLY RETURN RESULT
//     } catch (e) {
//       print("Toggle All Error: $e");
//       return false;
//     }
//   }
//
//   List<Plant> getPlants() {
//     return _dataManager.plants;
//   }
//
//   int getActiveMotors() => _dataManager.activeMotors;
//   int getTotalMotors() => _dataManager.totalMotors;
//   int getAvgMoisture() => _dataManager.avgMoisture;
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data_manager.dart';

class PlantService {
  static final PlantService _instance = PlantService._internal();
  factory PlantService() => _instance;
  PlantService._internal();

  final DataManager _dataManager = DataManager();

  // ✅ Only moisture sync (no motor control here)
  Future<bool> fetchMoistureData() async {
    final prefs = await SharedPreferences.getInstance();
    String? espIp = prefs.getString("esp_ip");
    if (espIp == null || espIp.isEmpty) return false;

    try {
      final res = await http
          .get(Uri.parse("http://$espIp/api/moisture"))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        for (var sensor in data["sensors"]) {
          int id = sensor["sensor_id"];
          int moisture = sensor["moisture"];

          int index =
          _dataManager.plants.indexWhere((p) => p.id == id);
          if (index != -1) {
            _dataManager.plants[index].moistureLevel = moisture;
          }
        }
        return true;
      }
    } catch (e) {
      print("Moisture Sync Error: $e");
    }
    return false;
  }

  // Individual motor
  Future<bool> togglePlantMotor(int id, bool isOn) async {
    return await _dataManager.togglePlantMotorApi(id, isOn);
  }

  // ✅ MASTER TOGGLE (CLEAN)
  Future<bool> toggleAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url =
        "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";

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