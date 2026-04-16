import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../communications/bluetooth_service.dart';

class BleCommandService {
  final BleService bleService;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  BleCommandService(this.bleService);

  fbp.BluetoothCharacteristic? get _characteristic =>
      bleService.characteristic;

  /// Send a command to the ESP32 and sync with Firebase
  Future<void> sendCommand(String command) async {
    // 1. Send via BLE if available
    bool bleSuccess = false;
    if (_characteristic != null) {
      try {
        await _characteristic!.write(
          utf8.encode(command),
          withoutResponse:
          _characteristic!.properties.writeWithoutResponse,
        );
        bleSuccess = true;
      } catch (e) {
        print("BLE Write Error: $e");
      }
    }

    // 2. Always sync with Firebase for motor commands
    await _syncCommandToFirebase(command);
    
    if (!bleSuccess && _characteristic == null) {
      // If we're strictly expecting BLE to work and it's not connected,
      // we might want to throw, but since we're "Always Syncing",
      // the Firebase update above is the primary goal.
    }
  }

  Future<void> _syncCommandToFirebase(String command) async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString("esp_device_id");
    if (deviceId == null || deviceId.isEmpty) return;

    final String cmd = command.toUpperCase().trim();

    try {
      if (cmd.startsWith("ON:")) {
        String zoneStr = cmd.substring(3);
        if (zoneStr == "ALL") {
          await _updateAllMotorsInFirebase(deviceId, true);
        } else {
          int? zone = int.tryParse(zoneStr);
          if (zone != null) {
            await _db.ref("devices/$deviceId/motors/$zone").set(true);
          }
        }
      } else if (cmd.startsWith("OFF:")) {
        String zoneStr = cmd.substring(4);
        if (zoneStr == "ALL") {
          await _updateAllMotorsInFirebase(deviceId, false);
        } else {
          int? zone = int.tryParse(zoneStr);
          if (zone != null) {
            await _db.ref("devices/$deviceId/motors/$zone").set(false);
          }
        }
      }
    } catch (e) {
      print("Firebase sync error via BLE command: $e");
    }
  }

  Future<void> _updateAllMotorsInFirebase(String deviceId, bool isOn) async {
    if (!isOn) {
      await _db.ref("devices/$deviceId/stopAll").set(true);
    }
    
    Map<String, dynamic> updates = {};
    for (int i = 0; i < 9; i++) {
      updates["devices/$deviceId/motors/$i"] = isOn;
    }
    await _db.ref().update(updates);
  }

  /// Read data from the ESP32
  Future<String?> readData() async {
    if (_characteristic == null ||
        !_characteristic!.properties.read) {
      return null;
    }

    final value = await _characteristic!.read();
    return utf8.decode(value);
  }

  /// Enable notifications for real-time updates
  Stream<String> enableNotifications() async* {
    if (_characteristic == null ||
        !_characteristic!.properties.notify) {
      throw Exception("Notifications not supported");
    }

    await _characteristic!.setNotifyValue(true);

    yield* _characteristic!.onValueReceived
        .map((value) => utf8.decode(value));
  }
}