import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data_manager.dart';
import 'esp32_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DataManager _dataManager = DataManager();
  final Esp32Service _esp32Service = Esp32Service();

  Future<String> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? "Farmer James";
  }

  void simulateMoisture() {
    _dataManager.simulateMoisture();
  }

  Future<bool> checkEspConnection() async {
    return await _esp32Service.checkConnection();
  }

  Future<bool> toggleMainPump(bool value) async {
    return await _esp32Service.toggleMainMotor(value);
  }

  Future<bool> toggleAllMotors(bool value) async {
    return await _esp32Service.toggleAllMotors(value);
  }

  Stream<List<ConnectivityResult>> get connectivityStream => Connectivity().onConnectivityChanged;

  DataManager get dataManager => _dataManager;
}
