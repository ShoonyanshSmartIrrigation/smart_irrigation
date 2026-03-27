import 'dart:async';
import 'package:flutter/material.dart';
import '../services/plant_service.dart';
import '../data_manager.dart';
import '../Widgets/build_header.dart';
import '../Routes/app_Routes.dart';

class PlantControlScreen extends StatefulWidget {
  const PlantControlScreen({super.key});
  @override
  State<PlantControlScreen> createState() => _PlantControlScreenState();
}

class _PlantControlScreenState extends State<PlantControlScreen> {
  final PlantService _plantService = PlantService();
  Timer? syncTimer;
  bool isSyncing = false;
  bool isTogglingAll = false;
  bool _allMotorsError = false;
  bool _isMasterOn = false;

  // Track which plants have connection errors
  final Map<int, bool> _plantConnectionErrors = {};

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  void _startSync() {
    _fetchMoistureData();
    syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchMoistureData();
    });
  }

  @override
  void dispose() {
    syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMoistureData() async {
    if (isSyncing) return;
    setState(() => isSyncing = true);

    await _plantService.fetchMoistureData();

    if (mounted) {
      setState(() {
        isSyncing = false;
        // Update master switch state based on actual motors
        _isMasterOn = _plantService.getActiveMotors() == _plantService.getTotalMotors();
      });
    }
  }

  Future<void> togglePlantMotor(Plant plant) async {
    bool success = await _plantService.togglePlantMotor(plant.id, !plant.isMotorOn);

    if (success) {
      setState(() {
        _plantConnectionErrors[plant.id] = false;
        // Update master switch state after toggling a plant
        _isMasterOn = _plantService.getActiveMotors() == _plantService.getTotalMotors();
      });
    } else {
      setState(() {
        // If connection fails, force the motor status to OFF in the app
        plant.isMotorOn = false;
        _plantConnectionErrors[plant.id] = true;
        // Update master switch state in case
        _isMasterOn = _plantService.getActiveMotors() == _plantService.getTotalMotors();
      });

      // Automatically clear the error highlight after 3 seconds
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _plantConnectionErrors[plant.id] = false;
          });
        }
      });
    }
  }

  Future<void> _toggleAllMotors(bool value) async {
    if (value) {
      print("Start button clicked");
    } else {
      print("Stop button clicked");
    }
    setState(() => isTogglingAll = true);

    bool success = await _plantService.toggleAllMotors(value);

    if (mounted) {
      if (success) {
        setState(() {
          for (var plant in _plantService.getPlants()) {
            plant.isMotorOn = value; // update UI
          }
          // Update master switch state based on actual motors
          _isMasterOn = _plantService.getActiveMotors() == _plantService.getTotalMotors();
          isTogglingAll = false;
        });
      } else {
        setState(() {
          isTogglingAll = false;
          _allMotorsError = true;
          // Update master switch state based on actual motors (revert)
          _isMasterOn = _plantService.getActiveMotors() == _plantService.getTotalMotors();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      floatingActionButton: FloatingActionButton(
        heroTag: 'plant_settings_fab', // Added unique heroTag
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () => Navigator.pushNamed(context, '/settings'),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          const SizedBox(height: 100), // Adjusted space for overlapping card
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: _plantService.getTotalMotors(),
              itemBuilder: (context, index) {
                final plant = _plantService.getPlants()[index];
                return _buildPlantCard(plant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
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
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  if (isSyncing || isTogglingAll)
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
          bottom: -100, // Adjusted for smaller card
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
                      _statItem("TOTAL PLANTS", _plantService.getTotalMotors().toString(), Icons.grass_rounded),
                      Container(width: 1, height: 30, color: Colors.grey[200]),
                      _statItem("ACTIVE", _plantService.getActiveMotors().toString(), Icons.water_drop_rounded),
                    ],
                  ),
                  const Divider(height: 30),
                  // Master Control Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "MASTER CONTROLS",
                              style: TextStyle(
                                color: _allMotorsError ? Colors.red : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_allMotorsError)
                              const Text(
                                "CONNECTION FAILED",
                                style: TextStyle(color: Colors.red, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: isTogglingAll ? null : () => _toggleAllMotors(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Start"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isTogglingAll ? null : () => _toggleAllMotors(false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Stop"),
                          ),
                        ],
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

  Widget _buildPlantCard(Plant plant) {
    bool hasError = _plantConnectionErrors[plant.id] ?? false;
    Color moistureColor = plant.moistureLevel < 30 ? Colors.red : (plant.moistureLevel < 60 ? Colors.orange : Colors.green);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasError ? Colors.redAccent : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError ? Colors.red.withOpacity(0.2) : Colors.black.withOpacity(0.05),
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
                      ? Colors.red[50]
                      : (plant.isMotorOn ? const Color(0xFFE8F5E9) : Colors.grey[100]),
                  radius: 18,
                  child: Icon(
                    hasError ? Icons.wifi_off_rounded : Icons.grass,
                    color: hasError ? Colors.red : (plant.isMotorOn ? const Color(0xFF2E7D32) : Colors.grey),
                    size: 18,
                  ),
                ),
                Text("#${plant.id}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: isTogglingAll ? null : (_) => togglePlantMotor(plant),
                ),
                Text(
                  hasError ? "OFFLINE" : (plant.isMotorOn ? "ACTIVE" : "INACTIVE"),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: hasError ? Colors.red : (plant.isMotorOn ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }
}
