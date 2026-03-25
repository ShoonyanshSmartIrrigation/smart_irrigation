import 'package:flutter/material.dart';
import '../Auth/Login_Screen.dart';
import '../Screens/MainScreen.dart';
import '../Screens/Esp32Config_Screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String esp32Config = '/esp32Config';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    dashboard: (context) => MainScreen(), // Points to MainScreen which holds the Nav Bar
    esp32Config: (context) => Esp32ConfigScreen(),
  };
}