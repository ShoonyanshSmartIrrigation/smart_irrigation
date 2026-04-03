import 'package:flutter/material.dart';

//-------------------------------------------------------- BuildHeader Class ----------------------------------------------------------
class BuildHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsets? padding;

  // You can change this single value to update the height across all screens
  static const double defaultHeaderHeight = 200.0;

  const BuildHeader({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  @override
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
    );

    return SizedBox(
      width: double.infinity,
      height: height ?? defaultHeaderHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
