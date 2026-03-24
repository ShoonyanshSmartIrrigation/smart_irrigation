import 'package:flutter/material.dart';
import '../data_manager.dart';

class PlantControlScreen extends StatefulWidget {
  const PlantControlScreen({super.key});

  @override
  State<PlantControlScreen> createState() => _PlantControlScreenState();
}

class _PlantControlScreenState extends State<PlantControlScreen> {
  final DataManager dataManager = DataManager();

  @override
  void initState() {
    super.initState();
  }

  // Toggle motor
  void togglePlantMotor(Plant plant) {
    setState(() {
      dataManager.updatePlantMotor(plant.id, !plant.isMotorOn);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${plant.name} Motor ${plant.isMotorOn ? "ON" : "OFF"}"),
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text("Plant Control", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: () {
          Navigator.pushNamed(context, '/settings');
        },
        child: const Icon(Icons.settings, color: Colors.white),
      ),

      body: Column(
        children: [
          // 📊 Statistics Section
          _buildStatsHeader(),

          // 🌱 Grid of Plants
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
              ),
              itemCount: dataManager.plants.length,
              itemBuilder: (context, index) {
                final plant = dataManager.plants[index];
                return _buildPlantCard(plant);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Card(
        elevation: 0,
        color: Colors.white.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Total Plants", dataManager.totalMotors.toString()),
                  _statItem("Active Motors", dataManager.activeMotors.toString()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Average Moisture", style: TextStyle(color: Colors.white70)),
                  Text("${dataManager.avgMoisture}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (dataManager.avgMoisture / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  color: Colors.greenAccent,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
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
                  backgroundColor: plant.isMotorOn ? const Color(0xFFE8F5E9) : Colors.grey[100],
                  radius: 18,
                  child: Icon(Icons.grass, color: plant.isMotorOn ? const Color(0xFF2E7D32) : Colors.grey, size: 18),
                ),
                Text("#${plant.id}", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                Text(plant.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Moisture: ${plant.moistureLevel}%", style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            Column(
              children: [
                Switch.adaptive(
                  value: plant.isMotorOn,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (_) => togglePlantMotor(plant),
                ),
                Text(
                  plant.isMotorOn ? "ACTIVE" : "INACTIVE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: plant.isMotorOn ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
