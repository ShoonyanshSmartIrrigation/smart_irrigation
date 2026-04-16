import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/theme_service.dart';
import '../widgets/build_header.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? null : AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuildHeader(
              height: 150,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "FAQs",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("App Related"),
                  _buildFAQItem(
                    0,
                    question: "How do I add a new plant?",
                    answer: "Go to the 'Zones' tab and click on the '+' icon to add a new plant and configure its watering schedule.",
                    icon: Icons.local_florist_rounded,
                  ),
                  _buildFAQItem(
                    1,
                    question: "Can I control the pump manually?",
                    answer: "Yes, you can toggle the main pump from the Dashboard or control individual plant motors from the Zones screen.",
                    icon: Icons.touch_app_rounded,
                  ),
                  _buildFAQItem(
                    2,
                    question: "Is there an automatic mode?",
                    answer: "Yes, enable 'Auto Mode' on the Dashboard. The system will then follow your saved schedules for each plant.",
                    icon: Icons.auto_mode_rounded,
                  ),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader("ESP32 Related"),
                  _buildFAQItem(
                    3,
                    question: "How to connect ESP32 to WiFi?",
                    answer: "In the Settings screen, go to 'Device Configuration'. Follow the on-screen instructions to connect your ESP32 to your local WiFi network.",
                    icon: Icons.wifi_rounded,
                  ),
                  _buildFAQItem(
                    4,
                    question: "What if the device is offline?",
                    answer: "Check if the ESP32 is powered on and within range of your WiFi router. You can also use Bluetooth (BLE) for local control when WiFi is unavailable.",
                    icon: Icons.wifi_off_rounded,
                  ),
                  _buildFAQItem(
                    5,
                    question: "How to update the ESP32 IP?",
                    answer: "If your router assigns a new IP to the ESP32, you can update it in Settings -> Device IP Address.",
                    icon: Icons.settings_ethernet_rounded,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFAQItem(int index, {required String question, required String answer, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpanded = _expandedIndex == index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.settingsShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ExpansionTile(
          key: GlobalKey(), // Important for state management
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedIndex = expanded ? index : null;
            });
          },
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isDark ? Colors.white : AppColors.black87,
            ),
          ),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.grey,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Divider(height: 1, color: AppColors.settingsDivider),
            ),
            Text(
              answer,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
