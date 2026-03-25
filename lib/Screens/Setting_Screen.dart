import 'package:flutter/material.dart';
import '../Routes/app_Routes.dart';
import '../services/settings_service.dart';
import '../Widgets/build_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  int minMoisture = 30;
  int maxMoisture = 70;
  String esp32Ip = "Not Set";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      minMoisture = settings["min_moisture"];
      maxMoisture = settings["max_moisture"];
      esp32Ip = settings["esp_ip"];
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    await _settingsService.updateSetting(key, value);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BuildHeader(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 30),
                    SizedBox(height: 10),
                    Text(
                      "Settings",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildSectionHeader("Irrigation Thresholds"),
            _buildSettingCard(
              icon: Icons.water_drop_outlined,
              title: "Minimum Moisture",
              subtitle: "$minMoisture%",
              onTap: () => _showMoistureDialog("Set Minimum Moisture", minMoisture, 0, maxMoisture - 1, (val) => _updateSetting("min_moisture", val)),
            ),
            _buildSettingCard(
              icon: Icons.waves,
              title: "Maximum Moisture",
              subtitle: "$maxMoisture%",
              onTap: () => _showMoistureDialog("Set Maximum Moisture", maxMoisture, minMoisture + 1, 100, (val) => _updateSetting("max_moisture", val)),
            ),
            
            _buildSectionHeader("System Configuration"),
            _buildSettingCard(
              icon: Icons.settings_ethernet,
              title: "ESP32 IP Address",
              subtitle: esp32Ip,
              onTap: _showIpDialog,
            ),
            
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/esp32Config'),
                icon: const Icon(Icons.wifi_find),
                label: const Text("AUTO DISCOVERY CONFIG"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
              ),
            ),
            
            _buildSectionHeader("Account & System"),
            _buildSettingCard(
              icon: Icons.logout,
              title: "Logout",
              subtitle: "Sign out of your account",
              color: Colors.redAccent,
              onTap: _showLogoutDialog,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 100), // Extra space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xFF2E7D32),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ),
      ),
    );
  }

  void _showMoistureDialog(String title, int currentValue, int min, int max, Function(int) onChanged) {
    TextEditingController controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: "Enter value (%)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              int? value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onChanged(value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter value between $min and $max")));
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showIpDialog() {
    TextEditingController controller = TextEditingController(text: esp32Ip == "Not Set" ? "" : esp32Ip);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("ESP32 IP Address"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "e.g. 192.168.1.15", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              String value = controller.text.trim();
              if (_settingsService.isValidIp(value)) {
                _updateSetting("esp_ip", value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid IP Address")));
              }
            },
            child: const Text("SAVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _settingsService.logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
