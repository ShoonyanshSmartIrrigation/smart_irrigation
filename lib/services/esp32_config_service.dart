import 'package:shared_preferences/shared_preferences.dart';
import 'esp32_service.dart';

class Esp32ConfigService {
  static final Esp32ConfigService _instance = Esp32ConfigService._internal();
  factory Esp32ConfigService() => _instance;
  Esp32ConfigService._internal();

  final Esp32Service _esp32service = Esp32Service();

  Future<bool> checkInitialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString("esp_ip");
    int savedPort = prefs.getInt("esp_port") ?? 80;

    if (savedIp != null && savedIp.isNotEmpty) {
      return await _esp32service.verifyConnection(savedIp, savedPort);
    }
    return false;
  }

  Future<String?> startAutoDiscovery() async {
    // 1. Try mDNS first
    String? ip = await _esp32service.discoverViaMDNS();
    if (ip != null) return ip;

    // 2. Fallback to Subnet Scan
    return await _esp32service.discoverViaIPScan();
  }

  Future<void> saveConfig(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("esp_ip", ip);
    await prefs.setInt("esp_port", port);
  }
}
