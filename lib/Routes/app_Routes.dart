import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../Auth/Login_Screen.dart';
import '../Auth/Signup_Screen.dart';
import '../Screens/MainScreen.dart';
import '../Screens/Dashboard_screen.dart';
import '../Screens/plant_control_screen.dart';
import '../Screens/schedule_screen.dart';
import '../Screens/Setting_Screen.dart';
import '../Screens/Esp32Config_Screen.dart';
import '../Screens/SplashScreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String zones = '/zones';
  static const String schedule = '/schedule';
  static const String settings = '/settings';
  static const String esp32Config = '/esp32Config';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: esp32Config,
        builder: (context, state) => Esp32ConfigScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: dashboard,
                builder: (context, state) => DashboardScreen(
                  onTabRequested: (index) {
                    if (index == 1) context.go(zones);
                    if (index == 2) context.go(schedule);
                    if (index == 3) context.go(settings);
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: zones,
                builder: (context, state) => const PlantControlScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text("Page not found"),
      ),
    ),
  );
}
