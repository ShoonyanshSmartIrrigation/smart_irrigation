import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data_manager.dart';

class PlantService extends ChangeNotifier {
  static final PlantService _instance = PlantService._internal();
  factory PlantService() => _instance;
  PlantService._internal();

  final DataManager _dataManager = DataManager();

  // State
  bool isSyncing = false;
  bool isTogglingAll = false;
  bool allMotorsError = false;
  final Map<int, bool> plantConnectionErrors = {};
  
  Timer? _syncTimer;

  void init() {
    startSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void startSync() {
    fetchMoistureData();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchMoistureData();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  // Fetch moisture data from ESP32
  Future<bool> fetchMoistureData() async {
    if (isSyncing) return false;
    
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    
    if (ip == null || ip.isEmpty) {
      debugPrint("Moisture Sync: No ESP32 IP configured.");
      return false;
    }

    isSyncing = true;
    notifyListeners();

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
        isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // Error handled silently for periodic sync
    } finally {
      isSyncing = false;
      notifyListeners();
    }
    return false;
  }

  // Individual motor control
  Future<bool> togglePlantMotor(Plant plant, {bool? isOn}) async {
    bool targetState = isOn ?? !plant.isMotorOn;
    bool success = await _dataManager.togglePlantMotorApi(plant.id, targetState);

    if (success) {
      plantConnectionErrors[plant.id] = false;
    } else {
      // If connection fails, force the motor status to OFF in the app
      plant.isMotorOn = false;
      plantConnectionErrors[plant.id] = true;

      // Automatically clear the error highlight after 3 seconds
      Timer(const Duration(seconds: 3), () {
        plantConnectionErrors[plant.id] = false;
        notifyListeners();
      });
    }
    notifyListeners();
    return success;
  }

  // Master toggle for all motors
  Future<void> toggleAllMotors(bool value) async {
    isTogglingAll = true;
    allMotorsError = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) {
      isTogglingAll = false;
      allMotorsError = true;
      notifyListeners();
      return;
    }

    String url = "http://$ip:$port${value ? "/api/all/on" : "/api/all/off"}";

    try {
      final response = await http
          .post(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        for (var plant in _dataManager.plants) {
          plant.isMotorOn = value;
        }
        allMotorsError = false;
      } else {
        allMotorsError = true;
      }
    } catch (e) {
      debugPrint("Toggle All Error: $e");
      allMotorsError = true;
    } finally {
      isTogglingAll = false;
      notifyListeners();
    }
  }

  List<Plant> getPlants() => _dataManager.plants;
  int getActiveMotors() => _dataManager.activeMotors;
  int getTotalMotors() => _dataManager.totalMotors;
  int getAvgMoisture() => _dataManager.avgMoisture;
}
