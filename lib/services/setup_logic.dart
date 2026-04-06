import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../Routes/app_routes.dart';

class SetupLogic {
  final AuthService _authService = AuthService();

  bool isFreshUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return _authService.isFreshUser(user.uid);
  }

  Future<void> completeSetup(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _authService.markSetupCompleted(user.uid);
      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }
}
