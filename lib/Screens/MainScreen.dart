import 'package:flutter/material.dart';
import 'Dashboard_screen.dart';
import 'plant_control_screen.dart';
import 'schedule_screen.dart';
import 'Setting_Screen.dart';
import '../Widgets/custom_bottom_nav.dart';
import '../Core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    // ✅ Initialize screens only once (performance optimized)
    _screens = [
      DashboardScreen(onTabRequested: _onTap),
      const PlantControlScreen(),
      const ScheduleScreen(),
      const SettingsScreen(),
    ];
  }

  void _onTap(int index) {
    if (_currentIndex == index) return; // ✅ avoid unnecessary rebuild
    setState(() {
      _currentIndex = index;
    });
  }

  // ✅ Handle back button (production UX)
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          color: AppColors.background,
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
