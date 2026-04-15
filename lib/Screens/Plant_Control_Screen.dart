import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/plant_service.dart';
import '../data_manager.dart';
import '../widgets/build_header.dart';
import '../core/theme/app_colors.dart';

//-------------------------------------------------------- PlantControlScreen Class ----------------------------------------------------------
class PlantControlScreen extends StatefulWidget {
  const PlantControlScreen({super.key});
  @override
  State<PlantControlScreen> createState() => _PlantControlScreenState();
}

//-------------------------------------------------------- _PlantControlScreenState Class ----------------------------------------------------------
class _PlantControlScreenState extends State<PlantControlScreen> {
  final PlantService _service = PlantService();

  @override
  //-------------------------------------------------------- Init State ----------------------------------------------------------
  void initState() {
    super.initState();
    _service.init();
    _service.addListener(_onServiceUpdate);
  }

  @override
  //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  //-------------------------------------------------------- Build Method ----------------------------------------------------------
  Widget build(BuildContext context) {
    final plants = _service.getPlants();
    final totalMotors = plants.length;
    final activeMotors = _service.getActiveMotors();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'plant_settings_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => context.go('/settings'),
        child: const Icon(Icons.settings, color: AppColors.white),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildStatsHeader(totalMotors, activeMotors),
            const SizedBox(height: 50),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: totalMotors,
              itemBuilder: (context, index) {
                final plant = plants[index];
                return _buildPlantCard(plant);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(int totalMotors, int activeMotors) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BuildHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Plant Control",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_service.isSyncing || _service.isTogglingAll)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              const Text(
                "Manage your individual plants",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -45,
          left: 20,
          right: 20,
          child: Card(
            elevation: 8,
            shadowColor: Colors.black12,
            color: isDark
                ? Theme.of(context).cardColor
                : AppColors.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: isDark
                  ? const BorderSide(color: Colors.white24, width: 1)
                  : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem(
                        "TOTAL PLANTS",
                        totalMotors.toString(),
                        Icons.grass_rounded,
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.plantControlDivider,
                      ),
                      _statItem(
                        "ACTIVE",
                        activeMotors.toString(),
                        Icons.water_drop_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.plantControlIconGrey, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.plantControlLabelGrey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlantCard(Plant plant) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool hasError = _service.plantConnectionErrors[plant.id] ?? false;
    Color moistureColor = plant.moistureLevel < 30
        ? AppColors.plantControlMoistureLow
        : (plant.moistureLevel < 60
              ? AppColors.plantControlMoistureMedium
              : AppColors.plantControlMoistureHigh);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError
              ? AppColors.plantControlError
              : (isDark ? Colors.white24 : Colors.transparent),
          width: hasError ? 2 : (isDark ? 1 : 0),
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? AppColors.plantControlError.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: hasError
                      ? AppColors.plantControlError.withValues(alpha: 0.1)
                      : (plant.isMotorOn
                            ? AppColors.plantControlIconBg
                            : (isDark ? Colors.white10 : AppColors.background)),
                  radius: 18,
                  child: Icon(
                    hasError ? Icons.wifi_off_rounded : Icons.grass,
                    color: hasError
                        ? AppColors.plantControlError
                        : (plant.isMotorOn
                              ? AppColors.primary
                              : (isDark ? Colors.white54 : AppColors.grey)),
                    size: 18,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "#${plant.id}",
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showPlantSettingsSheet(plant),
                      child: const Icon(
                        Icons.settings,
                        size: 16,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  plant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Moisture: ${plant.moistureLevel}%",
                  style: TextStyle(
                    color: moistureColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (plant.isAutoMode)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      "AUTO MODE",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              children: [
                Switch.adaptive(
                  value: plant.isMotorOn,
                  activeTrackColor: AppColors.primary,
                  onChanged: _service.isTogglingAll || plant.isAutoMode
                      ? null
                      : (_) => _service.togglePlantMotor(plant),
                ),
                Text(
                  hasError
                      ? "OFFLINE"
                      : (plant.isMotorOn ? "ACTIVE" : "INACTIVE"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: hasError
                        ? AppColors.plantControlError
                        : (plant.isMotorOn
                              ? AppColors.plantControlActive
                              : AppColors.plantControlInactive),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantSettingsSheet(Plant plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Settings - ${plant.name}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Auto Mode",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch.adaptive(
                        value: plant.isAutoMode,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          setModalState(() => plant.isAutoMode = val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const Text(
                    "Minimum Moisture (Auto-Start)",
                    style: TextStyle(fontSize: 14),
                  ),
                  Slider(
                    value: plant.minMoistureThreshold.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: "${plant.minMoistureThreshold}%",
                    activeColor: AppColors.plantControlMoistureLow,
                    onChanged: plant.isAutoMode
                        ? (val) {
                            if (val >= plant.maxMoistureThreshold) return;
                            setModalState(
                              () => plant.minMoistureThreshold = val.toInt(),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Maximum Moisture (Auto-Stop)",
                    style: TextStyle(fontSize: 14),
                  ),
                  Slider(
                    value: plant.maxMoistureThreshold.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: "${plant.maxMoistureThreshold}%",
                    activeColor: AppColors.plantControlMoistureHigh,
                    onChanged: plant.isAutoMode
                        ? (val) {
                            if (val <= plant.minMoistureThreshold) return;
                            setModalState(
                              () => plant.maxMoistureThreshold = val.toInt(),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text(
                        "Save",
                        style: TextStyle(color: Colors.white),
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
}
