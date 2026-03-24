import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data_manager.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
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
    setState(() {
      userName = prefs.getString('userName') ?? "User";
    });
  }

  void _setupConnectivityListener() {
    connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() {
          connectionStatus = "No Network";
        });
      } else {
        _checkEspConnection();
      }
    });
  }

  void _startPeriodicConnectionCheck() {
    connectionCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkEspConnection();
    });
  }

  Future<void> _checkEspConnection() async {
    bool isConnected = await dataManager.checkConnection();
    if (mounted) {
      setState(() {
        connectionStatus = isConnected ? "System Online" : "Disconnected";
      });
    }
  }

  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void startMoistureSimulation() {
    moistureTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      setState(() {
        dataManager.simulateMoisture();
      });
    });
  }

  void startTimer() {
    setState(() => timerSeconds = 300);
    irrigationTimer?.cancel();
    irrigationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        setState(() => timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String getTimerText() {
    int min = timerSeconds ~/ 60;
    int sec = timerSeconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  Future<void> _toggleMainPump(bool value) async {
    bool success = await dataManager.toggleMainMotor(value);
    
    if (success) {
      setState(() {
        mainMotor = value;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pump turned ${value ? 'ON' : 'OFF'}"),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to control pump. Check connection."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    moistureTimer?.cancel();
    irrigationTimer?.cancel();
    connectionCheckTimer?.cancel();
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F7F5),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadUserData();
          await _checkEspConnection();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildStatGrid(),
                    SizedBox(height: 20),
                    _buildMainControls(),
                    SizedBox(height: 20),
                    _buildTimerCard(),
                    SizedBox(height: 20),
                    _buildQuickActions(),
                    SizedBox(height: 30),
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
      padding: EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome Back,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(userName, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              CircleAvatar(
                backgroundColor: Colors.white24,
                child: IconButton(
                  icon: Icon(Icons.logout, color: Colors.white, size: 20),
                  onPressed: _logout,
                ),
              )
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  connectionStatus == "System Online" ? Icons.wifi : Icons.wifi_off, 
                  color: connectionStatus == "System Online" ? Colors.greenAccent : Colors.redAccent, 
                  size: 16
                ),
                SizedBox(width: 8),
                Text(connectionStatus, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
            "Soil Moisture",
            "${dataManager.avgMoisture}%",
            Icons.water_drop,
            Colors.blueAccent,
            progress: dataManager.avgMoisture / 100,
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildInfoCard(
            "Active Motors",
            "${dataManager.activeMotors} / ${dataManager.totalMotors}",
            Icons.settings_input_component,
            Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color, {double? progress}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 15),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(title, style: TextStyle(color: Colors.black54, fontSize: 14)),
          if (progress != null) ...[
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              borderRadius: BorderRadius.circular(10),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildMainControls() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildToggleRow("Main Water Pump", mainMotor, Icons.power_settings_new, (val) {
            _toggleMainPump(val);
          }),
          Divider(indent: 50),
          _buildToggleRow("Automatic Mode", autoMode, Icons.auto_fix_high, (val) {
            setState(() => autoMode = val);
          }),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, IconData icon, Function(bool) onChanged) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: value ? Color(0xFFE8F5E9) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: value ? Color(0xFF2E7D32) : Colors.grey),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: Color(0xFF2E7D32),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimerCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text("Irrigation Timer", style: TextStyle(color: Colors.white70, fontSize: 16)),
          SizedBox(height: 10),
          Text(getTimerText(), style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 2)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timerButton("START", Colors.green, startTimer),
              SizedBox(width: 15),
              _timerButton("STOP", Colors.redAccent, () {
                irrigationTimer?.cancel();
                setState(() => timerSeconds = 0);
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _timerButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _quickActionIcon(Icons.build_circle_outlined, "Maint.", '/maintenance'),
        _quickActionIcon(Icons.history, "Logs", null),
        _quickActionIcon(Icons.grass, "Plants", '/plant'),
        _quickActionIcon(Icons.settings_outlined, "Config", '/settings'),
      ],
    );
  }

  Widget _quickActionIcon(IconData icon, String label, String? route) {
    return GestureDetector(
      onTap: () async {
        if (route != null) {
          await Navigator.pushNamed(context, route);
          setState(() {}); // Refresh data when returning from other screens
          _checkEspConnection(); // Refresh connection status
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
