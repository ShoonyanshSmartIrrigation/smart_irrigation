import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:firebase_database/firebase_database.dart';

//-------------------------------------------------------- WifiService Class ----------------------------------------------------------
class WifiService {
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;
  WifiService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Connection Checking
  Future<Map<String, dynamic>?> getSystemStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    String? deviceId = prefs.getString("esp_device_id");

    if (ip != null && ip.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse("http://$ip:$port/api/system/status"))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      } catch (_) {}
    }

    // Fallback: Check Firebase for "lastSeen" or status if local fails or IP is missing
    if (deviceId != null && deviceId.isNotEmpty) {
      final snapshot = await _db.ref("devices/$deviceId").get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        int lastSeenRaw = data["lastSeen"] ?? 0;
        // Firebase ServerValue.timestamp is in milliseconds. 
        // If it's > 10,000,000,000 it's likely milliseconds.
        int lastSeenMs = lastSeenRaw > 10000000000 ? lastSeenRaw : lastSeenRaw * 1000;
        
        int currentTimeMs = DateTime.now().millisecondsSinceEpoch;
        bool isOffline = (currentTimeMs - lastSeenMs).abs() > 60000; // 60 seconds

        // Transform Firebase data to match ESP32 endpoint format briefly
        return {
          "status": isOffline ? "offline" : "ok",
          "remote": true,
          "deviceId": deviceId,
          "lastSeen": lastSeenMs ~/ 1000, // Standardize to seconds for statusMap
          "mainMotor": data["motors"]?["0"] == true ? "on" : "off",
          "activeMotorsList":
          (data["motors"] as Map?)?.entries
              .where((e) => e.value == true)
              .map((e) => e.key)
              .toList() ??
              [],
        };
      }
    }
    return null;
  }

  // Motor Controls
  Future<bool> toggleMainMotor(bool isOn) async {
    return _toggleMotor(0, isOn);
  }

  Future<bool> toggleMotor(int motorId, bool isOn) async {
    return _toggleMotor(motorId, isOn);
  }

  Future<Map<String, dynamic>?> getMoistureData() async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    String? deviceId = prefs.getString("esp_device_id");

    if (ip != null && ip.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse("http://$ip:$port/api/moisture"))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
      } catch (_) {}
    }

    // Firebase fallback if local fails or IP is missing
    if (deviceId != null && deviceId.isNotEmpty) {
      final snapshot = await _db.ref("devices/$deviceId").get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final firebaseMoisture = data["moisture"] as Map?;
        if (firebaseMoisture != null) {
          // Standardize to match ESP32 JSON format
          return {
            "main_motor": {"percent": data["mainMotorMoisture"] ?? 0},
            ...firebaseMoisture.map(
                  (key, value) => MapEntry(key, {"percent": value}),
            ),
          };
        }
      }
    }
    return null;
  }

  Future<bool> toggleAllMotors(bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    String? deviceId = prefs.getString("esp_device_id");

    bool localSuccess = false;

    // Try Local WiFi
    if (ip != null && ip.isNotEmpty) {
      String url = "http://$ip:$port${isOn ? "/api/all/on" : "/api/all/off"}";
      try {
        final response = await http
            .post(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        localSuccess = response.statusCode == 200;
      } catch (_) {}
    }

    // Always update Firebase to keep it in sync
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        if (!isOn) {
          // Use the stopAll trigger I added to the ESP32 code
          await _db.ref("devices/$deviceId/stopAll").set(true);
          // Set all individual motors to false in Firebase
          await Future.wait([
            for (int i = 0; i < 9; i++)
              _db.ref("devices/$deviceId/motors/$i").set(false),
          ]);
        } else {
          // Set all individual motors to true in Firebase
          await Future.wait([
            for (int i = 0; i < 9; i++)
              _db.ref("devices/$deviceId/motors/$i").set(true),
          ]);
        }
        return true;
      } catch (_) {}
    }
    return localSuccess;
  }

  Future<bool> _toggleMotor(int motorId, bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString("esp_ip");
    int port = prefs.getInt("esp_port") ?? 80;
    String? deviceId = prefs.getString("esp_device_id");

    bool localSuccess = false;

    // Try Local WiFi first
    if (ip != null && ip.isNotEmpty) {
      String url =
          "http://$ip:$port${isOn ? (motorId == 0 ? "/api/mainmotor/on" : "/api/motor/on?motor_id=$motorId") : (motorId == 0 ? "/api/mainmotor/off" : "/api/motor/off?motor_id=$motorId")}";
      try {
        final response = await http
            .post(Uri.parse(url))
            .timeout(const Duration(seconds: 2));
        localSuccess = response.statusCode == 200;
      } catch (_) {}
    }

    // Always update Firebase to keep it in sync
    if (deviceId != null && deviceId.isNotEmpty) {
      try {
        await _db.ref("devices/$deviceId/motors/${motorId.toString()}").set(isOn);
        return true;
      } catch (_) {}
    }

    return localSuccess;
  }

  // Configuration & Discovery Logic (Moved from Esp32ConfigService)
  Future<bool> checkInitialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString("esp_ip");
    int savedPort = prefs.getInt("esp_port") ?? 80;

    if (savedIp != null && savedIp.isNotEmpty) {
      return (await verifyConnectionAndGetDetails(savedIp, savedPort)) != null;
    }
    return false;
  }

  Future<Map<String, dynamic>?> startAutoDiscovery() async {
    // 1. Try mDNS first
    Map<String, dynamic>? info = await discoverViaMDNS();
    if (info != null) return info;

    // 2. Fallback to Subnet Scan
    return await discoverViaIPScan();
  }

  Future<void> saveConfig(String ip, int port, {String? deviceId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("esp_ip", ip);
    await prefs.setInt("esp_port", port);
    if (deviceId != null) {
      await prefs.setString("esp_device_id", deviceId);
    }
  }

  // Helper Discovery Methods
  Future<Map<String, dynamic>?> discoverViaMDNS() async {
    final MDnsClient client = MDnsClient();
    try {
      await client.start();
      await for (final PtrResourceRecord ptr
      in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer('_http._tcp.local'),
      )) {
        await for (final SrvResourceRecord srv
        in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip
          in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            String ipStr = ip.address.address;
            var details = await verifyConnectionAndGetDetails(ipStr, srv.port);
            if (details != null) {
              client.stop();
              return details;
            }
          }
        }
      }
    } catch (_) {
    } finally {
      client.stop();
    }
    return null;
  }

  Future<Map<String, dynamic>?> discoverViaIPScan() async {
    try {
      final info = NetworkInfo();
      String? myIp = await info.getWifiIP();
      if (myIp == null || myIp.isEmpty) return null;

      String subnet = myIp.substring(0, myIp.lastIndexOf('.'));
      for (int i = 1; i <= 255; i++) {
        String testIp = "$subnet.$i";
        var details = await verifyConnectionAndGetDetails(testIp, 80);
        if (details != null) {
          return details;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> verifyConnectionAndGetDetails(
      String ip,
      int port,
      ) async {
    try {
      final res = await http
          .get(Uri.parse("http://$ip:$port/api/system/status"))
          .timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String deviceId = data['deviceId'] ?? 'UNKNOWN_ID';
        await saveConfig(ip, port, deviceId: deviceId);
        return {'ip': ip, 'deviceId': deviceId};
      }
    } catch (_) {}
    return null;
  }

  Future<bool> verifyConnection(String ip, int port) async {
    return (await verifyConnectionAndGetDetails(ip, port)) != null;
  }
}
