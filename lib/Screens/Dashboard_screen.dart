import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../data_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DataManager dataManager = DataManager();
  bool mainMotor = false;
  bool autoMode = false;
  String connectionStatus = "Disconnected";
  String userName = "User";

  Timer? moistureTimer;
  Timer? irrigationTimer;
  Timer? connectionCheckTimer;
  int timerSeconds = 0;
  StreamSubscription? connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    startMoistureSimulation();
    _setupConnectivityListener();
    _startPeriodicConnectionCheck();
  }

  void _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        userName = prefs.getString('userName') ?? "Farmer James";
      });
    }
  }

  void _setupConnectivityListener() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        if (mounted) {
          setState(() {
            connectionStatus = "No Network";
          });
        }
      } else {
        _checkEspConnection();
      }
    });
  }

  void _startPeriodicConnectionCheck() {
    connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkEspConnection();
    });
  }

  Future<void> _checkEspConnection() async {
    bool isConnected = await dataManager.checkConnection();
    if (mounted) {
      setState(() {
        connectionStatus = isConnected ? "SYSTEM ONLINE" : "DISCONNECTED";
      });
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void startMoistureSimulation() {
    moistureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          dataManager.simulateMoisture();
        });
      }
    });
  }

  void startTimer() {
    setState(() => timerSeconds = 60); // Set to 1 minute (60 seconds)
    irrigationTimer?.cancel();
    irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        if (mounted) setState(() => timerSeconds--);
      } else {
        timer.cancel();
        _playAlarm();
      }
    });
  }

  void _playAlarm() {
    // Try playing a basic notification sound if alarm fails
    try {
      FlutterRingtonePlayer().play(
        fromAsset: "assets/alarm.mp3", // Fallback to asset if you have one
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (e) {
      // If the above fails, try the simplest method
      FlutterRingtonePlayer().playNotification();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Irrigation Complete"),
        content: const Text("The irrigation timer has finished."),
        actions: [
          TextButton(
            onPressed: () {
              FlutterRingtonePlayer().stop();
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String getTimerText() {
    int min = timerSeconds ~/ 60;
    int sec = timerSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  Future<void> _toggleMainPump(bool value) async {
    bool success = await dataManager.toggleMainMotor(value);
    
    if (mounted) {
      if (success) {
        setState(() {
          mainMotor = value;
        });
      } else {
        setState(() {
          mainMotor = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: No response from ESP32. Check IP and Wi-Fi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    moistureTimer?.cancel();
    irrigationTimer?.cancel();
    connectionCheckTimer?.cancel();
    connectivitySubscription?.cancel();
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUserData();
          await _checkEspConnection();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeader(),
                  Positioned(
                    bottom: -100,
                    left: 20,
                    right: 20,
                    child: _buildStatGrid(),
                  ),
                ],
              ),
              const SizedBox(height: 120), // Space for the overlapping stat grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildMainControls(),
                    const SizedBox(height: 20),
                    _buildTimerCard(),
                    const SizedBox(height: 20),
                    _buildWeatherCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 30, right: 30, bottom: 70),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15,
            offset: Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WELCOME BACK",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            userName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  connectionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: connectionStatus == "SYSTEM ONLINE" ? Colors.greenAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (connectionStatus == "SYSTEM ONLINE" ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            "MOISTURE",
            "${dataManager.avgMoisture}%",
            Icons.water_drop_rounded,
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
            showProgress: true,
            progressValue: dataManager.avgMoisture / 100,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildInfoCard(
            "HARDWARE",
            "${dataManager.activeMotors}/${dataManager.totalMotors}",
            Icons.developer_board,
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
            subTitle: "Active Motors",
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color bgColor, Color iconColor, {bool showProgress = false, double progressValue = 0, String? subTitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value.split('/').first, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (value.contains('/')) ...[
                Text("/${value.split('/').last}", style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
              ] else if (value.contains('%')) ...[
                 const Text("%", style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          if (subTitle != null) Text(subTitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[200],
                color: Colors.blueAccent,
                minHeight: 6,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            "Main Water Pump", 
            mainMotor, 
            Icons.power_settings_new_rounded, 
            (val) => _toggleMainPump(val),
            Colors.green.withOpacity(0.1),
            Colors.green,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1),
          ),
          _buildToggleRow(
            "Automatic Mode", 
            autoMode, 
            Icons.auto_awesome_rounded, 
            (val) => setState(() => autoMode = val),
            Colors.blue.withOpacity(0.1),
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, IconData icon, Function(bool) onChanged, Color iconBg, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Switch(
          value: value,
          activeColor: Colors.white,
          activeTrackColor: const Color(0xFF2E7D32),
          inactiveTrackColor: Colors.grey[300],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("NEXT CYCLE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text("Irrigation Timer", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.timer_outlined, color: Colors.white.withOpacity(0.2), size: 32),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(getTimerText(), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(width: 8),
                const Text("min", style: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _timerButton("START", const Color(0xFF2E7D32), startTimer),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _timerButton("STOP", const Color(0xFF332020), () {
                  irrigationTimer?.cancel();
                  FlutterRingtonePlayer().stop();
                  setState(() => timerSeconds = 0);
                }, textColor: Colors.redAccent),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _timerButton(String label, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_cloudy_rounded, color: Color(0xFF1976D2), size: 40),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Partly Cloudy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Precipitation expected: 12%", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("24°C", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              Text("SOIL TEMP", style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
