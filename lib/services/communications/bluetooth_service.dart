import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String serviceUuid =
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _characteristic;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;

  // Stream to notify UI about connection status
  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Getter for the connected device
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Getter for the discovered characteristic
  fbp.BluetoothCharacteristic? get characteristic => _characteristic;

  /// Check if a device is currently connected
  bool get isConnected => _connectedDevice != null;

  /// Request necessary BLE permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Start scanning for BLE devices
  Future<void> startScan() async {
    if (await requestPermissions()) {
      await fbp.FlutterBluePlus.stopScan();
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await fbp.FlutterBluePlus.stopScan();
  }

  /// Stream of scan results
  Stream<List<fbp.ScanResult>> get scanResults =>
      fbp.FlutterBluePlus.scanResults;

  /// Connect to a BLE device and discover the required characteristic
  Future<bool> connect(fbp.BluetoothDevice device) async {
    try {
      await stopScan();

      // Connect to the device
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: fbp.License.free,
      );

      _connectedDevice = device;

      // Listen to connection state changes
      _connectionSubscription?.cancel();
      _connectionSubscription =
          device.connectionState.listen((state) {
            bool isConnected =
                state == fbp.BluetoothConnectionState.connected;
            _connectionController.add(isConnected);

            if (!isConnected) {
              _connectedDevice = null;
              _characteristic = null;
            }
          });

      // Discover services and characteristics
      await _discoverCharacteristic();

      return true;
    } catch (e) {
      print("BLE Connection Error: $e");
      _connectionController.add(false);
      return false;
    }
  }

  /// Discover and cache the required characteristic
  Future<void> _discoverCharacteristic() async {
    if (_connectedDevice == null) return;

    List<fbp.BluetoothService> services =
    await _connectedDevice!.discoverServices();

    for (var service in services) {
      if (service.uuid.toString().toLowerCase() ==
          serviceUuid.toLowerCase()) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              characteristicUuid.toLowerCase()) {
            _characteristic = characteristic;
            return;
          }
        }
      }
    }

    throw Exception("Required characteristic not found");
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
    } catch (e) {
      print("Disconnect error: $e");
    } finally {
      await _connectionSubscription?.cancel();
      _connectionController.add(false);
      _connectedDevice = null;
      _characteristic = null;
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionController.close();
  }
}