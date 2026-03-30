import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';

class Esp32Service {
  static final Esp32Service _instance = Esp32Service._internal();
  factory Esp32Service() => _instance;
  Esp32Service._internal();

  // Connection Checking
  Future<bool> checkConnection() async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    try {
      final response = await http.get(Uri.parse("http://$ip:$port/api/system/status"))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Motor Controls
  Future<bool> toggleMainMotor(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url = "http://$ip:$port${isOn ? "/api/mainmotor/on" : "/api/mainmotor/off"}";
    try {
      final response = await http.post(Uri.parse(url)).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;

    if (ip == null || ip.isEmpty) return false;

    String url = "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";
    try {
      final response = await http.post(Uri.parse(url)).timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Configuration & Discovery Logic (Moved from Esp32ConfigService)
  Future<bool> checkInitialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString("esp_ip");
    int savedPort = prefs.getInt("esp_port") ?? 80;

    if (savedIp != null && savedIp.isNotEmpty) {
      return await verifyConnection(savedIp, savedPort);
    }
    return false;
  }

  Future<String?> startAutoDiscovery() async {
    // 1. Try mDNS first
    String? ip = await discoverViaMDNS();
    if (ip != null) return ip;

    // 2. Fallback to Subnet Scan
    return await discoverViaIPScan();
  }

  Future<void> saveConfig(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("esp_ip", ip);
    await prefs.setInt("esp_port", port);
  }

  // Helper Discovery Methods
  Future<String?> discoverViaMDNS() async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();
      await for (final PtrResourceRecord ptr in client.lookup<PtrResourceRecord>(
          ResourceRecordQuery.serverPointer('_http._tcp.local'))) {
        await for (final SrvResourceRecord srv in client.lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(ptr.domainName))) {
          await for (final IPAddressResourceRecord ip in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target))) {
            String ipStr = ip.address.address;
            if (await verifyConnection(ipStr, srv.port)) {
              client.stop();
              return ipStr;
            }
          }
        }
      }
    } catch (_) {} finally {
      client.stop();
    }
    return null;
  }

  Future<String?> discoverViaIPScan() async {
    try {
      final info = NetworkInfo();
      String? myIp = await info.getWifiIP();
      if (myIp == null || myIp.isEmpty) return null;

      String subnet = myIp.substring(0, myIp.lastIndexOf('.'));
      for (int i = 1; i <= 255; i++) {
        String testIp = "$subnet.$i";
        if (await verifyConnection(testIp, 80)) {
          return testIp;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> verifyConnection(String ip, int port) async {
    try {
      final res = await http.get(Uri.parse("http://$ip:$port/api/system/status"))
          .timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        await saveConfig(ip, port);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
