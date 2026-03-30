import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../Routes/app_Routes.dart';
import '../Core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // ✅ Run both tasks in parallel (faster startup)
      final results = await Future.wait([
        Future.delayed(const Duration(seconds: 2)), // reduced delay
        SharedPreferences.getInstance(),
      ]);

      final prefs = results[1] as SharedPreferences;
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      );

    } catch (e) {
      debugPrint("Splash Error: $e");

      if (!mounted) return;

      // ✅ fallback navigation (important for production)
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea( // ✅ UI safety
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.eco_rounded,
                size: 100,
                color: AppColors.splashPrimary,
              ),
              SizedBox(height: 20),
              Text(
                'Smart Irrigation',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.splashPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(
                color: AppColors.splashPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
