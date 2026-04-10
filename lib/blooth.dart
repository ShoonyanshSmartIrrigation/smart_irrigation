import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ESP32 Pairing',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BluetoothPairingScreen(),
    );
  }
}

class BluetoothPairingScreen extends StatefulWidget {
  const BluetoothPairingScreen({super.key});

  @override
  State<BluetoothPairingScreen> createState() =>
      _BluetoothPairingScreenState();
}

class _BluetoothPairingScreenState extends State<BluetoothPairingScreen> {
  List<ScanResult> devices = [];
  BluetoothDevice? connectedDevice;
  List<BluetoothService> discoveredServices = [];
  bool isScanning = false;
  bool isConnecting = false;

  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() async {
    // 1. Automatically ask the user to turn ON Bluetooth via an OS popup!
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bluetooth must be turned on to scan!")),
          );
        }
        return;
      }
    }

    // Request necessary Bluetooth and Location permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.bluetoothScan]!.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location & Bluetooth permissions are required"), duration: Duration(seconds: 4)),
        );
      }
      return;
    }

    // Verify the user actually turned on the GPS/location slider in their phone
    if (!await Permission.location.serviceStatus.isEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please turn ON Location (GPS) in your phone's notification panel!"), duration: Duration(seconds: 5)),
        );
      }
      return;
    }

    setState(() => isScanning = true);

    devices.clear();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Filter to show only ESP32 related devices (case insensitive)
          devices = results.where((result) {
            String name = result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.device.advName;
            return name.toLowerCase().contains("esp");
          }).toList();
        });
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    if (mounted) {
      setState(() => isScanning = false);
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() => isConnecting = true);

    try {
      // ✅ FIXED: Use the correct Enum for the license parameter
      await device.connect(
        license: License.free, // Use License.free for personal/non-profit use
        timeout: const Duration(seconds: 10),
      );

      setState(() {
        connectedDevice = device;
      });

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          if (mounted) {
            setState(() {
              connectedDevice = null;
              discoveredServices = [];
            });
          }
        }
      });

      discoveredServices = await device.discoverServices();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected to ${device.platformName}")),
      );

      bool dataSent = false;

      for (var service in discoveredServices) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            String data =
                "SSID:${ssidController.text},PASSWORD:${passwordController.text}";

            await characteristic.write(data.codeUnits);

            dataSent = true;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("WiFi credentials sent")),
            );

            // We do not break here so we can also discover the control characteristic
          }
        }
      }

      if (!dataSent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No writable characteristic found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isConnecting = false);
  }

  Future<void> sendBleCommand(String command) async {
    for (var service in discoveredServices) {
      for (var characteristic in service.characteristics) {
        // Look for writable characteristic
        if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
          try {
            await characteristic.write(command.codeUnits);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Sent: $command")),
            );
            return;
          } catch (e) {
            print("Failed to write to $characteristic - $e");
          }
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not find writable characteristic for command")),
    );
  }

  @override
  void dispose() {
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pair ESP32 Device"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: startScan,
          )
        ],
      ),
      body: Column(
        children: [
          // WiFi Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(
                    labelText: "WiFi SSID",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "WiFi Password",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Bluetooth Control Panel (Shows when connected)
          if (connectedDevice != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Connected to ${connectedDevice!.platformName}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () => connectedDevice!.disconnect(),
                        child: const Text("Disconnect"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("AUTO MODE CONTROL"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => sendBleCommand("AUTO_ON"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("AUTO ON"),
                      ),
                      ElevatedButton(
                        onPressed: () => sendBleCommand("AUTO_OFF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("AUTO OFF"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const Divider(),

          // Device List (Hidden when connected)
          if (connectedDevice == null)
            Expanded(
              child: isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final scanResult = devices[index];
                        final device = scanResult.device;
                        
                        String deviceName = device.platformName.isNotEmpty 
                            ? device.platformName 
                            : (device.advName.isNotEmpty ? device.advName : "Unknown Device");

                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(deviceName),
                          subtitle: Text('${device.remoteId} • Signal: ${scanResult.rssi} dBm'),
                          trailing: isConnecting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton(
                                  onPressed: () => connectToDevice(device),
                                  child: const Text("Connect"),
                                ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}