import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/settings_service.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

//-------------------------------------------------------- SettingsScreen Class ----------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

//-------------------------------------------------------- _SettingsScreenState Class ----------------------------------------------------------
class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuildHeader(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: AppColors.white,
                        child: Text(
                          _service.getInitials(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _service.userName.length > 18 
                          ? "${_service.userName.substring(0, 18)}..." 
                          : _service.userName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _service.userEmail,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            
            _buildSectionHeader("System Configuration"),
            _buildSettingsGroup([
              _buildSettingItem(
                icon: Icons.settings_ethernet,
                title: "ESP32 IP Address",
                subtitle: _service.esp32Ip,
                onTap: _showIpDialog,
              ),
              _buildSettingItem(
                icon: Icons.wifi_find,
                title: "ESP32 Configuration",
                subtitle: "Find ESP32 on local network",
                onTap: () => context.push('/esp32Config'),
                iconColor: Colors.orange[800]!,
                showDivider: false,
              ),
            ]),

            _buildSectionHeader("Account & System"),
            _buildSettingsGroup([
              _buildSettingItem(
                icon: Icons.logout,
                title: "Logout",
                subtitle: "Sign out of your account",
                iconColor: AppColors.settingsLogoutIcon,
                textColor: AppColors.settingsLogoutIcon,
                onTap: _showLogoutDialog,
                showDivider: false,
              ),
            ]),
            
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Text(
                    "Smart Irrigation System",
                    style: TextStyle(
                      color: AppColors.settingsSubtitleGrey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Version 1.0.0",
                    style: TextStyle(color: AppColors.grey.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
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
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.settingsSectionText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.settingsShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.primary,
    bool showDivider = true,
    Color? textColor,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: textColor ?? AppColors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: AppColors.settingsSubtitleGrey, fontSize: 13),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.grey),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 70, right: 20),
            child: Divider(height: 1, color: AppColors.settingsDivider),
          ),
      ],
    );
  }

  void _showIpDialog() {
    TextEditingController controller = TextEditingController(text: _service.esp32Ip == "Not Set" ? "" : _service.esp32Ip);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("ESP32 IP Address"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "e.g. 192.168.1.15", 
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              String value = controller.text.trim();
              if (_service.isValidIp(value)) {
                _service.updateSetting("esp_ip", value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid IP Address")));
              }
            },
            child: const Text("SAVE", style: TextStyle(color: AppColors.white)),
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
          TextButton(
            onPressed: () async {
              context.pop();
              await _service.logout();
              if (mounted) context.go('/login');
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
