// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../Routes/app_Routes.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigateToNext();
//   }
//
//   Future<void> _navigateToNext() async {
//     await Future.delayed(const Duration(seconds: 3));
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//     if (mounted) {
//       Navigator.pushReplacementNamed(
//         context,
//         isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const Color brandGreen = Color(0xFF2E7D32);
//
//     return const Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.eco_rounded,
//               size: 100,
//               color: brandGreen,
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Smart Irrigation',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: brandGreen,
//                 letterSpacing: 1.2,
//               ),
//             ),
//             SizedBox(height: 30),
//             CircularProgressIndicator(
//               color: brandGreen,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../Routes/app_Routes.dart';

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
    const Color brandGreen = Color(0xFF2E7D32);

    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea( // ✅ UI safety
        child: Center(
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
      ),
    );
  }
}
