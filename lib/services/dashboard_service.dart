// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
import '../data_manager.dart';
// import 'esp32_service.dart';
// import 'plant_service.dart';
// import 'weather_service.dart';
//
// //-------------------------------------------------------- DashboardStrings Class ----------------------------------------------------------
// class DashboardStrings {
//   static const disconnected = "DISCONNECTED";
//   static const systemOnline = "SYSTEM ONLINE";
//   static const noNetwork = "NO NETWORK";
//   static const loading = "CHECKING...";
// }
//
// //-------------------------------------------------------- DashboardService Class ----------------------------------------------------------
// class DashboardService extends ChangeNotifier with WidgetsBindingObserver {
//   static final DashboardService _instance = DashboardService._internal();
//   factory DashboardService() => _instance;
//   DashboardService._internal();
//
//   final DataManager _dataManager = DataManager();
//   final Esp32Service _esp32Service = Esp32Service();
//   final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   late SharedPreferences _prefs;
//
//   // State
//   bool mainMotor = false;
//   bool autoMode = false;
//   String connectionStatus = DashboardStrings.disconnected;
//   String lastSeenText = "";
//   String userName = "User";
//   bool mainPumpError = false;
//   bool autoModeError = false;
//   int timerSeconds = 60;
//   int selectedMinutes = 1;
//
//   // Weather State
//   String weatherCondition = "Mostly Sunny";
//   String weatherTemp = "28°C";
//   String weatherIcon = "01d";
//   String weatherCity = "Unknown City";
//
//   // Device Setup State
//   bool isDeviceConfigured = true;
//   bool isConfiguringDevice = false;
//   List<dynamic> scannedNetworks = [];
//   String? configurationError;
//
//   // Internal flags
//   bool _isDisposed = false;
//   bool _isProcessingMainPump = false;
//   bool _isProcessingAutoMode = false;
//   bool _isInitialized = false;
//
//   // Timers
//   Timer? _moistureTimer;
//   Timer? _irrigationTimer;
//   Timer? _connectionCheckTimer;
//   Timer? _connectivityDebounce;
//   StreamSubscription? _connectivitySubscription;
//
//   // Callbacks
//   VoidCallback? onIrrigationComplete;
//
//   Future<void> init() async {
//     _isDisposed = false;
//     WidgetsBinding.instance.addObserver(this);
//     if (_isInitialized) return;
//
//     try {
//       _prefs = await SharedPreferences.getInstance();
//       await loadUserData();
//       await checkDeviceConfiguration();
//       // await fetchWeatherData();
//
//       _setupConnectivityListener();
//       _startPeriodicTasks();
//       _isInitialized = true;
//     } catch (e) {
//       debugPrint("DashboardService Init Error: $e");
//     }
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       checkEspConnection(); // Trigger status update on app resume/reconnect
//     }
//   }
//
//   @override
//   //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
//   void dispose() {
//     _isDisposed = true;
//     WidgetsBinding.instance.removeObserver(this);
//     _moistureTimer?.cancel();
//     _irrigationTimer?.cancel();
//     _connectionCheckTimer?.cancel();
//     _connectivityDebounce?.cancel();
//     _connectivitySubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   void notifyListeners() {
//     if (!_isDisposed) {
//       super.notifyListeners();
//     }
//   }
//
//   // Reset method called on logout
//   void reset() {
//     _isInitialized = false;
//     userName = "User";
//     lastSeenText = "";
//     connectionStatus = DashboardStrings.disconnected;
//     isDeviceConfigured = false;
//     weatherCity = "Unknown City";
//     _moistureTimer?.cancel();
//     _irrigationTimer?.cancel();
//     _connectionCheckTimer?.cancel();
//     _connectivityDebounce?.cancel();
//     _connectivitySubscription?.cancel();
//     notifyListeners();
//   }
//
//   void _updateState(VoidCallback fn) {
//     fn();
//     notifyListeners();
//   }
//
//   Future<void> checkDeviceConfiguration() async {
//     isDeviceConfigured = _prefs.getBool('isDeviceConfigured') ?? false;
//     notifyListeners();
//   }
//
//   Future<void> setDeviceConfigured(bool value) async {
//     await _prefs.setBool('isDeviceConfigured', value);
//     _updateState(() => isDeviceConfigured = value);
//   }
//
//   Future<void> loadUserData() async {
//     try {
//       final name = await _secureStorage.read(key: 'userName');
//       if (name != null && name.isNotEmpty) {
//         _updateState(() => userName = name);
//       } else {
//         final legacyName = _prefs.getString('userName') ?? "Farmer";
//         _updateState(() => userName = legacyName);
//       }
//     } catch (e) {
//       debugPrint("Error fetching username in DashboardService: $e");
//     }
//   }
//   //
//   // Future<void> fetchWeatherData() async {
//   //   final data = await WeatherService().fetchWeather();
//   //   if (data != null && !_isDisposed) {
//   //     _updateState(() {
//   //       if (data.containsKey('error')) {
//   //         weatherCity = data['error'];
//   //       } else {
//   //         weatherTemp = "${data['main']['temp'].round()}°C";
//   //         weatherCondition = data['weather'][0]['main'];
//   //         weatherIcon = data['weather'][0]['icon'];
//   //         weatherCity = data['name'] ?? "Unknown City";
//   //       }
//   //     });
//   //   }
//   // }
//
//   // --- Normal Dashboard Logic ---
//   void _setupConnectivityListener() {
//     _connectivitySubscription?.cancel();
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       List<ConnectivityResult> results,
//     ) {
//       _connectivityDebounce?.cancel();
//       _connectivityDebounce = Timer(const Duration(milliseconds: 500), () {
//         if (results.contains(ConnectivityResult.none)) {
//           _updateState(() => connectionStatus = DashboardStrings.noNetwork);
//         } else {
//           checkEspConnection();
//         }
//       });
//     });
//   }
//
//   void _startPeriodicTasks() {
//     _connectionCheckTimer?.cancel();
//     _connectionCheckTimer = Timer.periodic(const Duration(seconds: 15), (
//       timer,
//     ) {
//       checkEspConnection();
//     });
//
//     _moistureTimer?.cancel();
//     _moistureTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
//       await PlantService().fetchMoistureData();
//       notifyListeners();
//     });
//   }
//
//   Future<bool> checkEspConnection() async {
//     if (_isDisposed) return false;
//     try {
//       final statusMap = await _esp32Service.getSystemStatus().timeout(
//         const Duration(seconds: 5),
//       );
//       bool isConnected = statusMap?['status'] == 'ok';
//
//       String lastSeenStr = "";
//       if (statusMap?.containsKey('lastSeen') == true && statusMap!['lastSeen'] != null) {
//         int lastSeen = statusMap['lastSeen'] as int;
//         if (lastSeen > 0) {
//           final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(lastSeen * 1000);
//           final diff = DateTime.now().difference(lastSeenDate);
//           if (diff.inMinutes < 1) {
//             lastSeenStr = "Just now";
//           } else if (diff.inHours < 1) {
//             lastSeenStr = "\${diff.inMinutes}m ago";
//           } else if (diff.inDays < 1) {
//             lastSeenStr = "\${diff.inHours}h ago";
//           } else {
//             lastSeenStr = "\${diff.inDays}d ago";
//           }
//         }
//       }
//
//       _updateState(() {
//         connectionStatus = isConnected
//             ? DashboardStrings.systemOnline
//             : DashboardStrings.disconnected;
//         lastSeenText = lastSeenStr;
//         if (isConnected) {
//           mainMotor = statusMap!['mainMotor'] == 'on';
//           autoMode = statusMap['autoMode'] == true;
//
//           _dataManager.mainMotorOn = mainMotor;
//           _dataManager.isSystemAutoMode = autoMode;
//
//           if (statusMap.containsKey('activeMotorsList')) {
//             List<dynamic> activeList = statusMap['activeMotorsList'];
//             for (var plant in _dataManager.plants) {
//               plant.isMotorOn =
//                   activeList.contains(plant.id) ||
//                   activeList.contains(plant.id.toString());
//             }
//           }
//
//           try {
//             PlantService()
//                 .notifyListeners(); // Force Plant Control Screen to refresh UI
//           } catch (_) {}
//         }
//       });
//       return isConnected;
//     } catch (e) {
//       _updateState(() => connectionStatus = DashboardStrings.disconnected);
//       return false;
//     }
//   }
//
//   Future<bool> toggleMainPump(bool value) async {
//     if (_isProcessingMainPump || _isDisposed) return false;
//     _isProcessingMainPump = true;
//     try {
//       // Act as Master Switch: Toggle ALL motors on/off
//       bool success = await _esp32Service
//           .toggleAllMotors(value)
//           .timeout(const Duration(seconds: 5));
//       _updateState(() {
//         if (success) {
//           mainMotor = value;
//           mainPumpError = false;
//
//           // Update DataManager state to reflect on Plant Control Screen
//           _dataManager.mainMotorOn = value;
//           _dataManager.isSystemAutoMode = value;
//           _dataManager.updateAllMotorsLocally(value);
//
//           // Notify PlantService to update UI on Plant Control Screen
//           try {
//             PlantService().notifyListeners();
//           } catch (e) {
//             debugPrint("Error notifying PlantService: $e");
//           }
//         } else {
//           _setMainPumpError();
//         }
//       });
//       return success;
//     } catch (e) {
//       _updateState(() => _setMainPumpError());
//       return false;
//     } finally {
//       _isProcessingMainPump = false;
//     }
//   }
//
//   void _setMainPumpError() {
//     mainMotor = false;
//     mainPumpError = true;
//     Timer(const Duration(seconds: 3), () {
//       _updateState(() => mainPumpError = false);
//     });
//   }
//
//   Future<bool> toggleAllMotors(bool value) async {
//     if (_isProcessingAutoMode || _isDisposed) return false;
//     _isProcessingAutoMode = true;
//     try {
//       bool success = await _esp32Service
//           .toggleAllMotors(value)
//           .timeout(const Duration(seconds: 5));
//       _updateState(() {
//         if (success) {
//           autoMode = value;
//           autoModeError = false;
//
//           // Also update individual motors for the Plant Control screen
//           _dataManager.isSystemAutoMode = value;
//           _dataManager.updateAllMotorsLocally(value);
//           try {
//             PlantService().notifyListeners();
//           } catch (e) {
//             debugPrint("Error notifying PlantService: $e");
//           }
//
//           if (value) {
//             startIrrigationTimer();
//           } else {
//             stopIrrigationTimer();
//           }
//         } else {
//           _setAutoModeError();
//         }
//       });
//       return success;
//     } catch (e) {
//       _updateState(() => _setAutoModeError());
//       return false;
//     } finally {
//       _isProcessingAutoMode = false;
//     }
//   }
//
//   void _setAutoModeError() {
//     autoModeError = true;
//     Timer(const Duration(seconds: 3), () {
//       _updateState(() => autoModeError = false);
//     });
//   }
//
//   void startIrrigationTimer() {
//     _updateState(() => timerSeconds = selectedMinutes * 60);
//     _irrigationTimer?.cancel();
//     _irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_isDisposed) {
//         timer.cancel();
//         return;
//       }
//       if (timerSeconds > 0) {
//         _updateState(() => timerSeconds--);
//       } else {
//         timer.cancel();
//         _finalizeIrrigation();
//       }
//     });
//   }
//
//   void _finalizeIrrigation() {
//     if (mainMotor) toggleMainPump(false);
//     if (autoMode) toggleAllMotors(false);
//     onIrrigationComplete?.call();
//     notifyListeners();
//   }
//
//   void stopIrrigationTimer() {
//     _irrigationTimer?.cancel();
//     _updateState(() => timerSeconds = selectedMinutes * 60);
//   }
//
//   void setTimerDuration(int minutes) {
//     _updateState(() {
//       selectedMinutes = minutes;
//       if (_irrigationTimer == null || !_irrigationTimer!.isActive) {
//         timerSeconds = minutes * 60;
//       }
//     });
//   }
//
//   String getTimerText() {
//     int min = timerSeconds ~/ 60;
//     int sec = timerSeconds % 60;
//     return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
//   }
//
//   DataManager get dataManager => _dataManager;
//   bool get isIrrigationRunning => _irrigationTimer?.isActive ?? false;
//   Stream<List<ConnectivityResult>> get connectivityStream =>
//       Connectivity().onConnectivityChanged;
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../data_manager.dart';
import 'communications/wifi_service.dart';
import 'communications/bluetooth_service.dart';
import 'communications/unified_command_service.dart';
import 'plant_service.dart';

//-------------------------------------------------------- DashboardStrings Class ----------------------------------------------------------
class DashboardStrings {
  static const disconnected = "DISCONNECTED";
  static const systemOnline = "SYSTEM ONLINE";
  static const noNetwork = "NO NETWORK";
  static const loading = "CHECKING...";
  static const wifi = "WIFI";
  static const ble = "BLE";
  static const cloud = "CLOUD";
}

//-------------------------------------------------------- DashboardService Class ----------------------------------------------------------
class DashboardService extends ChangeNotifier with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DataManager _dataManager = DataManager();
  final WifiService _wifiService = WifiService();
  final BleService _bleService = BleService();
  final UnifiedCommandService _unifiedCommandService = UnifiedCommandService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late SharedPreferences _prefs;

  // State
  bool mainMotor = false;
  bool autoMode = false;
  String connectionStatus = DashboardStrings.disconnected;
  String connectionType = "NONE";
  String lastSeenText = "";
  String userName = "User";
  bool mainPumpError = false;
  bool autoModeError = false;
  int timerSeconds = 60;
  int selectedMinutes = 1;
  bool allPlantsAutoMode = false;
  // Weather State
  String weatherCondition = "Mostly Sunny";
  String weatherTemp = "28°C";
  String weatherIcon = "01d";
  String weatherCity = "Unknown City";

  // Device Setup State
  bool isDeviceConfigured = true;
  bool isConfiguringDevice = false;
  List<dynamic> scannedNetworks = [];
  String? configurationError;

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
    _isDisposed = false;
    WidgetsBinding.instance.addObserver(this);
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await loadUserData();
      await checkDeviceConfiguration();

      _setupConnectivityListener();
      _startPeriodicTasks();
      _isInitialized = true;
    } catch (e) {
      debugPrint("DashboardService Init Error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkEspConnection(); // Trigger status update on app resume/reconnect
    }
  }

  @override
  //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
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

  // Reset method called on logout
  void reset() {
    _isInitialized = false;
    userName = "User";
    lastSeenText = "";
    connectionStatus = DashboardStrings.disconnected;
    isDeviceConfigured = false;
    weatherCity = "Unknown City";
    _moistureTimer?.cancel();
    _irrigationTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _connectivityDebounce?.cancel();
    _connectivitySubscription?.cancel();
    notifyListeners();
  }

  void _updateState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  Future<void> checkDeviceConfiguration() async {
    isDeviceConfigured = _prefs.getBool('isDeviceConfigured') ?? false;
    notifyListeners();
  }

  Future<void> setDeviceConfigured(bool value) async {
    await _prefs.setBool('isDeviceConfigured', value);
    _updateState(() => isDeviceConfigured = value);
  }

  Future<void> loadUserData() async {
    try {
      final name = await _secureStorage.read(key: 'userName');
      if (name != null && name.isNotEmpty) {
        _updateState(() => userName = name);
      } else {
        final legacyName = _prefs.getString('userName') ?? "Farmer";
        _updateState(() => userName = legacyName);
      }
    } catch (e) {
      debugPrint("Error fetching username in DashboardService: $e");
    }
  }

  // --- Normal Dashboard Logic ---
  void _setupConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
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
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 15), (
      timer,
    ) {
      checkEspConnection();
    });

    _moistureTimer?.cancel();
    _moistureTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await PlantService().fetchMoistureData();
      notifyListeners();
    });
  }

  Future<bool> checkEspConnection() async {
    if (_isDisposed) return false;

    bool bleConnected = _bleService.isConnected;
    Map<String, dynamic>? statusMap;

    try {
      statusMap = await _wifiService.getSystemStatus().timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint("DashboardService Connection Check Error: $e");
    }

    bool wifiOrCloudConnected = statusMap?['status'] == 'ok';
    bool isRemote = statusMap?['remote'] == true;

    String lastSeenStr = "";
    if (statusMap?.containsKey('lastSeen') == true &&
        statusMap!['lastSeen'] != null) {
      int lastSeen = statusMap['lastSeen'] as int;
      if (lastSeen > 0) {
        final lastSeenDate = DateTime.fromMillisecondsSinceEpoch(
          lastSeen * 1000,
        );
        lastSeenStr = DateFormat('HH:mm').format(lastSeenDate);
      }
    }

    _updateState(() {
      lastSeenText = lastSeenStr;

      if (bleConnected) {
        connectionStatus = DashboardStrings.systemOnline;
        connectionType = DashboardStrings.ble;
        if (lastSeenStr.isEmpty) lastSeenText = "Live";
      } else if (wifiOrCloudConnected) {
        connectionStatus = DashboardStrings.systemOnline;
        connectionType = isRemote ? DashboardStrings.cloud : DashboardStrings.wifi;
      } else {
        connectionStatus = DashboardStrings.disconnected;
        connectionType = "NONE";
      }

      if (wifiOrCloudConnected && statusMap != null) {
        mainMotor = statusMap['mainMotor'] == 'on';
        autoMode = statusMap['autoMode'] == true;

        _dataManager.mainMotorOn = mainMotor;
        _dataManager.isSystemAutoMode = autoMode;

        if (statusMap.containsKey('activeMotorsList')) {
          List<dynamic> activeList = statusMap['activeMotorsList'];
          for (var plant in _dataManager.plants) {
            plant.isMotorOn =
                activeList.contains(plant.id) ||
                    activeList.contains(plant.id.toString());
          }
        }

        try {
          PlantService().notifyListeners();
        } catch (_) {}
      }
    });

    return bleConnected || wifiOrCloudConnected;
  }

  Future<bool> toggleMainPump(bool value) async {
    if (_isProcessingMainPump || _isDisposed) return false;
    _isProcessingMainPump = true;
    try {
      // Act as Master Switch: Toggle ALL motors on/off
      bool success = await _unifiedCommandService
          .toggleAllMotors(value)
          .timeout(const Duration(seconds: 5));
      _updateState(() {
        if (success) {
          mainMotor = value;
          mainPumpError = false;

          // Update DataManager state to reflect on Plant Control Screen
          _dataManager.mainMotorOn = value;
          _dataManager.isSystemAutoMode = value;
          _dataManager.updateAllMotorsLocally(value);

          // Notify PlantService to update UI on Plant Control Screen
          try {
            PlantService().notifyListeners();
          } catch (e) {
            debugPrint("Error notifying PlantService: $e");
          }
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
      bool success = await _unifiedCommandService
          .toggleAllMotors(value)
          .timeout(const Duration(seconds: 5));
      _updateState(() {
        if (success) {
          autoMode = value;
          autoModeError = false;

          // Also update individual motors for the Plant Control screen
          _dataManager.isSystemAutoMode = value;
          _dataManager.updateAllMotorsLocally(value);
          try {
            PlantService().notifyListeners();
          } catch (e) {
            debugPrint("Error notifying PlantService: $e");
          }

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

  Future<void> toggleAllPlantsAutoMode(bool value) async {
    if (_isDisposed) return;

    _updateState(() {
      allPlantsAutoMode = value;

      // Apply auto mode to ALL plants
      for (var plant in _dataManager.plants) {
        plant.isAutoMode = value;
      }
    });

    // Notify PlantService so UI updates
    try {
      PlantService().notifyListeners();
    } catch (e) {
      debugPrint("Error notifying PlantService: $e");
    }
  }

  DataManager get dataManager => _dataManager;
  bool get isIrrigationRunning => _irrigationTimer?.isActive ?? false;
  Stream<List<ConnectivityResult>> get connectivityStream =>
      Connectivity().onConnectivityChanged;
}
