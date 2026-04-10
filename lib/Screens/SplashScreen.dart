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
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  //-------------------------------------------------------- Init State ----------------------------------------------------------
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();

    _initApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    try {
      // ✅ Run both tasks in parallel (faster startup)
      final results = await Future.wait([
        Future.delayed(const Duration(seconds: 3)), // reduced delay
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
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: Stack(
        children: [
          // Decorative background shapes
          Positioned(
            top: -50,
            left: -80,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  color: AppColors.splashPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: AppColors.splashPrimary.withValues(alpha: 0.05),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -80,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: AppColors.splashPrimary.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          // Main content
          SafeArea( // ✅ UI safety
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Image.asset(
                        'assets/jpeg/Splash_Logo.jpeg',
                        height: 400,
                        width: 400,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 150,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              color: AppColors.splashPrimary,
                              backgroundColor: AppColors.splashPrimary.withValues(alpha: 0.2),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Loading...",
                          style: TextStyle(
                            color: AppColors.splashPrimary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
