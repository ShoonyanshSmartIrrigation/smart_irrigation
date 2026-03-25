// import 'dart:async';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//
// class BluetoothService {
//   static final BluetoothService _instance = BluetoothService._internal();
//   factory BluetoothService() => _instance;
//   BluetoothService._internal();
//
//   Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
//   Stream<bool> get isScanning => FlutterBluePlus.isScanning;
//
//   Future<void> startScan() async {
//     if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
//       throw Exception("Bluetooth is off");
//     }
//     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
//   }
//
//   Future<void> stopScan() async {
//     await FlutterBluePlus.stopScan();
//   }
//
//   Future<void> connectToDevice(BluetoothDevice device) async {
//     await device.connect();
//     await stopScan();
//   }
//
//   Future<void> disconnectDevice(BluetoothDevice? device) async {
//     if (device != null) {
//       await device.disconnect();
//     }
//   }
//
//   Future<void> sendCommand(BluetoothDevice? device, String command) async {
//     if (device == null) throw Exception("Not connected");
//
//     List<BluetoothService> services = await device.discoverServices();
//     for (var service in services) {
//       for (var characteristic in service.characteristics) {
//         if (characteristic.properties.write) {
//           await characteristic.write(command.codeUnits);
//           return;
//         }
//       }
//     }
//     throw Exception("No writeable characteristic found");
//   }
// }
