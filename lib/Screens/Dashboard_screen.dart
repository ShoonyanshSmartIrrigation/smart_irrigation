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
    _service.init();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    // ✅ Do NOT call _service.dispose() here because DashboardService is a Singleton.
    // Disposing it here would prevent it from being used again when the screen is rebuilt.
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
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
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: AppColors.white,
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
                      color: AppColors.dashboardTextDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select how long you want to irrigate",
                    style: TextStyle(color: AppColors.grey, fontSize: 14),
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
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.white : Colors.black87,
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
                            color: AppColors.dashboardWheelPickerBg.withValues(alpha: 0.6),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
            "Main Water Pump", 
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
                if (!isRunning) IconButton(
                  icon: const Icon(Icons.edit_calendar_rounded, color: Colors.green, size: 20),
                  onPressed: _showTimerPicker,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
          child: _timerButton(isRunning ? "RUNNING" : "START", isRunning ? AppColors.primary.withValues(alpha: 0.5) : AppColors.primary, isRunning ? () {} : _service.startIrrigationTimer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timerButton("STOP", AppColors.dashboardStopButtonBg, () {
            _service.stopIrrigationTimer();
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("WEATHER", style: TextStyle(color: AppColors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 4),
              Text("Mostly Sunny", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text("28°C", style: TextStyle(color: AppColors.grey, fontSize: 14)),
            ],
          ),
          Icon(Icons.wb_sunny_rounded, color: Colors.orange[400], size: 40),
        ],
      ),
    );
  }
}
