import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bluetooth_service.dart';
import 'wifi_service.dart';

class UnifiedCommandService {
  static final UnifiedCommandService _instance = UnifiedCommandService._internal();
  factory UnifiedCommandService() => _instance;
  UnifiedCommandService._internal();

  final BleService _bleService = BleService();
  final WifiService _wifiService = WifiService();
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Main method to toggle a motor using the best available path
  Future<bool> toggleMotor(int motorId, bool isOn) async {
    bool commandSent = false;

    // 1. Try BLE (Priority 1: Low Latency)
    if (_bleService.isConnected && _bleService.characteristic != null) {
      try {
        String command = "${isOn ? "ON" : "OFF"}:$motorId";
        await _bleService.characteristic!.write(
          utf8.encode(command),
          withoutResponse: _bleService.characteristic!.properties.writeWithoutResponse,
        );
        commandSent = true;
      } catch (_) {}
    }

    // 2. Try Local WiFi (Priority 2: Local Network)
    if (!commandSent) {
      commandSent = await _wifiService.toggleMotor(motorId, isOn);
    } else {
      // If BLE succeeded, we still MUST sync to Firebase manually
      await _updateFirebaseMotorState(motorId, isOn);
    }

    return commandSent;
  }

  /// Master switch to toggle all motors
  Future<bool> toggleAllMotors(bool isOn) async {
    bool commandSent = false;

    // 1. Try BLE
    if (_bleService.isConnected && _bleService.characteristic != null) {
      try {
        String command = "${isOn ? "ON" : "OFF"}:ALL";
        await _bleService.characteristic!.write(
          utf8.encode(command),
          withoutResponse: _bleService.characteristic!.properties.writeWithoutResponse,
        );
        commandSent = true;
      } catch (_) {}
    }

    // 2. Try Local WiFi
    if (!commandSent) {
      commandSent = await _wifiService.toggleAllMotors(isOn);
    } else {
      // If BLE succeeded, sync to Firebase
      await _updateFirebaseAllMotors(isOn);
    }

    return commandSent;
  }

  Future<void> _updateFirebaseMotorState(int motorId, bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");
    if (deviceId == null || deviceId.isEmpty) return;

    try {
      await _db.ref("devices/$deviceId/motors/${motorId.toString()}").set(isOn);
    } catch (e) {
      print("Firebase sync error: $e");
    }
  }

  Future<void> _updateFirebaseAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");
    if (deviceId == null || deviceId.isEmpty) return;

    try {
      if (!isOn) {
        await _db.ref("devices/$deviceId/stopAll").set(true);
      }

      Map<String, dynamic> updates = {};
      for (int i = 0; i <= 8; i++) {
        updates["devices/$deviceId/motors/$i"] = isOn;
      }
      await _db.ref().update(updates);
    } catch (e) {
      print("Firebase sync error: $e");
    }
  }
}
