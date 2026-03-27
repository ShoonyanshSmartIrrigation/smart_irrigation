import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../services/dashboard_service.dart';
import '../Widgets/build_header.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabRequested;
  const DashboardScreen({super.key, this.onTabRequested});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();
  bool mainMotor = false;
  bool autoMode = false;
  String connectionStatus = "Disconnected";
  String userName = "User";
  bool _mainPumpError = false;
  bool _autoModeError = false;

  Timer? moistureTimer;
  Timer? irrigationTimer;
  Timer? connectionCheckTimer;
  int timerSeconds = 60; // Default to 1 minute
  int _selectedMinutes = 1;
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
    String name = await _dashboardService.getUserName();
    if (mounted) {
      setState(() {
        userName = name;
      });
    }
  }

  void _setupConnectivityListener() {
    connectivitySubscription = _dashboardService.connectivityStream.listen((List<ConnectivityResult> results) {
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
    bool isConnected = await _dashboardService.checkEspConnection();
    if (mounted) {
      setState(() {
        connectionStatus = isConnected ? "SYSTEM ONLINE" : "DISCONNECTED";
      });
    }
  }

  void startMoistureSimulation() {
    moistureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _dashboardService.simulateMoisture();
        });
      }
    });
  }

  void startTimer() {
    if (timerSeconds == 0) {
      setState(() => timerSeconds = _selectedMinutes * 60);
    }
    irrigationTimer?.cancel();
    irrigationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds > 0) {
        if (mounted) setState(() => timerSeconds--);
      } else {
        timer.cancel();
        // Check if motor is ON, then turn it OFF
        if (mainMotor) {
          _toggleMainPump(false);
        }
        // If auto mode is on, turn it off
        if (autoMode) {
          _toggleAutoMode(false);
        }
        _playAlarm();
      }
    });
  }

  void _showTimerPicker() {
    int tempMinutes = _selectedMinutes;
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: tempMinutes - 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "Set Irrigation Duration",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select how long you want to irrigate",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  // Quick Selection Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [5, 10, 15, 30, 45, 60].map((mins) {
                        bool isSelected = tempMinutes == mins;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text("$mins min"),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  tempMinutes = mins;
                                  scrollController.animateToItem(
                                    mins - 1,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeOutBack,
                                  );
                                });
                                HapticFeedback.mediumImpact();
                              }
                            },
                            selectedColor: const Color(0xFF2E7D32),
                            backgroundColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey[300]!,
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Wheel Picker
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 55,
                          width: MediaQuery.of(context).size.width * 0.85,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        ListWheelScrollView.useDelegate(
                          controller: scrollController,
                          itemExtent: 55,
                          perspective: 0.006,
                          diameterRatio: 1.4,
                          squeeze: 1.1,
                          physics: const FixedExtentScrollPhysics(),
                          useMagnifier: true,
                          magnification: 1.3,
                          overAndUnderCenterOpacity: 0.4,
                          onSelectedItemChanged: (index) {
                            HapticFeedback.selectionClick();
                            setModalState(() {
                              tempMinutes = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 120,
                            builder: (context, index) {
                              final isSelected = (index + 1) == tempMinutes;
                              return Center(
                                child: Text(
                                  "${index + 1} minutes",
                                  style: TextStyle(
                                    fontSize: isSelected ? 26 : 20,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedMinutes = tempMinutes;
                            if (irrigationTimer == null || !irrigationTimer!.isActive) {
                              timerSeconds = _selectedMinutes * 60;
                            }
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          "CONFIRM DURATION",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _playAlarm() {
    try {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (e) {
      FlutterRingtonePlayer().playNotification();
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Irrigation Complete"),
        content: const Text("The irrigation timer has finished and the motor has been turned off."),
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
    bool success = await _dashboardService.toggleMainPump(value);
    
    if (mounted) {
      if (success) {
        setState(() {
          mainMotor = value;
          _mainPumpError = false;
        });
      } else {
        setState(() {
          mainMotor = false; // Force OFF on failure
          _mainPumpError = true;
        });
        
        // Clear error state after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _mainPumpError = false;
            });
          }
        });
      }
    }
  }

  Future<void> _toggleAutoMode(bool value) async {
    bool success = await _dashboardService.toggleAllMotors(value);
    
    if (mounted) {
      if (success) {
        setState(() {
          autoMode = value;
          _autoModeError = false;
        });
        
        // Start timer if auto mode is turned on
        if (value) {
          startTimer();
        } else {
          // If turned off manually, stop timer
          irrigationTimer?.cancel();
          setState(() => timerSeconds = _selectedMinutes * 60);
        }
      } else {
        setState(() {
          _autoModeError = true;
        });
        
        // Clear error state after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _autoModeError = false;
            });
          }
        });
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

  String _formatDisplayName(String name) {
    if (name.isEmpty) return "User";
    
    // Capitalize first letter and handle rest
    String formatted = name[0].toUpperCase() + name.substring(1);
    
    // Limit to 8 characters (as requested)
    if (formatted.length > 8) {
      return "${formatted.substring(0, 8)}..";
    }
    return formatted;
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
                  _buildHeaderContent(),
                  Positioned(
                    bottom: -90,
                    left: 20,
                    right: 20,
                    child: _buildStatGrid(),
                  ),
                ],
              ),
              const SizedBox(height: 100),
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

  Widget _buildHeaderContent() {
    String displayName = _formatDisplayName(userName);

    return BuildHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WELCOME BACK",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: connectionStatus == "SYSTEM ONLINE" ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (connectionStatus == "SYSTEM ONLINE" ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connectionStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
            "${_dashboardService.dataManager.avgMoisture}%",
            Icons.water_drop_rounded,
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
            showProgress: true,
            progressValue: _dashboardService.dataManager.avgMoisture / 100,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildInfoCard(
            "HARDWARE",
            "${_dashboardService.dataManager.activeMotors}/${_dashboardService.dataManager.totalMotors}",
            Icons.developer_board,
            const Color(0xFFFFF3E0),
            const Color(0xFFE65100),
            subTitle: "Active Motors",
            onTap: () {
              if (widget.onTabRequested != null) {
                widget.onTabRequested!(1); // Index 1 is Zones/PlantControl
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color bgColor, Color iconColor, {bool showProgress = false, double progressValue = 0, String? subTitle, VoidCallback? onTap}) {
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
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

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildMainControls() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_mainPumpError || _autoModeError) ? Colors.redAccent : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_mainPumpError || _autoModeError) ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            "Main Water Pump", 
            mainMotor, 
            _mainPumpError ? Icons.wifi_off_rounded : Icons.power_settings_new_rounded, 
            (val) => _toggleMainPump(val),
            _mainPumpError ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
            _mainPumpError ? Colors.red : Colors.green,
            isError: _mainPumpError,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1),
          ),
          _buildToggleRow(
            "Automatic Mode", 
            autoMode, 
            _autoModeError ? Icons.wifi_off_rounded : Icons.auto_awesome_rounded, 
            (val) => _toggleAutoMode(val),
            _autoModeError ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            _autoModeError ? Colors.red : Colors.blue,
            isError: _autoModeError,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, IconData icon, Function(bool) onChanged, Color iconBg, Color iconColor, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          isError ? "$title (OFFLINE)" : title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isError ? Colors.red : Colors.black87,
          )
        ),
        trailing: Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF2E7D32),
          inactiveTrackColor: Colors.grey[300],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    bool isRunning = irrigationTimer?.isActive ?? false;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NEXT CYCLE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Row(
                    children: [
                      const Text("Irrigation Timer", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Visibility(
                        visible: !isRunning,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: IconButton(
                          icon: const Icon(Icons.edit_calendar_rounded, color: Colors.green, size: 20),
                          onPressed: _showTimerPicker,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.2), size: 32),
            ],
          ),
          GestureDetector(
            onTap: isRunning ? null : _showTimerPicker,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(getTimerText(), style: const TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(width: 8),
                  const Text("min", style: TextStyle(color: Colors.grey, fontSize: 24, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _timerButton(isRunning ? "RUNNING" : "START", isRunning ? const Color(0xFF2E7D32).withValues(alpha: 0.5) : const Color(0xFF2E7D32), isRunning ? () {} : startTimer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timerButton("STOP", const Color(0xFF332020), () {
                  irrigationTimer?.cancel();
                  FlutterRingtonePlayer().stop();
                  setState(() => timerSeconds = _selectedMinutes * 60);
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WEATHER", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 4),
              Text("Mostly Sunny", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("28°C", style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          Icon(Icons.wb_sunny_rounded, color: Colors.orange[400], size: 40),
        ],
      ),
    );
  }
}
