import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Widgets/custom_bottom_nav.dart';

//-------------------------------------------------------- MainScreen Class ----------------------------------------------------------
class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  void _onTap(int index) {
    if (navigationShell.currentIndex == index) return;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<bool> _onWillPop() async {
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          color: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF4F7F5),
          child: navigationShell,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}
