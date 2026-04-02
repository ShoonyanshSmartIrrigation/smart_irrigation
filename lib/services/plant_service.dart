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
  DateTime? lastUpdated;
  final Map<int, bool> plantConnectionErrors = {};
  final Map<int, bool> _isProcessingToggle = {};
  
  Timer? _syncTimer;
  bool _isDisposed = false;

  void init() {
    startSync();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void startSync() {
    fetchMoistureData();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchMoistureData();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  Future<String?> _getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? ip = prefs.getString("esp_ip");
      int port = prefs.getInt("esp_port") ?? 80;
      if (ip == null || ip.isEmpty) return null;
      return "http://$ip:$port";
    } catch (e) {
      return null;
    }
  }

  // Fetch moisture data from ESP32 with Retry Strategy
  Future<bool> fetchMoistureData({int retry = 2}) async {
    if (isSyncing || _isDisposed) return false;
    
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      debugPrint("Moisture Sync: No ESP32 IP configured.");
      return false;
    }

    isSyncing = true;
    notifyListeners();

    try {
      final res = await http
          .get(Uri.parse("$baseUrl/api/moisture"))
          .timeout(const Duration(seconds: 2));
      
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);

        for (var plant in _dataManager.plants) {
          String sensorKey = "sensor_${plant.id}";
          if (data.containsKey(sensorKey)) {
            int newMoisture = data[sensorKey]?["percent"] ?? plant.moistureLevel;
            if (plant.moistureLevel != newMoisture) {
              plant.moistureLevel = newMoisture;
            }
            
              // Auto Mode logic based on thresholds
              if (plant.isAutoMode && !_dataManager.isSystemAutoMode) {
                if (plant.moistureLevel < plant.minMoistureThreshold && !plant.isMotorOn) {
                  togglePlantMotor(plant, isOn: true);
                } else if (plant.moistureLevel >= plant.maxMoistureThreshold && plant.isMotorOn) {
                  togglePlantMotor(plant, isOn: false);
                }
              }
          }
        }
        
        lastUpdated = DateTime.now();
        isSyncing = false;
        notifyListeners(); // Notify once after all updates
        return true;
      } else {
        throw Exception("Server Error: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Moisture Sync Attempt Failed: $e");
      if (retry > 0 && !_isDisposed) {
        isSyncing = false; // Reset to allow retry
        return fetchMoistureData(retry: retry - 1);
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
    return false;
  }

  // Individual motor control with Debounce
  Future<bool> togglePlantMotor(Plant plant, {bool? isOn}) async {
    if (_isProcessingToggle[plant.id] == true || _isDisposed) return false;
    
    _isProcessingToggle[plant.id] = true;
    bool targetState = isOn ?? !plant.isMotorOn;
    
    notifyListeners();

    try {
      bool success = await _dataManager.togglePlantMotorApi(plant.id, targetState)
          .timeout(const Duration(seconds: 5));

      if (success) {
        plantConnectionErrors[plant.id] = false;
      } else {
        _handlePlantError(plant);
      }
      return success;
    } catch (e) {
      _handlePlantError(plant);
      return false;
    } finally {
      _isProcessingToggle[plant.id] = false;
      notifyListeners();
    }
  }

  void _handlePlantError(Plant plant) {
    plant.isMotorOn = false; // Safe fallback
    plantConnectionErrors[plant.id] = true;

    // Auto-clear error after 3s
    Timer(const Duration(seconds: 3), () {
      if (!_isDisposed) {
        plantConnectionErrors[plant.id] = false;
        notifyListeners();
      }
    });
  }

  // Master toggle for all motors
  Future<void> toggleAllMotors(bool value) async {
    if (isTogglingAll || _isDisposed) return;
    
    isTogglingAll = true;
    allMotorsError = false;
    notifyListeners();

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      isTogglingAll = false;
      allMotorsError = true;
      notifyListeners();
      return;
    }

    try {
      final response = await http
          .post(Uri.parse("$baseUrl/api/all/${value ? 'on' : 'off'}"))
          .timeout(const Duration(seconds: 7));

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
