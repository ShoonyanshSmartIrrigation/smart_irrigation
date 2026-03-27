import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../Routes/app_Routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2E7D32);

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              size: 100,
              color: brandGreen,
            ),
            SizedBox(height: 20),
            Text(
              'Smart Irrigation',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: brandGreen,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: brandGreen,
            ),
          ],
        ),
      ),
    );
  }
}
