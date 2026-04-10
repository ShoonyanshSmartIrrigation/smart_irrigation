import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothConnectionService {
  static final BluetoothConnectionService _instance = BluetoothConnectionService._internal();
  factory BluetoothConnectionService() => _instance;
  BluetoothConnectionService._internal();

  BluetoothDevice? connectedDevice;
  List<BluetoothService> discoveredServices = [];

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  Future<bool> checkPermissions() async {
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint("Bluetooth turn on error: $e");
        return false;
      }
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.bluetoothScan]!.isDenied) {
      return false;
    }

    if (!await Permission.location.serviceStatus.isEnabled) {
      return false;
    }

    return true;
  }

  Future<void> startScan() async {
    bool hasPermissions = await checkPermissions();
    if (!hasPermissions) return;

    FlutterBluePlus.startScan(
      withKeywords: ["ESP32_IRRIGATION"],
      timeout: const Duration(seconds: 15),
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        license: License.free, // Use License.free for personal/non-profit use
        timeout: const Duration(seconds: 10),
      );

      connectedDevice = device;
      
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
          discoveredServices = [];
        }
      });

      discoveredServices = await device.discoverServices();
      return true;
    } catch (e) {
      debugPrint("Error connecting: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      discoveredServices = [];
    }
  }

  Future<bool> sendCommand(String jsonCommand) async {
    if (connectedDevice == null || discoveredServices.isEmpty) return false;

    for (var service in discoveredServices) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          try {
            await characteristic.write(utf8.encode(jsonCommand));
            debugPrint("Sent: $jsonCommand");
            return true;
          } catch (e) {
            debugPrint("Error writing characteristic: $e");
          }
        }
      }
    }
    return false;
  }

  // Example: toggling motor
  Future<bool> toggleMotor(int motorId, bool turnOn) async {
    final stateStr = turnOn ? "on" : "off";
    final command = '{"motor":$motorId,"state":"$stateStr"}';
    return await sendCommand(command);
  }
}
