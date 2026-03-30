import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data_manager.dart';
import 'esp32_service.dart';

class DashboardStrings {
  static const disconnected = "DISCONNECTED";
  static const systemOnline = "SYSTEM ONLINE";
  static const noNetwork = "NO NETWORK";
  static const loading = "CHECKING...";
}

class DashboardService extends ChangeNotifier {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DataManager _dataManager = DataManager();
  final Esp32Service _esp32Service = Esp32Service();
  late SharedPreferences _prefs;

  // State
  bool mainMotor = false;
  bool autoMode = false;
  String connectionStatus = DashboardStrings.disconnected;
  String userName = "User";
  bool mainPumpError = false;
  bool autoModeError = false;
  int timerSeconds = 60;
  int selectedMinutes = 1;

  // Internal flags
  bool _isDisposed = false;
  bool _isProcessingMainPump = false;
  bool _isProcessingAutoMode = false;
  bool _isInitialized = false;

  // Timers
  Timer? _moistureTimer;
  Timer? _irrigationTimer;
  Timer? _connectionCheckTimer;
  Timer? _connectivityDebounce;
  StreamSubscription? _connectivitySubscription;

  // Callbacks
  VoidCallback? onIrrigationComplete;

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await loadUserData();
      _setupConnectivityListener();
      _startPeriodicTasks();
      _isInitialized = true;
    } catch (e) {
      debugPrint("DashboardService Init Error: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _moistureTimer?.cancel();
    _irrigationTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _connectivityDebounce?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _updateState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> loadUserData() async {
    try {
      final name = _prefs.getString('userName') ?? "Farmer James";
      _updateState(() => userName = name);
    } catch (e) {
      debugPrint("Error fetching username: $e");
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _connectivityDebounce?.cancel();
      _connectivityDebounce = Timer(const Duration(milliseconds: 500), () {
        if (results.contains(ConnectivityResult.none)) {
          _updateState(() => connectionStatus = DashboardStrings.noNetwork);
        } else {
          checkEspConnection();
        }
      });
    });
  }

  void _startPeriodicTasks() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      checkEspConnection();
    });

    _moistureTimer?.cancel();
    _moistureTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _dataManager.simulateMoisture();
      notifyListeners();
    });
  }

  Future<bool> checkEspConnection() async {
    if (_isDisposed) return false;
    
    try {
      bool isConnected = await _esp32Service.checkConnection().timeout(const Duration(seconds: 5));
      _updateState(() {
        connectionStatus = isConnected ? DashboardStrings.systemOnline : DashboardStrings.disconnected;
      });
      return isConnected;
    } catch (e) {
      _updateState(() => connectionStatus = DashboardStrings.disconnected);
      return false;
    }
  }

  Future<bool> toggleMainPump(bool value) async {
    if (_isProcessingMainPump || _isDisposed) return false;
    
    _isProcessingMainPump = true;
    try {
      bool success = await _esp32Service.toggleMainMotor(value).timeout(const Duration(seconds: 5));
      _updateState(() {
        if (success) {
          mainMotor = value;
          mainPumpError = false;
        } else {
          _setMainPumpError();
        }
      });
      return success;
    } catch (e) {
      _updateState(() => _setMainPumpError());
      return false;
    } finally {
      _isProcessingMainPump = false;
    }
  }

  void _setMainPumpError() {
    mainMotor = false;
    mainPumpError = true;
    Timer(const Duration(seconds: 3), () {
      _updateState(() => mainPumpError = false);
    });
  }

  Future<bool> toggleAllMotors(bool value) async {
    if (_isProcessingAutoMode || _isDisposed) return false;

    _isProcessingAutoMode = true;
    try {
      bool success = await _esp32Service.toggleAllMotors(value).timeout(const Duration(seconds: 5));
      _updateState(() {
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
      });
      return success;
    } catch (e) {
      _updateState(() => _setAutoModeError());
      return false;
    } finally {
      _isProcessingAutoMode = false;
    }
  }

  void _setAutoModeError() {
    autoModeError = true;
    Timer(const Duration(seconds: 3), () {
      _updateState(() => autoModeError = false);
    });
  }

  void startIrrigationTimer() {
    // Production Fix: Always reset explicitly to avoid inconsistent time if changed mid-run
    _updateState(() => timerSeconds = selectedMinutes * 60);
    
    _irrigationTimer?.cancel();
    _irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (timerSeconds > 0) {
        _updateState(() => timerSeconds--);
      } else {
        timer.cancel();
        _finalizeIrrigation();
      }
    });
  }

  void _finalizeIrrigation() {
    if (mainMotor) toggleMainPump(false);
    if (autoMode) toggleAllMotors(false);
    onIrrigationComplete?.call();
    notifyListeners();
  }

  void stopIrrigationTimer() {
    _irrigationTimer?.cancel();
    _updateState(() => timerSeconds = selectedMinutes * 60);
  }

  void setTimerDuration(int minutes) {
    _updateState(() {
      selectedMinutes = minutes;
      if (_irrigationTimer == null || !_irrigationTimer!.isActive) {
        timerSeconds = minutes * 60;
      }
    });
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
