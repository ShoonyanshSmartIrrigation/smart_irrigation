import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Widgets/custom_bottom_nav.dart';
import '../Core/theme/app_colors.dart';

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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Container(
          color: AppColors.background,
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
