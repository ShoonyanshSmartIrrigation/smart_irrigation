// import 'esp32_service.dart';
//
// class Esp32ConfigService {
//   static final Esp32ConfigService _instance = Esp32ConfigService._internal();
//   factory Esp32ConfigService() => _instance;
//   Esp32ConfigService._internal();
//
//   final Esp32Service _esp32service = Esp32Service();
//
//   Future<bool> checkInitialStatus() async {
//     return await _esp32service.checkInitialStatus();
//   }
//
//   Future<String?> startAutoDiscovery() async {
//     return await _esp32service.startAutoDiscovery();
//   }
//
//   Future<void> saveConfig(String ip, int port) async {
//     await _esp32service.saveConfig(ip, port);
//   }
// }
