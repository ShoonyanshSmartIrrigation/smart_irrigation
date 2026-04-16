import 'dart:async';
import 'package:flutter/material.dart';
import '../data_manager.dart';
import 'communications/wifi_service.dart';
import 'communications/unified_command_service.dart';

//-------------------------------------------------------- PlantService Class ----------------------------------------------------------
class PlantService extends ChangeNotifier {
  static final PlantService _instance = PlantService._internal();
  factory PlantService() => _instance;
  PlantService._internal();

  final DataManager _dataManager = DataManager();
  final WifiService _wifiService = WifiService();
  final UnifiedCommandService _unifiedCommandService = UnifiedCommandService();

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
  //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
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
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchMoistureData();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  // Fetch moisture data from ESP32 or Firebase
  Future<bool> fetchMoistureData({int retry = 1}) async {
    if (isSyncing || _isDisposed) return false;

    isSyncing = true;
    notifyListeners();

    try {
      final data = await _wifiService.getMoistureData();
      if (data != null) {
        for (var plant in _dataManager.plants) {
          String sensorKey = "sensor_${plant.id}";
          if (data.containsKey(sensorKey)) {
            int newMoisture =
                data[sensorKey]?["percent"] ?? plant.moistureLevel;
            if (plant.moistureLevel != newMoisture) {
              plant.moistureLevel = newMoisture;
            }

            // Auto Mode logic based on thresholds
            if (plant.isAutoMode && !_dataManager.isSystemAutoMode) {
              if (plant.moistureLevel < plant.minMoistureThreshold &&
                  !plant.isMotorOn) {
                togglePlantMotor(plant, isOn: true);
              } else if (plant.moistureLevel >= plant.maxMoistureThreshold &&
                  plant.isMotorOn) {
                togglePlantMotor(plant, isOn: false);
              }
            }
          }
        }

        // Sync system status briefly
        final statusMap = await _wifiService.getSystemStatus();
        if (statusMap != null && statusMap.containsKey('activeMotorsList')) {
          List<dynamic> activeList = statusMap['activeMotorsList'];
          for (var plant in _dataManager.plants) {
            plant.isMotorOn =
                activeList.contains(plant.id) ||
                activeList.contains(plant.id.toString());
          }
        }

        lastUpdated = DateTime.now();
        isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Moisture Sync Attempt Failed: $e");
      if (retry > 0 && !_isDisposed) {
        isSyncing = false;
        return fetchMoistureData(retry: retry - 1);
      }
    } finally {
      isSyncing = false;
      notifyListeners();
    }
    return false;
  }

  // Individual motor control using Esp32Service Local/Firebase Logic
  Future<bool> togglePlantMotor(Plant plant, {bool? isOn}) async {
    if (_isProcessingToggle[plant.id] == true || _isDisposed) return false;

    _isProcessingToggle[plant.id] = true;
    bool targetState = isOn ?? !plant.isMotorOn;
    notifyListeners();

    try {
      bool success = await _unifiedCommandService.toggleMotor(plant.id, targetState);
      if (success) {
        plant.isMotorOn = targetState;
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
    // Falls back to motor state from last sync if communication fails entirely
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

    try {
      bool success = await _unifiedCommandService.toggleAllMotors(value);
      if (success) {
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

  Future<void> enableSmartAutoMode() async {
    for (var plant in _dataManager.plants) {
      plant.isAutoMode = true;
    }
    notifyListeners();
  }

  Future<void> disableSmartAutoMode() async {
    for (var plant in _dataManager.plants) {
      plant.isAutoMode = false;
    }
    notifyListeners();
  }

  List<Plant> getPlants() => _dataManager.plants;
  int getActiveMotors() => _dataManager.activeMotors;
  int getTotalMotors() => _dataManager.totalMotors;
  int getAvgMoisture() => _dataManager.avgMoisture;
}
