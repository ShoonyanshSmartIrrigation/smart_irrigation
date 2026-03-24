import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MaintenanceScreen extends StatefulWidget {
  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          scanResults = results;
        });
      }
    });

    // Listen to scanning state
    FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          isScanning = state;
        });
      }
    });
  }

  // 🔍 Start Scanning
  void startScan() async {
    // Check if bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      showToast("Please turn on Bluetooth");
      return;
    }

    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 15));
    } catch (e) {
      showToast("Error starting scan: $e");
    }
  }

  // 🔗 Connect to Device
  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });
      showToast("Connected to ${device.platformName}");
      
      // Stop scanning once connected
      await FlutterBluePlus.stopScan();
    } catch (e) {
      showToast("Connection failed: $e");
    }
  }

  // ❌ Disconnect
  void disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
      });
      showToast("Disconnected");
    }
  }

  // ⚙️ Send Command (Simplified for BLE)
  void sendCommand(String command) async {
    if (connectedDevice == null) {
      showToast("Not connected");
      return;
    }

    try {
      // BLE requires discovering services and writing to a specific characteristic
      List<BluetoothService> services = await connectedDevice!.discoverServices();
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(command.codeUnits);
            showToast("Sent: $command");
            return;
          }
        }
      }
      showToast("No writeable characteristic found");
    } catch (e) {
      showToast("Error sending command: $e");
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text("Maintenance (BLE)", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          _buildControlPanel(),
          Divider(height: 1),
          _buildDeviceListHeader(),
          Expanded(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                connectedDevice != null ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: connectedDevice != null ? Colors.blue : Colors.grey,
                size: 30,
              ),
              SizedBox(width: 10),
              Text(
                connectedDevice != null 
                    ? "Connected to ${connectedDevice!.platformName}" 
                    : "Not Connected",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (isScanning) Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(color: Color(0xFF2E7D32), backgroundColor: Colors.green[100]),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isScanning ? null : startScan,
                  icon: Icon(Icons.search),
                  label: Text("START SCAN"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Color(0xFF2E7D32)),
                ),
              ),
              SizedBox(width: 10),
              if (connectedDevice != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: disconnect,
                    icon: Icon(Icons.close),
                    label: Text("DISCONNECT"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
                  ),
                ),
            ],
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _motorButton("MOTOR ON", Icons.play_arrow, Colors.green, () => sendCommand("MOTOR_ON")),
                _motorButton("MOTOR OFF", Icons.stop, Colors.red, () => sendCommand("MOTOR_OFF")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _motorButton(String label, IconData icon, Color color, VoidCallback? onPressed) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: connectedDevice != null ? onPressed : null,
          icon: Icon(icon),
          style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.1), foregroundColor: color, padding: EdgeInsets.all(20)),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
      ],
    );
  }

  Widget _buildDeviceListHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      alignment: Alignment.centerLeft,
      child: Text("AVAILABLE DEVICES (${scanResults.length})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1)),
    );
  }

  Widget _buildDeviceList() {
    if (scanResults.isEmpty) {
      return Center(child: Text("No devices found. Tap Scan to start."));
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 15),
      itemCount: scanResults.length,
      separatorBuilder: (_, __) => SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = scanResults[index];
        final device = result.device;
        final name = device.platformName.isEmpty ? "Unknown Device" : device.platformName;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.bluetooth, color: Color(0xFF2E7D32))),
            title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(device.remoteId.str),
            trailing: Icon(Icons.chevron_right),
            onTap: () => connectToDevice(device),
          ),
        );
      },
    );
  }
}
