import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../Routes/app_routes.dart';
import '../Core/theme/app_colors.dart';

//-------------------------------------------------------- SplashScreen Class ----------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//-------------------------------------------------------- _SplashScreenState Class ----------------------------------------------------------
class _SplashScreenState extends State<SplashScreen> {

  @override
    //-------------------------------------------------------- Init State ----------------------------------------------------------
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

      context.go(isLoggedIn ? AppRoutes.dashboard : AppRoutes.login);

    } catch (e) {
      debugPrint("Splash Error: $e");

      if (!mounted) return;

      // œ… fallback navigation (important for production)
      context.go(AppRoutes.login);
    }
  }

  @override
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
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
