import 'package:flutter/material.dart';
import '../Auth/Login_Screen.dart';
import '../Screens/Dashboard_screen.dart';
import '../Screens/Setting_Screen.dart';
import '../Screens/maintenance_screen.dart';
import '../Screens/plant_control_screen.dart';
import '../Screens/Esp32Config_Screen.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String plant = '/plant';
  static const String maintenance = '/maintenance';
  static const String esp32Config = '/esp32Config';

  // Route map
  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    dashboard: (context) =>  DashboardScreen(),
    settings: (context) => SettingsScreen(),
    plant: (context) =>  PlantControlScreen(),
    maintenance: (context) =>  MaintenanceScreen(),
    esp32Config: (context) => Esp32ConfigScreen(),
  };
}