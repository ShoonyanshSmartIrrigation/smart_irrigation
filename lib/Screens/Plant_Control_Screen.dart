import 'package:flutter/material.dart';
import '../services/plant_service.dart';
import '../data_manager.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

class PlantControlScreen extends StatefulWidget {
  const PlantControlScreen({super.key});
  @override
  State<PlantControlScreen> createState() => _PlantControlScreenState();
}

class _PlantControlScreenState extends State<PlantControlScreen> {
  final PlantService _service = PlantService();

  @override
  void initState() {
    super.initState();
    _service.init();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    // ✅ Do NOT call _service.dispose() here because PlantService is a Singleton.
    // Disposing it here would prevent it from being used again when the screen is rebuilt.
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final plants = _service.getPlants();
    final totalMotors = plants.length;
    final activeMotors = _service.getActiveMotors();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        heroTag: 'plant_settings_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.pushNamed(context, '/settings'),
        child: const Icon(Icons.settings, color: AppColors.white),
      ),
      body: Column(
        children: [
          _buildStatsHeader(totalMotors, activeMotors),
          const SizedBox(height: 50),
          Expanded(
            child: GridView.builder(
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(int totalMotors, int activeMotors) {
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
                    style: TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  if (_service.isSyncing || _service.isTogglingAll)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem("TOTAL PLANTS", totalMotors.toString(), Icons.grass_rounded),
                      Container(width: 1, height: 30, color: AppColors.plantControlDivider),
                      _statItem("ACTIVE", activeMotors.toString(), Icons.water_drop_rounded),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: AppColors.plantControlLabelGrey, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlantCard(Plant plant) {
    bool hasError = _service.plantConnectionErrors[plant.id] ?? false;
    Color moistureColor = plant.moistureLevel < 30 
        ? AppColors.plantControlMoistureLow 
        : (plant.moistureLevel < 60 ? AppColors.plantControlMoistureMedium : AppColors.plantControlMoistureHigh);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError ? AppColors.plantControlError : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError ? AppColors.plantControlError.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: hasError
                      ? AppColors.plantControlError.withOpacity(0.1)
                      : (plant.isMotorOn ? AppColors.plantControlIconBg : AppColors.background),
                  radius: 18,
                  child: Icon(
                    hasError ? Icons.wifi_off_rounded : Icons.grass,
                    color: hasError ? AppColors.plantControlError : (plant.isMotorOn ? AppColors.primary : AppColors.grey),
                    size: 18,
                  ),
                ),
                Text("#${plant.id}", style: const TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                Text(plant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Moisture: ${plant.moistureLevel}%", style: TextStyle(color: moistureColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                Switch.adaptive(
                  value: plant.isMotorOn,
                  activeColor: AppColors.primary,
                  onChanged: _service.isTogglingAll ? null : (_) => _service.togglePlantMotor(plant),
                ),
                Text(
                  hasError ? "OFFLINE" : (plant.isMotorOn ? "ACTIVE" : "INACTIVE"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: hasError ? AppColors.plantControlError : (plant.isMotorOn ? AppColors.plantControlActive : AppColors.plantControlInactive),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
