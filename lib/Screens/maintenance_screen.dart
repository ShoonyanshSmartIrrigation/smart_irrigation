// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import '../services/bluetooth_service.dart' as custom_bt;
//
// class MaintenanceScreen extends StatefulWidget {
//   @override
//   _MaintenanceScreenState createState() => _MaintenanceScreenState();
// }
//
// class _MaintenanceScreenState extends State<MaintenanceScreen> {
//   final custom_bt.BluetoothService _bluetoothService = custom_bt.BluetoothService();
//   List<ScanResult> scanResults = [];
//   BluetoothDevice? connectedDevice;
//   bool isScanning = false;
//   StreamSubscription? _scanSubscription;
//   StreamSubscription? _isScanningSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _scanSubscription = _bluetoothService.scanResults.listen((results) {
//       if (mounted) {
//         setState(() {
//           scanResults = results;
//         });
//       }
//     });
//
//     _isScanningSubscription = _bluetoothService.isScanning.listen((state) {
//       if (mounted) {
//         setState(() {
//           isScanning = state;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     _isScanningSubscription?.cancel();
//     super.dispose();
//   }
//
//   void startScan() async {
//     try {
//       await _bluetoothService.startScan();
//     } catch (e) {
//       showToast(e.toString());
//     }
//   }
//
//   void connectToDevice(BluetoothDevice device) async {
//     try {
//       await _bluetoothService.connectToDevice(device);
//       setState(() {
//         connectedDevice = device;
//       });
//       showToast("Connected to ${device.platformName}");
//     } catch (e) {
//       showToast("Connection failed: $e");
//     }
//   }
//
//   void disconnect() async {
//     try {
//       await _bluetoothService.disconnectDevice(connectedDevice);
//       setState(() {
//         connectedDevice = null;
//       });
//       showToast("Disconnected");
//     } catch (e) {
//       showToast("Error disconnecting: $e");
//     }
//   }
//
//   void sendCommand(String command) async {
//     try {
//       await _bluetoothService.sendCommand(connectedDevice, command);
//       showToast("Sent: $command");
//     } catch (e) {
//       showToast(e.toString());
//     }
//   }
//
//   void showToast(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F7F5),
//       appBar: AppBar(
//         title: const Text("Maintenance (BLE)", style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: const Color(0xFF2E7D32),
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           _buildStatusHeader(),
//           _buildControlPanel(),
//           const Divider(height: 1),
//           _buildDeviceListHeader(),
//           Expanded(child: _buildDeviceList()),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       color: Colors.white,
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 connectedDevice != null ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
//                 color: connectedDevice != null ? Colors.blue : Colors.grey,
//                 size: 30,
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 connectedDevice != null
//                     ? "Connected to ${connectedDevice!.platformName}"
//                     : "Not Connected",
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//               ),
//             ],
//           ),
//           if (isScanning) Padding(
//             padding: const EdgeInsets.only(top: 10),
//             child: LinearProgressIndicator(color: const Color(0xFF2E7D32), backgroundColor: Colors.green[100]),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildControlPanel() {
//     return Padding(
//       padding: const EdgeInsets.all(15),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: ElevatedButton.icon(
//                   onPressed: isScanning ? null : startScan,
//                   icon: const Icon(Icons.search),
//                   label: const Text("START SCAN"),
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF2E7D32)),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               if (connectedDevice != null)
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: disconnect,
//                     icon: const Icon(Icons.close),
//                     label: const Text("DISCONNECT"),
//                     style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 15),
//           Container(
//             padding: const EdgeInsets.all(15),
//             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _motorButton("MOTOR ON", Icons.play_arrow, Colors.green, () => sendCommand("MOTOR_ON")),
//                 _motorButton("MOTOR OFF", Icons.stop, Colors.red, () => sendCommand("MOTOR_OFF")),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _motorButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
//     return Column(
//       children: [
//         IconButton.filled(
//           onPressed: connectedDevice != null ? onPressed : null,
//           icon: Icon(icon),
//           style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, padding: const EdgeInsets.all(20)),
//         ),
//         const SizedBox(height: 8),
//         Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
//       ],
//     );
//   }
//
//   Widget _buildDeviceListHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       alignment: Alignment.centerLeft,
//       child: Text("AVAILABLE DEVICES (${scanResults.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
//     );
//   }
//
//   Widget _buildDeviceList() {
//     if (scanResults.isEmpty) {
//       return const Center(child: Text("No devices found. Tap Scan to start."));
//     }
//
//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(horizontal: 15),
//       itemCount: scanResults.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 10),
//       itemBuilder: (context, index) {
//         final result = scanResults[index];
//         final device = result.device;
//         final name = device.platformName.isEmpty ? "Unknown Device" : device.platformName;
//
//         return Card(
//           elevation: 0,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           child: ListTile(
//             leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.bluetooth, color: Color(0xFF2E7D32))),
//             title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//             subtitle: Text(device.remoteId.str),
//             trailing: const Icon(Icons.chevron_right),
//             onTap: () => connectToDevice(device),
//           ),
//         );
//       },
//     );
//   }
// }
