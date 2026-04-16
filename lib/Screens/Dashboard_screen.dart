import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:go_router/go_router.dart';
import '../services/dashboard_service.dart';
import '../widgets/build_header.dart';
import '../core/theme/app_colors.dart';
import '../services/weather_service.dart';

//-------------------------------------------------------- DashboardScreen Class ----------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabRequested;
  const DashboardScreen({super.key, this.onTabRequested});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

//-------------------------------------------------------- _DashboardScreenState Class ----------------------------------------------------------
class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _service = DashboardService();

  String? city;
  Map<String, dynamic>? weather;
  bool loading = false;

  Future<void> updateWeather(StateSetter setState, String name, {double? lat, double? lon}) async {
    setState(() => loading = true);
    Map<String, dynamic>? data;
    if (lat != null && lon != null) {
      data = await WeatherService.fetchWeatherByCoords(lat, lon);
    } else {
      data = await WeatherService.fetchWeather(name);
    }
    
    if (data != null) {
      weather = data;
    }
    loading = false;
    setState(() {});
  }

  Future<void> loadCity() async {
    final info = await CityService.getCityInfo();
    final savedName = info['name'];
    final lat = info['lat'];
    final lon = info['lon'];
    
    if (savedName != null) {
      city = savedName;
      await updateWeather(setState, savedName, lat: lat, lon: lon);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _service.onIrrigationComplete = _playAlarm;
    _service.init();
    _service.addListener(_onServiceUpdate);
    loadCity();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _showTimerPicker() {
    int tempMinutes = _service.selectedMinutes;
    final FixedExtentScrollController scrollController =
    FixedExtentScrollController(initialItem: tempMinutes - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Select Duration",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "How long should irrigation run?",
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppColors.grey),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 60,
                          width: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              width: 1,
                            ),
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
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? Colors.white24 : AppColors.grey.withValues(alpha: 0.4)),
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
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "CONFIRM DURATION",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
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
        content: const Text(
          "The irrigation timer has finished and the motor has been turned off.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              FlutterRingtonePlayer().stop();
              context.pop();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : AppColors.background,
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
                    weatherHomeFunction(),
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
    bool online = _service.connectionStatus == DashboardStrings.systemOnline;
    bool noNetwork = _service.connectionStatus == DashboardStrings.noNetwork;
    
    Color statusColor = online ? Colors.greenAccent : (noNetwork ? Colors.orangeAccent : Colors.redAccent);
    String displayStatus = online ? _service.connectionType : _service.connectionStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                displayStatus,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (!online && _service.lastSeenText.isNotEmpty && !noNetwork)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Text(
              "Last seen: ${_service.lastSeenText}",
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
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

  Widget _buildInfoCard(
      String title,
      String value,
      IconData icon,
      Color bgColor,
      Color iconColor, {
        bool showProgress = false,
        double progressValue = 0,
        String? subTitle,
        VoidCallback? onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white24, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.1) : bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.split('/').first,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (value.contains('/')) ...[
                Text(
                  "/${value.split('/').last}",
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (value.contains('%')) ...[
                const Text(
                  "%",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (subTitle != null)
            Text(
              subTitle,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          if (showProgress) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                color: Colors.blueAccent,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: card) : card;
  }

  Widget _buildMainControls() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (_service.mainPumpError || _service.autoModeError)
              ? Colors.redAccent
              : (isDark ? Colors.white24 : Colors.transparent),
          width: (_service.mainPumpError || _service.autoModeError) ? 2 : (isDark ? 1 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: (_service.mainPumpError || _service.autoModeError)
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            "On All Motor",
            _service.mainMotor,
            _service.mainPumpError
                ? Icons.wifi_off_rounded
                : Icons.power_settings_new_rounded,
                (val) => _service.toggleMainPump(val),
            _service.mainPumpError
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.green.withValues(alpha: 0.1),
            _service.mainPumpError ? Colors.red : Colors.green,
            isError: _service.mainPumpError,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.dashboardDivider),
          ),
          _buildToggleRow(
            "Automatic Mode",
            _service.autoMode,
            _service.autoModeError
                ? Icons.wifi_off_rounded
                : Icons.auto_awesome_rounded,
                (val) => _service.toggleAllMotors(val),
            _service.autoModeError
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            _service.autoModeError ? Colors.red : Colors.blue,
            isError: _service.autoModeError,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.dashboardDivider),
          ),
          _buildToggleRow(
            "Smart Auto(All Plants)",
            _service.isAllPlantsAutoMode,
            Icons.psychology_rounded,
            (val) => _service.toggleAllPlantsAutoMode(val),
            Colors.purple.withValues(alpha: 0.1),
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      String title,
      bool value,
      IconData icon,
      Function(bool) onChanged,
      Color iconBg,
      Color iconColor, {
        bool isError = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          isError ? "$title (OFFLINE)" : title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isError ? Colors.red : (isDark ? Colors.white : Colors.black87),
          ),
        ),
        trailing: Switch(
          value: value,
          activeThumbColor: AppColors.white,
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: isDark ? Colors.white10 : Colors.grey[300],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    bool isRunning = _service.isIrrigationRunning;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dashboardTimerCardBg : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(30),
        border: isDark ? Border.all(color: Colors.white24, width: 1) : null,
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimerHeader(isRunning, isDark),
          _buildTimerDisplay(isRunning, isDark),
          const SizedBox(height: 10),
          _buildTimerControls(isRunning, isDark),
        ],
      ),
    );
  }

  Widget _buildTimerHeader(bool isRunning, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NEXT CYCLE",
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Row(
              children: [
                Text(
                  "Irrigation Timer",
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.dashboardTextDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Visibility(
                  visible: !isRunning,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_calendar_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    onPressed: _showTimerPicker,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ],
        ),
        Icon(
          Icons.timer_outlined,
          color: (isDark ? AppColors.white : AppColors.dashboardTextDark).withValues(alpha: 0.2),
          size: 32,
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(bool isRunning, bool isDark) {
    return GestureDetector(
      onTap: isRunning ? null : _showTimerPicker,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _service.getTimerText(),
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.dashboardTextDark,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "min",
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerControls(bool isRunning, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _timerButton(
            isRunning ? "RUNNING" : "START",
            isRunning
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary,
            isRunning ? () {} : () => _service.toggleAllMotors(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timerButton("STOP", isDark ? AppColors.dashboardStopButtonBg : Colors.red.withValues(alpha: 0.08), () {
            _service.toggleAllMotors(false);
            FlutterRingtonePlayer().stop();
          }, textColor: Colors.redAccent),
        ),
      ],
    );
  }

  Widget _timerButton(
      String label,
      Color color,
      VoidCallback onTap, {
        Color textColor = AppColors.white,
      }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget weatherHomeFunction() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    void openEditDialog(BuildContext context, StateSetter setState) {
      final controller = TextEditingController(text: city ?? "");
      List<Map<String, dynamic>> suggestions = [];
      bool isSearching = false;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Set City"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter City",
                    suffixIcon: isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (value) async {
                    if (value.length >= 2) {
                      setDialogState(() => isSearching = true);
                      final results = await WeatherService.fetchCitySuggestions(value);
                      setDialogState(() {
                        suggestions = results;
                        isSearching = false;
                      });
                    } else {
                      setDialogState(() => suggestions = []);
                    }
                  },
                ),
                if (suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final s = suggestions[index];
                        return ListTile(
                          title: Text("${s['name']}, ${s['country']}"),
                          subtitle: s['state'].isNotEmpty ? Text(s['state']) : null,
                          onTap: () async {
                            final cityName = s['name'];
                            final stateName = s['state'];
                            final lat = s['lat'];
                            final lon = s['lon'];
                            
                            context.pop();
                            
                            String storageName = stateName.isNotEmpty ? "$cityName, $stateName" : cityName;
                            await CityService.saveCity(storageName, lat: lat, lon: lon);
                            city = storageName;
                            
                            setState(() {});
                            await updateWeather(setState, cityName, lat: lat, lon: lon);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ),
      );
    }

    IconData getIcon(String? condition) {
      switch (condition?.toLowerCase()) {
        case 'clear': return Icons.wb_sunny_rounded;
        case 'clouds': return Icons.cloud_rounded;
        case 'rain':
        case 'drizzle': return Icons.water_drop_rounded;
        case 'snow': return Icons.ac_unit_rounded;
        case 'thunderstorm': return Icons.flash_on_rounded;
        default: return Icons.cloud_queue_rounded;
      }
    }

    Color getColor(String? condition) {
      switch (condition?.toLowerCase()) {
        case 'clear': return Colors.orangeAccent;
        case 'clouds': return const Color.fromARGB(255, 105, 143, 162);
        case 'rain':
        case 'drizzle': return AppColors.dashboardMoistureIcon;
        case 'snow': return Colors.lightBlueAccent;
        case 'thunderstorm': return Colors.deepPurple;
        default: return AppColors.grey;
      }
    }

    Widget detail(IconData icon, String value, String label) {
      return Expanded(
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.dashboardMoistureIcon),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final temp = weather?['main']?['temp'];
        final humidity = weather?['main']?['humidity'];
        final pressure = weather?['main']?['pressure'];
        final feelsLike = weather?['main']?['feels_like'];
        final windSpeed = weather?['wind']?['speed'];
        String? condition;
        String? description;
        if (weather != null && weather!['weather'] != null && weather!['weather'].isNotEmpty) {
          condition = weather!['weather'][0]?['main']?.toString();
          description = weather!['weather'][0]?['description']?.toString();
        }
        description ??= condition ?? "--";

        return SizedBox(
          width: double.infinity,
          child: Center(
            child: Card(
              color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: isDark ? const BorderSide(color: Colors.white24, width: 1) : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: city == null
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: AppColors.plantControlError,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    const Text("No City Selected"),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => openEditDialog(context, setState),
                      child: const Text("Set City"),
                    ),
                  ],
                )
                    : loading
                    ? const CircularProgressIndicator()
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            city ?? "",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => openEditDialog(context, setState),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: () async {
                                final info = await CityService.getCityInfo();
                                await updateWeather(setState, info['name'] ?? "", lat: info['lat'], lon: info['lon']);
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (weather != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Last synced: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                          style: TextStyle(fontSize: 10, color: AppColors.grey.withValues(alpha: 0.6)),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getIcon(condition),
                          size: 40,
                          color: getColor(condition),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              temp != null ? "${(temp as num).round()}°C" : "--",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(description.toUpperCase()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        detail(Icons.water_drop, "${humidity ?? '--'}%", "Humidity"),
                        detail(Icons.air, "${windSpeed ?? '--'} m/s", "Wind"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        detail(Icons.speed, "${pressure ?? '--'} hPa", "Pressure"),
                        detail(Icons.thermostat, feelsLike != null ? "${(feelsLike as num).round()}°C" : "--", "Feels Like"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
