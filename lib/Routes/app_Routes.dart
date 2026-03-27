import 'package:flutter/material.dart';
import '../Auth/Login_Screen.dart';
import '../Auth/Signup_Screen.dart';
import '../Screens/MainScreen.dart';
import '../Screens/Esp32Config_Screen.dart';
import '../Screens/SplashScreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String esp32Config = '/esp32Config';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    login: (context) => LoginScreen(),
    signup: (context) => SignupScreen(),
    dashboard: (context) => MainScreen(),
    esp32Config: (context) => Esp32ConfigScreen(),
  };
}
