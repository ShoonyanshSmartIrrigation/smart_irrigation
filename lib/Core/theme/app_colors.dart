import 'package:flutter/material.dart';

//-------------------------------------------------------- AppColors Class ----------------------------------------------------------
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF2E7D32);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color grey = Colors.grey;

  // Backgrounds
  static const Color background = Color(0xFFF4F7F5);
  static const Color cardBackground = Colors.white;

  // Splash Screen
  static const Color splashBackground = Colors.white;
  static const Color splashPrimary = Color(0xFF2E7D32);

  // Login Screen
  static const Color loginBackground = Color(0xFFF4F7F5);
  static const Color loginTextFieldBg = Colors.white;
  static const Color loginTextGrey = Color(0xFF757575); // Colors.grey[600]
  static const Color loginTextDarkGrey = Color(0xFF616161); // Colors.grey[700]
  static const Color loginDivider = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color loginShadow = Color(0x0D000000); // Colors.black.withValues(alpha: 0.05)
  static const Color loginHeaderIconBg = Color(0x33FFFFFF); // Colors.white.withValues(alpha: 0.2)
  static const Color loginSubtitle = Color(0xCCFFFFFF); // Colors.white.withValues(alpha: 0.8)
  static const Color loginGoogleButtonBg = Colors.white;
  static const Color loginGoogleButtonText = Colors.black87;
  static const Color loginButtonShadow = Color(0x662E7D32); // primary with opacity

  // Signup Screen
  static const Color signupBackground = Color(0xFFF4F7F5);
  static const Color signupTextFieldBg = Colors.white;
  static const Color signupTextGrey = Color(0xFF757575); // Colors.grey[600]
  static const Color signupTextDarkGrey = Color(0xFF616161); // Colors.grey[700]
  static const Color signupDivider = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color signupShadow = Color(0x0D000000); // Colors.black.withValues(alpha: 0.05)
  static const Color signupHeaderIconBg = Color(0x33FFFFFF); // Colors.white.withValues(alpha: 0.2)
  static const Color signupSubtitle = Color(0xCCFFFFFF); // Colors.white.withValues(alpha: 0.8)
  static const Color signupButtonShadow = Color(0x662E7D32); // primary with opacity
  static const Color signupGoogleButtonBg = Colors.white;
  static const Color signupGoogleButtonText = Colors.black87;

  // Dashboard Screen
  static const Color dashboardTextDark = Color(0xFF1A1A1A);
  static const Color dashboardTimerCardBg = Color(0xFF1A1A1A);
  static const Color dashboardWheelPickerBg = Color(0xFFE8F5E9);
  static const Color dashboardMoistureBg = Color(0xFFE3F2FD);
  static const Color dashboardMoistureIcon = Color(0xFF1976D2);
  static const Color dashboardHardwareBg = Color(0xFFFFF3E0);
  static const Color dashboardHardwareIcon = Color(0xFFE65100);
  static const Color dashboardStopButtonBg = Color(0xFF332020);
  static const Color dashboardDivider = Color(0xFFEEEEEE); // Colors.grey[200]

  // Settings Screen
  static const Color settingsSectionText = Color(0xFF2E7D32);
  static const Color settingsIconBg = Color(0x1A2E7D32); // Color(0xFF2E7D32).withValues(alpha: 0.1)
  static const Color settingsLogoutIcon = Colors.redAccent;
  static const Color settingsSubtitleGrey = Color(0xFF757575); // Colors.grey[600]
  static const Color settingsDivider = Color(0xFFF5F5F5); // Colors.grey[100]
  static const Color settingsShadow = Color(0x08000000); // Colors.black.withValues(alpha: 0.03)

  // Schedule Screen
  static const Color scheduleTextDark = Color(0xFF1A1A1A);
  static const Color scheduleIconBg = Color(0xFFE8F5E9);
  static const Color scheduleDeleteIcon = Colors.redAccent;
  static const Color scheduleEmptyIcon = Color(0xFFE0E0E0); // Colors.grey[300]
  static const Color scheduleSubtext = Color(0xFF757575); // Colors.grey[600]
  static const Color scheduleShadow = Color(0x0D000000); // Colors.black.withValues(alpha: 0.05)

  // Plant Control Screen
  static const Color plantControlError = Colors.redAccent;
  static const Color plantControlActive = Colors.green;
  static const Color plantControlInactive = Colors.grey;
  static const Color plantControlMoistureLow = Colors.red;
  static const Color plantControlMoistureMedium = Colors.orange;
  static const Color plantControlMoistureHigh = Colors.green;
  static const Color plantControlIconBg = Color(0xFFE8F5E9);
  static const Color plantControlDivider = Color(0xFFEEEEEE); // Colors.grey[200]
  static const Color plantControlLabelGrey = Color(0xFF9E9E9E); // Colors.grey[500]
  static const Color plantControlIconGrey = Color(0xFFBDBDBD); // Colors.grey[400]

  // ESP32 Config Screen
  static const Color esp32Success = Colors.green;
  static const Color esp32Error = Colors.redAccent;
  static const Color esp32TextGrey = Colors.black54;

  // Main Screen
  static const Color mainSafeAreaBg = Color(0xFFF4F7F5);
}
