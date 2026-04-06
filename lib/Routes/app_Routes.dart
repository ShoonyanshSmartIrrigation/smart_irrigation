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
    redirect: (context, state) {
      final isLoggedIn = true; // replace with your auth check

      final isAuthRoute = state.matchedLocation == login ||
          state.matchedLocation == signup ||
          state.matchedLocation == splash;

      if (!isLoggedIn && !isAuthRoute) {
        return login;
      }

      if (isLoggedIn && isAuthRoute) {
        return dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        name: 'splash',
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: 'login',
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'signup',
        path: signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        name: 'esp32Config',
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
                name: 'dashboard',
                path: dashboard,
                builder: (context, state) => DashboardScreen(
                  onTabRequested: (index) {
                    if (index == 1) context.go(AppRoutes.zones);
                    if (index == 2) context.go(AppRoutes.schedule);
                    if (index == 3) context.go(AppRoutes.settings);
                  },
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'zones',
                path: zones,
                builder: (context, state) => const PlantControlScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'schedule',
                path: schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'settings',
                path: settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 10),
            Text("Page not found: ${state.uri}"),
          ],
        ),
      ),
    ),
  );
}
