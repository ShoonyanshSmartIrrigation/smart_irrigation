import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 70;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  label: "Dashboard",
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                NavItem(
                  index: 1,
                  icon: Icons.polyline_outlined,
                  label: "Zones",
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                NavItem(
                  index: 2,
                  icon: Icons.access_time_rounded,
                  label: "Schedule",
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                NavItem(
                  index: 3,
                  icon: Icons.settings_outlined,
                  label: "Settings",
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int currentIndex;
  final Function(int) onTap;

  const NavItem({
    super.key,
    required this.index,
    required this.icon,
    required this.label,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double iconSize = 18;
    const double fontSize = 9;

    // ✅ State Safety: Validate index
    final bool isActive = currentIndex == index && currentIndex >= 0;

    return Expanded(
      child: Semantics(
        label: label,
        selected: isActive,
        container: true,
        button: true,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 90,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // ✅ Haptic Feedback
                  HapticFeedback.lightImpact();
                  onTap(index);
                },
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isActive ? Colors.white : const Color(0xFF78909C),
                      size: iconSize,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? Colors.white : const Color(0xFF78909C),
                        fontWeight: FontWeight.w800,
                        fontSize: fontSize,
                        letterSpacing: 0.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
