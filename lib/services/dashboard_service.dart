import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data_manager.dart';
import 'esp32_service.dart';

class DashboardService extends ChangeNotifier {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DataManager _dataManager = DataManager();
  final Esp32Service _esp32Service = Esp32Service();

  // State
  bool mainMotor = false;
  bool autoMode = false;
  String connectionStatus = "Disconnected";
  String userName = "User";
  bool mainPumpError = false;
  bool autoModeError = false;
  int timerSeconds = 60;
  int selectedMinutes = 1;

  // Timers
  Timer? _moistureTimer;
  Timer? _irrigationTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription? _connectivitySubscription;

  // Callbacks
  VoidCallback? onIrrigationComplete;

  void init() {
    loadUserData();
    _setupConnectivityListener();
    _startPeriodicTasks();
  }

  @override
  void dispose() {
    _moistureTimer?.cancel();
    _irrigationTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> loadUserData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('userName') ?? "Farmer James";
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching username: $e");
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        connectionStatus = "No Network";
        notifyListeners();
      } else {
        checkEspConnection();
      }
    });
  }

  void _startPeriodicTasks() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkEspConnection();
    });

    _moistureTimer?.cancel();
    _moistureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _dataManager.simulateMoisture();
      notifyListeners();
    });
  }

  Future<bool> checkEspConnection() async {
    try {
      bool isConnected = await _esp32Service.checkConnection().timeout(const Duration(seconds: 5));
      connectionStatus = isConnected ? "SYSTEM ONLINE" : "DISCONNECTED";
      notifyListeners();
      return isConnected;
    } catch (e) {
      connectionStatus = "DISCONNECTED";
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleMainPump(bool value) async {
    try {
      bool success = await _esp32Service.toggleMainMotor(value).timeout(const Duration(seconds: 5));
      if (success) {
        mainMotor = value;
        mainPumpError = false;
      } else {
        _setMainPumpError();
      }
      notifyListeners();
      return success;
    } catch (e) {
      _setMainPumpError();
      notifyListeners();
      return false;
    }
  }

  void _setMainPumpError() {
    mainMotor = false;
    mainPumpError = true;
    Timer(const Duration(seconds: 3), () {
      mainPumpError = false;
      notifyListeners();
    });
  }

  Future<bool> toggleAllMotors(bool value) async {
    try {
      bool success = await _esp32Service.toggleAllMotors(value).timeout(const Duration(seconds: 5));
      if (success) {
        autoMode = value;
        autoModeError = false;
        if (value) {
          startIrrigationTimer();
        } else {
          stopIrrigationTimer();
        }
      } else {
        _setAutoModeError();
      }
      notifyListeners();
      return success;
    } catch (e) {
      _setAutoModeError();
      notifyListeners();
      return false;
    }
  }

  void _setAutoModeError() {
    autoModeError = true;
    Timer(const Duration(seconds: 3), () {
      autoModeError = false;
      notifyListeners();
    });
  }

  void startIrrigationTimer() {
    if (timerSeconds == 0) {
      timerSeconds = selectedMinutes * 60;
    }
    _irrigationTimer?.cancel();
    _irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        timerSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        if (mainMotor) toggleMainPump(false);
        if (autoMode) toggleAllMotors(false);
        onIrrigationComplete?.call();
        notifyListeners();
      }
    });
  }

  void stopIrrigationTimer() {
    _irrigationTimer?.cancel();
    timerSeconds = selectedMinutes * 60;
    notifyListeners();
  }

  void setTimerDuration(int minutes) {
    selectedMinutes = minutes;
    if (_irrigationTimer == null || !_irrigationTimer!.isActive) {
      timerSeconds = minutes * 60;
    }
    notifyListeners();
  }

  String getTimerText() {
    int min = timerSeconds ~/ 60;
    int sec = timerSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  DataManager get dataManager => _dataManager;
  bool get isIrrigationRunning => _irrigationTimer?.isActive ?? false;
  Stream<List<ConnectivityResult>> get connectivityStream => Connectivity().onConnectivityChanged;
}
