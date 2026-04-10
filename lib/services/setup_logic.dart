import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> saveDeviceDetails(String? ip, String deviceId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('esp_device_id', deviceId);

      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      
      // 1. Save strictly under users -> user.uid -> deviceId
      await dbRef.child('users').child(user.uid).child('deviceId').set(deviceId);
      
      // 2. Initialize device node
      await dbRef.child('devices').child(deviceId).set({
        'owner': user.uid,
        'ip': ip ?? 'Unknown',
        'lastUpdated': ServerValue.timestamp,
        'motors': {
          "1": {"isOn": false}, "2": {"isOn": false}, "3": {"isOn": false}, "4": {"isOn": false},
          "5": {"isOn": false}, "6": {"isOn": false}, "7": {"isOn": false}, "8": {"isOn": false}
        },
        'plants': {
          "1": {"name": "Plant 1", "moisture": 0}, "2": {"name": "Plant 2", "moisture": 0},
          "3": {"name": "Plant 3", "moisture": 0}, "4": {"name": "Plant 4", "moisture": 0},
          "5": {"name": "Plant 5", "moisture": 0}, "6": {"name": "Plant 6", "moisture": 0},
          "7": {"name": "Plant 7", "moisture": 0}, "8": {"name": "Plant 8", "moisture": 0}
        },
        'schedules': {}
      });
    }
  }

  Future<void> completeSetup(BuildContext context, {String? ip, String? deviceId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (deviceId != null) {
        await saveDeviceDetails(ip, deviceId);
      }
      await _authService.markSetupCompleted(user.uid);
      if (context.mounted) {
        context.go(AppRoutes.dashboard);
      }
    }
  }
}
