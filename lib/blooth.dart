// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'ESP32 Motor Control',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const BluetoothMotorScreen(),
//     );
//   }
// }
//
// class BluetoothMotorScreen extends StatefulWidget {
//   const BluetoothMotorScreen({super.key});
//
//   @override
//   State<BluetoothMotorScreen> createState() => _BluetoothMotorScreenState();
// }
//
// class _BluetoothMotorScreenState extends State<BluetoothMotorScreen> {
//   BluetoothConnection? connection;
//   bool isConnected = false;
//   List<BluetoothDevice> devices = [];
//   String receivedData = "No data";
//   final TextEditingController commandController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _requestPermissions();
//     _getBondedDevices();
//   }
//
//   Future<void> _requestPermissions() async {
//     await [
//       Permission.bluetooth,
//       Permission.bluetoothConnect,
//       Permission.bluetoothScan,
//       Permission.location,
//     ].request();
//   }
//
//   Future<void> _getBondedDevices() async {
//     List<BluetoothDevice> bonded =
//     await FlutterBluetoothSerial.instance.getBondedDevices();
//     setState(() {
//       devices = bonded
//           .where((d) => d.name == "ESP32_Motor_Control")
//           .toList();
//     });
//   }
//
//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     try {
//       connection = await BluetoothConnection.toAddress(device.address);
//       setState(() => isConnected = true);
//
//       connection!.input!.listen((data) {
//         setState(() {
//           receivedData = utf8.decode(data);
//         });
//       }).onDone(() {
//         setState(() => isConnected = false);
//       });
//     } catch (e) {
//       debugPrint("Connection error: $e");
//     }
//   }
//
//   void _sendCommand(String command) {
//     if (connection != null && isConnected) {
//       connection!.output.add(utf8.encode("$command\r\n"));
//       connection!.output.allSent;
//     }
//   }
//
//   @override
//   void dispose() {
//     connection?.dispose();
//     commandController.dispose();
//     super.dispose();
//   }
//
//   Widget _motorControls() {
//     return Column(
//       children: [
//         const SizedBox(height: 10),
//         const Text("Motor Controls",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         Wrap(
//           spacing: 10,
//           children: List.generate(4, (index) {
//             int motor = index + 1;
//             return Column(
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _sendCommand("ON:$motor"),
//                   child: Text("Motor $motor ON"),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _sendCommand("OFF:$motor"),
//                   child: Text("Motor $motor OFF"),
//                 ),
//               ],
//             );
//           }),
//         ),
//         const SizedBox(height: 10),
//         ElevatedButton(
//           onPressed: () => _sendCommand("ALL:ON"),
//           child: const Text("All Motors ON"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("ALL:OFF"),
//           child: const Text("All Motors OFF"),
//         ),
//       ],
//     );
//   }
//
//   Widget _advancedControls() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Advanced Controls",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         ElevatedButton(
//           onPressed: () => _sendCommand("AUTO:ON:1:5:3"),
//           child: const Text("Auto Mode Motor 1"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("TIMER:1:ON:10"),
//           child: const Text("Timer Motor 1 (10s)"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("ALARM:SET:1:12:30"),
//           child: const Text("Set Alarm Motor 1"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("ALARM:LIST"),
//           child: const Text("List Alarms"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("STATUS"),
//           child: const Text("Get Status"),
//         ),
//         ElevatedButton(
//           onPressed: () => _sendCommand("HELP"),
//           child: const Text("Help"),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("ESP32 Motor Control"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // Device List
//             const Text("Available ESP32 Devices",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             Expanded(
//               child: ListView(
//                 children: devices.map((device) {
//                   return ListTile(
//                     title: Text(device.name ?? "Unknown"),
//                     subtitle: Text(device.address),
//                     trailing: ElevatedButton(
//                       onPressed: () => _connectToDevice(device),
//                       child: const Text("Connect"),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//
//             const SizedBox(height: 10),
//             Text(
//               isConnected ? "Connected" : "Disconnected",
//               style: TextStyle(
//                 color: isConnected ? Colors.green : Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//
//             const Divider(),
//
//             // Motor Controls
//             if (isConnected) _motorControls(),
//
//             const Divider(),
//
//             // Advanced Controls
//             if (isConnected) _advancedControls(),
//
//             const Divider(),
//
//             // Custom Command
//             TextField(
//               controller: commandController,
//               decoration: const InputDecoration(
//                 labelText: "Custom Command",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: () => _sendCommand(commandController.text),
//               child: const Text("Send Command"),
//             ),
//
//             const SizedBox(height: 10),
//             const Text("Response:",
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(10),
//               color: Colors.black12,
//               child: Text(receivedData),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }