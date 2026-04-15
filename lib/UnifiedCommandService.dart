// lib/services/communications/unified_command_service.dart

import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartirrigation/services/communications/bluetooth_service.dart';
import 'package:smartirrigation/services/communications/wifi_service.dart';

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

    // 1. Try BLE (Priority 1: Low Latency, No Internet needed)
    if (_bleService.isConnected && _bleService.characteristic != null) {
      try {
        String command = "${isOn ? "ON" : "OFF"}:$motorId";
        await _bleService.characteristic!.write(utf8.encode(command));
        commandSent = true;
      } catch (_) {}
    }

    // 2. Try Local WiFi (Priority 2: Low Latency, Local Network)
    if (!commandSent) {
      // WifiService already tries local HTTP then reports success
      // We call the internal toggle to avoid double-syncing Firebase here if we refactor WifiService
      // but for now, we'll use the existing toggle and let it handle its logic.
      commandSent = await _wifiService.toggleMotor(motorId, isOn);
    }

    // 3. Always Sync/Push to Firebase (Priority 3: Global Sync / Cloud Fallback)
    // Even if BLE or WiFi succeeded, we update Firebase so other users see the change.
    await _updateFirebaseMotorState(motorId, isOn);

    return commandSent || true; // Return true because Firebase update is a success path
  }

  /// Master switch to toggle all motors
  Future<bool> toggleAllMotors(bool isOn) async {
    bool commandSent = false;

    // 1. Try BLE
    if (_bleService.isConnected && _bleService.characteristic != null) {
      try {
        String command = "${isOn ? "ON" : "OFF"}:ALL";
        await _bleService.characteristic!.write(utf8.encode(command));
        commandSent = true;
      } catch (_) {}
    }

    // 2. Try Local WiFi
    if (!commandSent) {
      commandSent = await _wifiService.toggleAllMotors(isOn);
    }

    // 3. Always Sync Firebase
    await _updateFirebaseAllMotors(isOn);

    return commandSent || true;
  }

  Future<void> _updateFirebaseMotorState(int motorId, bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");
    if (deviceId == null) return;

    await _db.ref("devices/$deviceId/motors/${motorId.toString()}").set(isOn);
  }

  Future<void> _updateFirebaseAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");
    if (deviceId == null) return;

    if (!isOn) {
      await _db.ref("devices/$deviceId/stopAll").set(true);
    }

    Map<String, dynamic> updates = {};
    for (int i = 0; i <= 8; i++) {
      updates["devices/$deviceId/motors/$i"] = isOn;
    }
    await _db.ref().update(updates);
  }
}