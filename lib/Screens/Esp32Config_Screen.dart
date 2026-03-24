import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

class Esp32ConfigScreen extends StatefulWidget {
  @override
  State<Esp32ConfigScreen> createState() => _Esp32ConfigScreenState();
}

class _Esp32ConfigScreenState extends State<Esp32ConfigScreen> {
  String status = "Checking...";
  String result = "Verifying current status...";
  bool isLoading = false;
  String? discoveredIp;

  @override
  void initState() {
    super.initState();
    // Check for existing connection before starting discovery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialStatus();
    });
  }

  Future<void> _checkInitialStatus() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString("esp_ip");
    int savedPort = prefs.getInt("esp_port") ?? 80;

    if (savedIp != null && savedIp.isNotEmpty) {
      bool isConnected = await _verifyAndSave(savedIp, savedPort, "Saved Settings");
      if (isConnected) {
        setState(() {
          isLoading = false;
        });
        return; // Already connected, no need to search
      }
    }

    // If no saved IP or saved IP is unreachable, start auto discovery
    startAutoDiscovery();
  }

  Future<void> saveData(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("esp_ip", ip);
    await prefs.setInt("esp_port", port);
  }

  // ===============================
  // AUTO DISCOVERY (mDNS + Scan)
  // ===============================
  Future<void> startAutoDiscovery() async {
    setState(() {
      isLoading = true;
      status = "Searching...";
      result = "Looking for ESP32 on your network...";
      discoveredIp = null;
    });

    // 1. Try mDNS first
    bool found = await _discoverViaMDNS();
    
    // 2. Fallback to Subnet Scan if mDNS doesn't find it
    if (!found && mounted) {
      await _discoverViaIPScan();
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        if (status != "Connected") {
          status = "Not Found";
          result = "Could not find ESP32. Please ensure it's powered on and on the same Wi-Fi.";
        }
      });
    }
  }

  Future<bool> _discoverViaMDNS() async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();
      
      // Look for HTTP services
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_http._tcp.local'))) {
        
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            
            String ipStr = ip.address.address;
            int port = srv.port;
            
            if (await _verifyAndSave(ipStr, port, "mDNS")) {
              client.stop();
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("mDNS error: $e");
    } finally {
      client.stop();
    }
    return false;
  }

  Future<void> _discoverViaIPScan() async {
    if (status == "Connected") return;

    setState(() {
      result = "mDNS failed. Scanning network subnet...";
    });

    try {
      final info = NetworkInfo();
      String? myIp = await info.getWifiIP();
      
      if (myIp == null || myIp.isEmpty) {
        result = "❌ Wi-Fi IP not found. Are you connected to Wi-Fi?";
        return;
      }

      String subnet = myIp.substring(0, myIp.lastIndexOf('.'));
      List<Future<void>> scans = [];

      // Scan common IP range
      for (int i = 1; i <= 255; i++) {
        scans.add(_verifyAndSave("$subnet.$i", 80, "Auto Scan"));
      }

      await Future.wait(scans);
    } catch (e) {
      debugPrint("Scan error: $e");
    }
  }

  Future<bool> _verifyAndSave(String ip, int port, String method) async {
    if (status == "Connected") return true;

    try {
      final res = await http.get(Uri.parse("http://$ip:$port/api/system/status"))
          .timeout(const Duration(milliseconds: 1500));
      
      if (res.statusCode == 200 && status != "Connected") {
        await saveData(ip, port);
        if (mounted) {
          setState(() {
            status = "Connected";
            result = "✅ Device is connected!";
            discoveredIp = ip;
          });
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text("ESP32 Auto Connect", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 30),
              Text(
                status,
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  color: status == "Connected" ? Colors.green : Colors.black87
                ),
              ),
              const SizedBox(height: 15),
              Text(
                result,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              if (discoveredIp != null) ...[
                const SizedBox(height: 10),
                Text(
                  "IP: $discoveredIp",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                ),
              ],
              const SizedBox(height: 40),
              if (isLoading)
                const CircularProgressIndicator(color: Color(0xFF2E7D32))
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: startAutoDiscovery,
                    icon: Icon(status == "Connected" ? Icons.refresh : Icons.search),
                    label: Text(
                      status == "Connected" ? "RE-SCAN" : "TRY AGAIN",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (status == "Connected")
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      "DONE",
                      style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (status == "Connected") {
      return const Icon(Icons.check_circle, size: 100, color: Colors.green);
    } else if (status == "Not Found") {
      return const Icon(Icons.error_outline, size: 100, color: Colors.redAccent);
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
          ),
          const Icon(Icons.wifi_find, size: 60, color: Color(0xFF2E7D32)),
        ],
      );
    }
  }
}
