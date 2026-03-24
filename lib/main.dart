import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Routes/app_Routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Irrigation',
      initialRoute: isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
