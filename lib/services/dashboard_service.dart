import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data_manager.dart';
import 'esp32_service.dart';
import 'plant_service.dart';
import 'weather_service.dart';

//-------------------------------------------------------- DashboardStrings Class ----------------------------------------------------------
class DashboardStrings {
  static const disconnected = "DISCONNECTED";
  static const systemOnline = "SYSTEM ONLINE";
  static const noNetwork = "NO NETWORK";
  static const loading = "CHECKING...";
}

//-------------------------------------------------------- DashboardService Class ----------------------------------------------------------
class DashboardService extends ChangeNotifier with WidgetsBindingObserver {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final DataManager _dataManager = DataManager();
  final Esp32Service _esp32Service = Esp32Service();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  // Weather State
  String weatherCondition = "Mostly Sunny";
  String weatherTemp = "28°C";
  String weatherIcon = "01d";

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
      await fetchWeatherData();
      
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

  Future<void> fetchWeatherData() async {
    final data = await WeatherService().fetchWeather();
    if (data != null && !_isDisposed) {
      _updateState(() {
        weatherTemp = "${data['main']['temp'].round()}°C";
        weatherCondition = data['weather'][0]['main'];
        weatherIcon = data['weather'][0]['icon'];
      });
    }
  }

  Future<void> startWifiScan() async {
    debugPrint("DashboardService: Starting WiFi Scan...");
    _updateState(() {
      isConfiguringDevice = true;
      configurationError = null;
      scannedNetworks = [];
    });

    try {
      if (!await WiFiForIoTPlugin.isEnabled()) {
        await WiFiForIoTPlugin.setEnabled(true);
        await Future.delayed(const Duration(seconds: 2));
      }

      PermissionStatus status = await Permission.locationWhenInUse.request();
      if (status.isDenied) throw "Location permission required.";

      if (!await Permission.location.serviceStatus.isEnabled) {
        throw "Please turn ON GPS to scan for devices.";
      }

      List<dynamic> results = [];
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        await Future.delayed(const Duration(seconds: 4));
        results = await WiFiScan.instance.getScannedResults();
      }

      // Fallback via wifi_scan is already handled above.

      // Sort: ESP32 SSIDs first
      results.sort((a, b) {
        String ssidA = (a is WiFiAccessPoint) ? a.ssid : (a.ssid ?? "");
        String ssidB = (b is WiFiAccessPoint) ? b.ssid : (b.ssid ?? "");
        bool isAEsp = ssidA.toUpperCase().contains("ESP32");
        bool isBEsp = ssidB.toUpperCase().contains("ESP32");
        if (isAEsp && !isBEsp) return -1;
        if (!isAEsp && isBEsp) return 1;
        return ssidA.compareTo(ssidB);
      });

      _updateState(() {
        scannedNetworks = results;
        isConfiguringDevice = false;
        if (results.isEmpty) configurationError = "No devices found. Ensure ESP32 is nearby.";
      });

    } catch (e) {
      _updateState(() {
        configurationError = e.toString();
        isConfiguringDevice = false;
      });
    }
  }

  Future<bool> connectToEspHotspot(String ssid, String password) async {
    _updateState(() {
      isConfiguringDevice = true;
      configurationError = null;
    });

    try {
      debugPrint("DashboardService: Connecting to Hotspot $ssid...");
      bool connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: password.isEmpty ? NetworkSecurity.NONE : NetworkSecurity.WPA,
        joinOnce: true,
        withInternet: false,
      ).timeout(const Duration(seconds: 25));

      if (!connected) throw "Could not connect to $ssid.";

      // Force WiFi usage for local requests (Fixes 404/Mobile data issues)
      await WiFiForIoTPlugin.forceWifiUsage(true);
      
      await Future.delayed(const Duration(seconds: 4));
      _updateState(() => isConfiguringDevice = false);
      return true;
    } catch (e) {
      _updateState(() {
        configurationError = "Connection failed: $e";
        isConfiguringDevice = false;
      });
      return false;
    }
  }

  Future<bool> sendWifiCredentials(String homeSSID, String homePassword) async {
    _updateState(() {
      isConfiguringDevice = true;
      configurationError = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw "User not logged in.";
      
      final email = user.email ?? "";
      final uid = user.uid;
      
      debugPrint("DashboardService: Sending data to 192.168.4.1...");
      
      // Ensure we stay on WiFi for this request
      await WiFiForIoTPlugin.forceWifiUsage(true);

      final response = await http.post(
        Uri.parse('http://192.168.4.1/config'),
        body: {
          'ssid': homeSSID, 
          'password': homePassword, 
          'email': email,
          'uid': uid,
        },
      ).timeout(const Duration(seconds: 15));

      // Release WiFi lock after request
      await WiFiForIoTPlugin.forceWifiUsage(false);

      if (response.statusCode == 200) {
        _updateState(() => isConfiguringDevice = false);
        return true;
      } else {
        throw "ESP32 Rejected Request (Status: ${response.statusCode})";
      }
    } catch (e) {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      _updateState(() {
        configurationError = "Setup failed: $e. Check connection to device.";
        isConfiguringDevice = false;
      });
      return false;
    }
  }

  // --- Normal Dashboard Logic ---
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
    _moistureTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await PlantService().fetchMoistureData();
      notifyListeners();
    });
  }

  Future<bool> checkEspConnection() async {
    if (_isDisposed) return false;
    try {
      final statusMap = await _esp32Service.getSystemStatus().timeout(const Duration(seconds: 5));
      bool isConnected = statusMap?['status'] == 'ok';

      _updateState(() {
        connectionStatus = isConnected ? DashboardStrings.systemOnline : DashboardStrings.disconnected;
        if (isConnected) {
          mainMotor = statusMap!['mainMotor'] == 'on';
          autoMode = statusMap['autoMode'] == true;
          
          _dataManager.mainMotorOn = mainMotor;
          _dataManager.isSystemAutoMode = autoMode;

          if (statusMap.containsKey('activeMotorsList')) {
            List<dynamic> activeList = statusMap['activeMotorsList'];
            for (var plant in _dataManager.plants) {
              plant.isMotorOn = activeList.contains(plant.id) || activeList.contains(plant.id.toString());
            }
          }
          
          try {
            PlantService().notifyListeners(); // Force Plant Control Screen to refresh UI
          } catch (_) {}
        }
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
      // Act as Master Switch: Toggle ALL motors on/off
      bool success = await _esp32Service.toggleAllMotors(value).timeout(const Duration(seconds: 5));
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
      bool success = await _esp32Service.toggleAllMotors(value).timeout(const Duration(seconds: 5));
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

  DataManager get dataManager => _dataManager;
  bool get isIrrigationRunning => _irrigationTimer?.isActive ?? false;
  Stream<List<ConnectivityResult>> get connectivityStream => Connectivity().onConnectivityChanged;
}
