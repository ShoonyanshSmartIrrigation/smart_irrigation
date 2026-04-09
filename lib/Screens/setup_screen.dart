import 'package:flutter/material.dart';
import '../services/setup_logic.dart';
import '../services/esp32_service.dart';
import '../Core/theme/app_colors.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final SetupLogic _setupLogic = SetupLogic();
  final Esp32Service _esp32Service = Esp32Service();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  String? _discoveredIp;
  String? _discoveredDeviceId;
  bool _isScanning = false;
  bool _scanComplete = false;

  void _nextStep() {
    if (_currentStep < 3) {
      // Auto trigger scan when reaching step 3
      if (_currentStep == 2 && !_scanComplete) {
         _startScan();
      }
      setState(() {
        _currentStep++;
      });
    } else {
      _finishSetup();
    }
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
      _discoveredIp = null;
      _discoveredDeviceId = null;
    });

    Map<String, dynamic>? resultData = await _esp32Service.startAutoDiscovery();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanComplete = true;
        if (resultData != null) {
          _discoveredIp = resultData['ip'];
          _discoveredDeviceId = resultData['deviceId'];
        }
      });
    }
  }

  void _finishSetup() async {
    setState(() => _isLoading = true);
    if (mounted) {
      await _setupLogic.completeSetup(context, ip: _discoveredIp, deviceId: _discoveredDeviceId);
    }
  }

  Widget _buildStep(String title, String description, IconData icon, int index) {
    if (index == 3) {
      return _buildScannerStep();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
         return FadeTransition(
           opacity: animation, 
           child: ScaleTransition(scale: animation, child: child)
         );
      },
      child: Column(
        key: ValueKey<int>(_currentStep),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerStep() {
    return Column(
      key: const ValueKey<int>(3),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _scanComplete && _discoveredIp != null 
                ? Colors.green.withOpacity(0.1) 
                : AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _scanComplete && _discoveredIp != null 
                ? Icons.check_circle_outline 
                : Icons.wifi_find_outlined,
            size: 80, 
            color: _scanComplete && _discoveredIp != null ? Colors.green : AppColors.primary,
          ),
        ),
        const SizedBox(height: 30),
        const Text("Connect Sprinkler", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 15),
        
        if (_isScanning)
          const Column(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 15),
              Text("Scanning network for ESP32...", style: TextStyle(color: Colors.grey)),
            ],
          )
        else if (_scanComplete && _discoveredIp != null)
          Container(
            padding: const EdgeInsets.all(15),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                const Text("✅ Device Found!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 5),
                Text("IP: $_discoveredIp", style: const TextStyle(color: Colors.black87)),
                Text("ID: $_discoveredDeviceId", style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          )
        else
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text("Ensure your ESP32 is powered on and connected to the same Wi-Fi network.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.5)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.search),
                label: const Text("Scan Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> steps = [
      {
        'title': 'Welcome to Smart Irrigation',
        'desc': 'Take control of your water usage and ensure your plants thrive with minimal effort.',
        'icon': Icons.water_drop_outlined
      },
      {
        'title': 'Automate Your Schedules',
        'desc': 'Set up customized watering times or let our smart system decide based on live data.',
        'icon': Icons.schedule_outlined
      },
      {
        'title': 'Real-Time Insights',
        'desc': 'Monitor soil moisture and weather forecasts right from your dashboard.',
        'icon': Icons.analytics_outlined
      },
      {
        'title': 'Connect Sprinkler',
        'desc': 'Locate your device on the network',
        'icon': Icons.wifi_find_outlined
      }
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildStep(
                steps[_currentStep]['title'],
                steps[_currentStep]['desc'],
                steps[_currentStep]['icon'],
                _currentStep,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        height: 10,
                        width: _currentStep == index ? 25 : 10,
                        decoration: BoxDecoration(
                          color: _currentStep == index ? AppColors.primary : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      _currentStep == steps.length - 1 ? "GET STARTED" : "NEXT",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
