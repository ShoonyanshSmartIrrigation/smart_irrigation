import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../services/dashboard_service.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabRequested;
  const DashboardScreen({super.key, this.onTabRequested});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  @override
  void initState() {
    super.initState();
    _service.onIrrigationComplete = _playAlarm;
    _service.init().then((_) {
      if (!_service.isDeviceConfigured) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDeviceSetupSheet();
        });
      }
    });
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _showDeviceSetupSheet() {
    int setupStep = 0; // 0: Select Hotspot, 1: Enter Credentials, 2: Success
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    _service.startWifiScan();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ListenableBuilder(
          listenable: _service,
          builder: (context, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return WillPopScope(
                  onWillPop: () async => true,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 20,
                      left: 24,
                      right: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 25),
                        if (setupStep == 0) ...[
                          const Text(
                            "Setup Your Device",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Select your ESP32 hotspot to begin",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                          const SizedBox(height: 20),
                          if (_service.isConfiguringDevice && _service.scannedNetworks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(color: AppColors.primary),
                                  SizedBox(height: 12),
                                  Text("Searching for device...", style: TextStyle(fontSize: 14, color: AppColors.grey)),
                                ],
                              ),
                            )
                          else if (_service.configurationError != null && _service.scannedNetworks.isEmpty)
                            Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                const SizedBox(height: 10),
                                Text(_service.configurationError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () => _service.startWifiScan(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Retry Scan"),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Devices Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                                      onPressed: () => _service.startWifiScan(),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 250,
                                  child: ListView.builder(
                                    itemCount: _service.scannedNetworks.length,
                                    itemBuilder: (context, index) {
                                      final network = _service.scannedNetworks[index];
                                      final ssid = network.ssid;
                                      final isEsp = ssid.toUpperCase().contains("ESP32");
                                      
                                      return Card(
                                        elevation: 0,
                                        color: isEsp ? AppColors.primary.withOpacity(0.05) : Colors.grey[50],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: isEsp ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
                                        ),
                                        child: ListTile(
                                          leading: Icon(Icons.wifi, color: isEsp ? AppColors.primary : Colors.grey),
                                          title: Text(ssid.isEmpty ? "[Hidden]" : ssid, style: TextStyle(fontWeight: isEsp ? FontWeight.bold : FontWeight.normal)),
                                          subtitle: isEsp ? const Text("Tap to configure", style: TextStyle(color: AppColors.primary, fontSize: 11)) : null,
                                          trailing: const Icon(Icons.chevron_right, size: 20),
                                          onTap: () async {
                                            final hotspotPwdController = TextEditingController(text: "12345678");
                                            final bool? shouldConnect = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("Connect to $ssid"),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text("Enter the password for the device's hotspot:"),
                                                    const SizedBox(height: 15),
                                                    TextField(
                                                      controller: hotspotPwdController,
                                                      decoration: InputDecoration(
                                                        labelText: "Hotspot Password",
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                      obscureText: true,
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                                    child: const Text("CONNECT"),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (shouldConnect == true) {
                                              bool connected = await _service.connectToEspHotspot(ssid, hotspotPwdController.text);
                                              if (connected) {
                                                setModalState(() {
                                                  setupStep = 1;
                                                });
                                              }
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                _service.setDeviceConfigured(true);
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                "Skip for now",
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ] else if (setupStep == 1) ...[
                          const Text(
                            "WiFi Configuration",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Enter your Home WiFi details for the device",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                          const SizedBox(height: 25),
                          TextField(
                            controller: ssidController,
                            decoration: InputDecoration(
                              labelText: "Home WiFi Name (SSID)",
                              prefixIcon: const Icon(Icons.wifi),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Home WiFi Password",
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                            ),
                          ),
                          if (_service.configurationError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 15),
                              child: Text(_service.configurationError!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
                            ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _service.isConfiguringDevice 
                                ? null 
                                : () async {
                                    bool success = await _service.sendWifiCredentials(
                                      ssidController.text.trim(),
                                      passwordController.text.trim(),
                                    );
                                    if (success) {
                                      setModalState(() => setupStep = 2);
                                    }
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              child: _service.isConfiguringDevice 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("SEND TO DEVICE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => setModalState(() => setupStep = 0),
                            child: const Text("Back", style: TextStyle(color: AppColors.grey)),
                          ),
                        ] else if (setupStep == 2) ...[
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                          const SizedBox(height: 20),
                          const Text(
                            "Setup Complete!",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Your ESP32 is connecting to your WiFi. It will appear online in a moment.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.grey),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                _service.setDeviceConfigured(true);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              child: const Text("FINISH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTimerPicker() {
    int tempMinutes = _service.selectedMinutes;
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: tempMinutes - 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 30),
                  const Text("Select Duration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Text("How long should irrigation run?", style: TextStyle(fontSize: 14, color: AppColors.grey)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
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
                                    color: isSelected ? AppColors.primary : AppColors.grey.withOpacity(0.4),
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
                          _service.setTimerDuration(tempMinutes);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
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
                  const SizedBox(height: 30),
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

  String _formatDisplayName(String name) {
    if (name.isEmpty) return "User";
    String formatted = name[0].toUpperCase() + name.substring(1);
    return formatted.length > 8 ? "${formatted.substring(0, 8)}.." : formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          _service.loadUserData();
          await _service.checkEspConnection();
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
    String displayName = _formatDisplayName(_service.userName);
    return BuildHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "WELCOME BACK",
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                ),
              ),
              _buildConnectionBadge(),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    bool online = _service.connectionStatus == "SYSTEM ONLINE";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? Colors.greenAccent : Colors.redAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (online ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _service.connectionStatus,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
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
            "${_service.dataManager.avgMoisture}%",
            Icons.water_drop_rounded,
            AppColors.dashboardMoistureBg,
            AppColors.dashboardMoistureIcon,
            showProgress: true,
            progressValue: _service.dataManager.avgMoisture / 100,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildInfoCard(
            "HARDWARE",
            "${_service.dataManager.activeMotors}/${_service.dataManager.totalMotors}",
            Icons.developer_board,
            AppColors.dashboardHardwareBg,
            AppColors.dashboardHardwareIcon,
            subTitle: "Active Motors",
            onTap: () => widget.onTabRequested?.call(1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color bgColor, Color iconColor, {bool showProgress = false, double progressValue = 0, String? subTitle, VoidCallback? onTap}) {
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
              Text(title, style: const TextStyle(color: AppColors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value.split('/').first, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (value.contains('/')) ...[
                Text("/${value.split('/').last}", style: const TextStyle(fontSize: 18, color: AppColors.grey, fontWeight: FontWeight.w500)),
              ] else if (value.contains('%')) ...[
                 const Text("%", style: TextStyle(fontSize: 18, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          if (subTitle != null) Text(subTitle, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
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
    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }

  Widget _buildMainControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_service.mainPumpError || _service.autoModeError) ? Colors.redAccent : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_service.mainPumpError || _service.autoModeError) ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            "On All Motor",
            _service.mainMotor, 
            _service.mainPumpError ? Icons.wifi_off_rounded : Icons.power_settings_new_rounded, 
            (val) => _service.toggleMainPump(val),
            _service.mainPumpError ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
            _service.mainPumpError ? Colors.red : Colors.green,
            isError: _service.mainPumpError,
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1, color: AppColors.dashboardDivider)),
          _buildToggleRow(
            "Automatic Mode", 
            _service.autoMode, 
            _service.autoModeError ? Icons.wifi_off_rounded : Icons.auto_awesome_rounded, 
            (val) => _service.toggleAllMotors(val),
            _service.autoModeError ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
            _service.autoModeError ? Colors.red : Colors.blue,
            isError: _service.autoModeError,
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
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: Colors.grey[300],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    bool isRunning = _service.isIrrigationRunning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.dashboardTimerCardBg, borderRadius: BorderRadius.circular(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimerHeader(isRunning),
          _buildTimerDisplay(isRunning),
          const SizedBox(height: 10),
          _buildTimerControls(isRunning),
        ],
      ),
    );
  }

  Widget _buildTimerHeader(bool isRunning) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("NEXT CYCLE", style: TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Row(
              children: [
                const Text("Irrigation Timer", style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        Icon(Icons.timer_outlined, color: AppColors.white.withValues(alpha: 0.2), size: 32),
      ],
    );
  }

  Widget _buildTimerDisplay(bool isRunning) {
    return GestureDetector(
      onTap: isRunning ? null : _showTimerPicker,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(_service.getTimerText(), style: const TextStyle(color: AppColors.white, fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(width: 8),
            const Text("min", style: TextStyle(color: AppColors.grey, fontSize: 24, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControls(bool isRunning) {
    return Row(
      children: [
        Expanded(
          child: _timerButton(isRunning ? "RUNNING" : "START", isRunning ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary, isRunning ? () {} : () => _service.toggleAllMotors(true)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timerButton("STOP", AppColors.dashboardStopButtonBg, () {
            _service.toggleAllMotors(false);
            FlutterRingtonePlayer().stop();
          }, textColor: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _timerButton(String label, Color color, VoidCallback onTap, {Color textColor = AppColors.white}) {
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
    String iconUrl = "https://openweathermap.org/img/wn/${_service.weatherIcon}@2x.png";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WEATHER", style: TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(_service.weatherCondition, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(_service.weatherTemp, style: const TextStyle(color: AppColors.grey, fontSize: 14)),
            ],
          ),
          Image.network(iconUrl, width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.wb_sunny_rounded, color: Colors.orange[400], size: 40)),
        ],
      ),
    );
  }
}
