import 'dart:async';
import 'package:flutter/material.dart';
import '../services/esp32_service.dart';
import '../Core/theme/app_colors.dart';

//-------------------------------------------------------- Esp32ConfigScreen Class ----------------------------------------------------------
class Esp32ConfigScreen extends StatefulWidget {
  @override
  State<Esp32ConfigScreen> createState() => _Esp32ConfigScreenState();
}

//-------------------------------------------------------- _Esp32ConfigScreenState Class ----------------------------------------------------------
class _Esp32ConfigScreenState extends State<Esp32ConfigScreen> {
  final Esp32Service _esp32Service = Esp32Service();
  String status = "Checking...";
  String result = "Verifying current status...";
  bool isLoading = false;
  String? discoveredIp;

  @override
    //-------------------------------------------------------- Init State ----------------------------------------------------------
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialStatus();
    });
  }

  Future<void> _checkInitialStatus() async {
    setState(() {
      isLoading = true;
    });

    bool isConnected = await _esp32Service.checkInitialStatus();
    if (isConnected) {
      if (mounted) {
        setState(() {
          status = "Connected";
          result = "✅ Device is connected!";
          isLoading = false;
        });
      }
      return;
    }

    startAutoDiscovery();
  }

  Future<void> startAutoDiscovery() async {
    setState(() {
      isLoading = true;
      status = "Searching...";
      result = "Looking for Device on your network...";
      discoveredIp = null;
    });

    Map<String, dynamic>? resultData = await _esp32Service.startAutoDiscovery();

    if (mounted) {
      setState(() {
        isLoading = false;
        if (resultData != null) {
          status = "Connected";
          result = "✅ Device is connected!";
          discoveredIp = resultData['ip'];
        } else {
          status = "Not Found";
          result = "Could not find Device. Please ensure it's powered on and on the same Wi-Fi.";
        }
      });
    }
  }

  @override
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : AppColors.background,
      appBar: AppBar(
        title: const Text("Device Auto Connect", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(),
              const SizedBox(height: 30),
              Text(
                status,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: status == "Connected" ? AppColors.esp32Success : (isDark ? Colors.white : AppColors.black87)
                ),
              ),
              const SizedBox(height: 15),
              Text(
                result,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : AppColors.esp32TextGrey),
              ),
              if (discoveredIp != null) ...[
                const SizedBox(height: 10),
                Text(
                  "IP: $discoveredIp",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
              const SizedBox(height: 40),
              if (isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: startAutoDiscovery,
                    icon: Icon(status == "Connected" ? Icons.refresh : Icons.search),
                    label: Text(
                      status == "Connected" ? "RE-SCAN" : "TRY AGAIN",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (status == "Connected")
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      "DONE",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (status == "Connected") {
      return const Icon(Icons.check_circle, size: 100, color: AppColors.esp32Success);
    } else if (status == "Not Found") {
      return const Icon(Icons.error_outline, size: 100, color: AppColors.esp32Error);
    } else {
      return const Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          Icon(Icons.wifi_find, size: 60, color: AppColors.primary),
        ],
      );
    }
  }
}
