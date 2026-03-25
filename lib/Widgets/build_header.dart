import 'package:flutter/material.dart';

class BuildHeader extends StatelessWidget {
  final Widget child;
  final double? height;

  // You can change this single value to update the height across all screens
  static const double defaultHeaderHeight = 200.0;

  const BuildHeader({
    super.key,
    required this.child,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? defaultHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: SafeArea(
        child: child,
      ),
    );
  }
}
