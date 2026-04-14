import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleTestScreen extends StatefulWidget {
  const BleTestScreen({super.key});

  @override
  State<BleTestScreen> createState() => _BleTestScreenState();
}

class _BleTestScreenState extends State<BleTestScreen> {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _controlChar;
  BluetoothCharacteristic? _responseChar;
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  String _status = "Idle";
  String _lastResponse = "";
  final Map<int, String> _motorStates = {};

  final String _serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  final String _controlUuid = "12345678-1234-1234-1234-1234567890ac";
  final String _responseUuid = "12345678-1234-1234-1234-1234567890ad";

  @override
  void initState() {
    super.initState();
    _setupBluetooth();
  }

  void _setupBluetooth() {
    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });

    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results
              .where((r) {
                final name = r.device.platformName.isNotEmpty 
                    ? r.device.platformName 
                    : r.advertisementData.advName;
                return name.toUpperCase().contains("ESP");
              })
              .toList();
        });
      }
    });
  }

  Future<void> _startScan() async {
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      
      setState(() {
        _status = "Scanning for ESP devices...";
        _scanResults.clear();
      });

      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      } catch (e) {
        setState(() => _status = "Scan Error: $e");
      }
    } else {
      setState(() => _status = "Required permissions denied");
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() => _status = "Connecting to ${device.platformName}...");
    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        license: License.free,
      );
      
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == _serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == _controlUuid.toLowerCase()) {
              _controlChar = char;
            } else if (char.uuid.toString().toLowerCase() == _responseUuid.toLowerCase()) {
              _responseChar = char;
              await _responseChar!.setNotifyValue(true);
              _responseChar!.onValueReceived.listen((value) {
                String resp = utf8.decode(value);
                setState(() {
                  _lastResponse = resp;
                  _updateMotorStates(resp);
                });
              });
            }
          }
        }
      }

      if (_controlChar == null) {
        setState(() => _status = "Connected, but Service/Char not found");
      } else {
        setState(() => _status = "Connected & Ready");
        _sendCommand("STATUS");
      }
    } catch (e) {
      setState(() => _status = "Connection failed: $e");
    }
  }

  void _updateMotorStates(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      if (data['motors'] != null) {
        for (var motor in data['motors']) {
          _motorStates[motor['id']] = motor['state'];
        }
      } else if (data['zone'] != null) {
        _motorStates[data['zone']] = data['state'];
      } else if (data['action'] == "ALL_ON") {
        for (int i = 0; i < 9; i++) {
          _motorStates[i] = "ON";
        }
      } else if (data['action'] == "ALL_OFF") {
        for (int i = 0; i < 9; i++) {
          _motorStates[i] = "OFF";
        }
      }
    } catch (e) {}
  }

  Future<void> _sendCommand(String command) async {
    if (_controlChar != null) {
      try {
        await _controlChar!.write(utf8.encode(command));
        setState(() => _status = "Sent: $command");
      } catch (e) {
        setState(() => _status = "Send failed: $e");
      }
    } else {
      setState(() => _status = "Not connected to control characteristic");
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      setState(() {
        _connectedDevice = null;
        _controlChar = null;
        _responseChar = null;
        _status = "Disconnected";
        _motorStates.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : Colors.white,
      appBar: AppBar(
        title: const Text("ESP32 BLE Tester"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_connectedDevice != null)
            IconButton(onPressed: _disconnect, icon: const Icon(Icons.link_off))
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Status: $_status", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_connectedDevice != null)
                   Text("Device: ${_connectedDevice!.platformName} (${_connectedDevice!.remoteId})", 
                        style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _connectedDevice == null ? _buildScanner() : _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Searching for ESP Devices...", style: TextStyle(fontStyle: FontStyle.italic, color: isDark ? Colors.white70 : Colors.black87)),
        ),
        ElevatedButton.icon(
          onPressed: _isScanning ? null : _startScan,
          icon: const Icon(Icons.search),
          label: Text(_isScanning ? "Scanning..." : "Search for ESP Device"),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final r = _scanResults[index];
              final name = r.device.platformName.isEmpty ? r.advertisementData.advName : r.device.platformName;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.bluetooth, color: Colors.blue),
                  title: Text(name.isEmpty ? "Unknown Device" : name, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text(r.device.remoteId.toString(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                  trailing: ElevatedButton(
                    onPressed: () => _connect(r.device),
                    child: const Text("Connect"),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Master Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _sendCommand("ON:ALL"),
                  child: const Text("ALL ON"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => _sendCommand("OFF:ALL"),
                  child: const Text("ALL OFF"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _sendCommand("STATUS"),
            icon: const Icon(Icons.refresh),
            label: const Text("REFRESH MOTOR STATUS"),
          ),
          const Divider(height: 40, thickness: 2),
          const Text("Individual Motor Control (0-8)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              String state = _motorStates[index] ?? "OFF";
              bool isOn = state == "ON";
              return Card(
                elevation: isOn ? 4 : 1,
                color: isOn ? Colors.green.withOpacity(0.1) : (isDark ? Colors.white10 : Colors.grey.shade100),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isOn ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade400), width: 2),
                ),
                child: InkWell(
                  onTap: () => _sendCommand("${isOn ? "OFF" : "ON"}:$index"),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Motor $index", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Icon(isOn ? Icons.power : Icons.power_off, color: isOn ? Colors.green : Colors.grey),
                      const SizedBox(height: 4),
                      Text(state, style: TextStyle(color: isOn ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(height: 40, thickness: 2),
          const Text("Raw Response from ESP:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _lastResponse.isEmpty ? "No data received yet" : _lastResponse, 
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent)
            ),
          ),
        ],
      ),
    );
  }
}
