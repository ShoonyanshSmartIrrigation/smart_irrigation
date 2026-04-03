import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

//-------------------------------------------------------- Plant Class ----------------------------------------------------------
class Plant {
  final int id;
  final String name;
  int moistureLevel;
  bool isMotorOn;
  bool isAutoMode;
  int minMoistureThreshold;
  int maxMoistureThreshold;

  Plant({
    required this.id,
    required this.name,
    required this.moistureLevel,
    required this.isMotorOn,
    required this.isAutoMode,
    required this.minMoistureThreshold,
    required this.maxMoistureThreshold,
  });
}

//-------------------------------------------------------- DataManager Class ----------------------------------------------------------
class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  bool isSystemAutoMode = false;

  List<Plant> plants = List.generate(8, (index) {
    return Plant(
      id: index + 1,
      name: "Plant ${index + 1}",
      moistureLevel: 0,
      isMotorOn: false,
      isAutoMode: false,
      minMoistureThreshold: 30,
      maxMoistureThreshold: 70,
    );
  });

  bool mainMotorOn = false;

  int get activeMotors => plants.where((p) => p.isMotorOn).length;
  int get totalMotors => plants.length;
  
  int get avgMoisture {
    if (plants.isEmpty) return 0;
    return (plants.map((p) => p.moistureLevel).reduce((a, b) => a + b) / plants.length).toInt();
  }

  // Control Main Motor on ESP32
  Future<bool> toggleMainMotor(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) {
      print("DataManager: No IP configured for ESP32");
      return false;
    }

    String url = "http://$ip:$port${isOn ? "/api/mainmotor/on" : "/api/mainmotor/off"}";
    print("DataManager: Sending Request -> POST $url");

    try {
      final response = await http.post(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      
      print("DataManager: Response Received -> Status: ${response.statusCode}, Body: ${response.body}");
      
      if (response.statusCode == 200) {
        mainMotorOn = isOn;
        return true;
      }
    } catch (e) {
      print("DataManager: Error during request -> $e");
    }
    return false;
  }

  // Master Control for All Motors
  Future<bool> toggleAllMotorsApi(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url = "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";
    try {
      final response = await http.post(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        updateAllMotorsLocally(isOn);
        return true;
      }
    } catch (e) {
      print("DataManager: Master Control Error -> $e");
    }
    return false;
  }

  // New method to update all motors locally
  void updateAllMotorsLocally(bool isOn) {
    for (var plant in plants) {
      plant.isMotorOn = isOn;
    }
  }

  // Control Individual Plant Motor on ESP32
  Future<bool> togglePlantMotorApi(int id, bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url = "http://$ip:$port${isOn ? "/api/motor/on" : "/api/motor/off"}?motor_id=$id";
    try {
      final response = await http.post(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        int index = plants.indexWhere((p) => p.id == id);
        if (index != -1) {
          plants[index].isMotorOn = isOn;
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> checkConnection() async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    try {
      final response = await http.get(Uri.parse("http://$ip:$port/api/system/status"))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void updatePlantMotor(int id, bool isOn) {
    int index = plants.indexWhere((p) => p.id == id);
    if (index != -1) {
      plants[index].isMotorOn = isOn;
    }
  }

  // void simulateMoisture() {
  //   for (var plant in plants) {
  //     plant.moistureLevel = 30 + Random().nextInt(40);
  //   }
  // }
}
