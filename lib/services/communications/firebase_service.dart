import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  StreamSubscription? _deviceSubscription;

  // Stream for UI to listen to device updates (moisture, motor status, etc.)
  final StreamController<Map<String, dynamic>> _deviceDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get deviceDataStream => _deviceDataController.stream;

  /// Initialize the Firebase listener for the configured ESP32 device
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");

    if (deviceId == null || deviceId.isEmpty) {
      debugPrint("FirebaseService: No Device ID configured.");
      return;
    }

    _deviceSubscription?.cancel();
    _deviceSubscription = _db.ref("devices/$deviceId").onValue.listen((event) {
      if (event.snapshot.exists) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          _deviceDataController.add(data);
        } catch (e) {
          debugPrint("FirebaseService: Error parsing data: $e");
        }
      }
    });
  }

  /// Toggle a specific motor (0 for main motor, 1-8 for individual plants)
  Future<bool> toggleMotor(int motorId, bool isOn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString("esp_device_id");
      
      if (deviceId == null || deviceId.isEmpty) return false;

      await _db.ref("devices/$deviceId/motors/${motorId.toString()}").set(isOn);
      return true;
    } catch (e) {
      debugPrint("FirebaseService: Failed to toggle motor $motorId: $e");
      return false;
    }
  }

  /// Emergency stop or toggle all motors
  Future<bool> toggleAllMotors(bool isOn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString("esp_device_id");
      
      if (deviceId == null || deviceId.isEmpty) return false;

      if (!isOn) {
        // Trigger a global stop flag if the ESP32 code supports it
        await _db.ref("devices/$deviceId/stopAll").set(true);
      }

      // Update all individual motor states for consistency
      Map<String, dynamic> motorUpdates = {};
      for (int i = 0; i <= 8; i++) {
        motorUpdates[i.toString()] = isOn;
      }
      await _db.ref("devices/$deviceId/motors").update(motorUpdates);
      
      return true;
    } catch (e) {
      debugPrint("FirebaseService: Failed to toggle all motors: $e");
      return false;
    }
  }

  /// Update moisture thresholds for auto-irrigation
  Future<bool> updateThresholds(int motorId, int min, int max) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString("esp_device_id");
      
      if (deviceId == null || deviceId.isEmpty) return false;

      await _db.ref("devices/$deviceId/thresholds/${motorId.toString()}").set({
        "min": min,
        "max": max,
      });
      return true;
    } catch (e) {
      debugPrint("FirebaseService: Failed to update thresholds: $e");
      return false;
    }
  }

  /// Check if the device is currently online based on the "lastSeen" timestamp
  bool isDeviceOnline(Map<String, dynamic> data) {
    int lastSeen = data["lastSeen"] ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // Consider offline if no heartbeat for more than 60 seconds
    return (currentTime - lastSeen) < 60;
  }

  /// Clean up resources
  void dispose() {
    _deviceSubscription?.cancel();
    _deviceDataController.close();
  }
}
