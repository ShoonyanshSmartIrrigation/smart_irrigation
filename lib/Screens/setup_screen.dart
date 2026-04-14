import 'package:flutter/material.dart';
import '../services/setup_logic.dart';
import '../services/esp32_service.dart';
import '../core/theme/app_colors.dart';
import '../bluetooth_connection.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final SetupLogic _setupLogic = SetupLogic();
  final Esp32Service _esp32Service = Esp32Service();
  final TextEditingController _deviceIdController = TextEditingController();
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  String? _discoveredIp;
  String? _discoveredDeviceId;
  bool _isScanning = false;
  bool _scanComplete = false;
  int _selectedMethodIndex = -1; // 0: Bluetooth, 1: Wi-Fi, 2: Manual
  bool _isReadyToStart = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
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
      _isReadyToStart = false;
    });

    Map<String, dynamic>? resultData = await _esp32Service.startAutoDiscovery();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanComplete = true;
        if (resultData != null) {
          _discoveredIp = resultData['ip'];
          _discoveredDeviceId = resultData['deviceId'];
          _isReadyToStart = true;
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
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 90, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        key: const ValueKey<int>(3),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.router_outlined, size: 70, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text("Connect Sprinkler", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text("Choose how to connect your device", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 35),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMethodCard(0, Icons.bluetooth, "Bluetooth"),
              _buildMethodCard(1, Icons.wifi, "Wi-Fi Scan"),
              _buildMethodCard(2, Icons.keyboard, "Manual ID"),
            ],
          ),
          const SizedBox(height: 40),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedMethodIndex == 0 
                ? _buildBluetoothUI()
                : _selectedMethodIndex == 1 
                    ? _buildWifiUI() 
                    : _selectedMethodIndex == 2 
                        ? _buildManualUI() 
                        : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(int index, IconData icon, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = _selectedMethodIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodIndex = index;
          _isReadyToStart = false; // Reset until valid
          if (index == 1 && !_scanComplete) {
            _startScan();
          } else if (index == 1 && _scanComplete && _discoveredIp != null) {
            _isReadyToStart = true;
          } else if (index == 2) {
            _isReadyToStart = _deviceIdController.text.length == 10;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 105,
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: isSelected 
            ? Border.all(color: AppColors.primary, width: 2)
            : (isDark ? null : Border.all(color: Colors.grey.shade200, width: 2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white54 : Colors.grey.shade500), size: 32),
            const SizedBox(height: 12),
            Text(
              title, 
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade700), 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                fontSize: 13,
              ), 
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text(
            "Ensure your device is nearby. We will connect to Device.",
            textAlign: TextAlign.center, 
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, height: 1.5, fontSize: 14),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : () async {
              setState(() {
                _isScanning = true;
              });
            
              try {
                final btService = BluetoothConnectionService();
                await btService.startScan();
                
                // Wait a bit for scan
                await Future.delayed(const Duration(seconds: 4));
                
                await btService.stopScan();
                final results = await btService.scanResults.first;
                if (results.isNotEmpty) {
                  final device = results.first.device;
                  bool connected = await btService.connectToDevice(device);
                  if (connected) {
                    // In a real app we might read a specific characteristic here, 
                    // but for now we'll use the device's remote ID or a mocked read.
                    String fetchedDeviceId = device.remoteId.toString().replaceAll(':', '').substring(0, 10).toUpperCase();
                    if (fetchedDeviceId.length < 10) fetchedDeviceId = fetchedDeviceId.padRight(10, 'A');

                    if (mounted) {
                      setState(() {
                        _isReadyToStart = true;
                        _discoveredDeviceId = fetchedDeviceId;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bluetooth connected: $_discoveredDeviceId!")));
                    }
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to connect via Bluetooth")));
                  }
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No ESP32_IRRIGATION found nearby")));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bluetooth error: $e")));
              } finally {
                if (mounted) {
                  setState(() {
                    _isScanning = false;
                  });
                }
              }
            },
            icon: _isScanning 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.bluetooth_connected),
            label: Text(_isScanning ? "Scanning..." : "Pair Device"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          if (_isScanning)
            Column(
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                Text("Scanning network for Device...", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 16)),
              ],
            )
          else if (_scanComplete && _discoveredIp != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(12), 
                border: Border.all(color: Colors.green.shade300)
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                      const SizedBox(width: 10),
                      Text("Device Found!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("IP: $_discoveredIp", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text("ID: $_discoveredDeviceId", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                ],
              ),
            )
          else
            Column(
              children: [
                Text(
                  "Ensure your Device is powered on and connected to the same Wi-Fi network.",
                  textAlign: TextAlign.center, 
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.search),
                  label: const Text("Scan Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildManualUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Manual ID Entry", style: TextStyle(color: isDark ? Colors.white : Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Enter your 10-character Device ID exactly as it appears on your device.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _deviceIdController,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2),
            decoration: InputDecoration(
              labelText: "Device ID",
              labelStyle: const TextStyle(letterSpacing: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
              counterText: "",
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade50,
            ),
            maxLength: 10,
            onChanged: (val) {
              setState(() {
                _isReadyToStart = val.length == 10;
                if (_isReadyToStart) {
                   _discoveredDeviceId = val;
                   _discoveredIp = null; // No IP for manual setup usually, or backend fetches it
                }
              });
            },
          ),
          const SizedBox(height: 12),
          if (_deviceIdController.text.isNotEmpty && _deviceIdController.text.length < 10)
            const Text("Device ID must be exactly 10 characters", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
          if (_isReadyToStart)
            const Text("Valid Device ID!", style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
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
                          color: _currentStep == index ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : (_currentStep == 3 && !_isReadyToStart)
                    ? const SizedBox(height: 55) // Hide button if conditions are not met on step 3
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
