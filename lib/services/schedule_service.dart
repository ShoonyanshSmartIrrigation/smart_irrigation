import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WateringSchedule {
  final String id;
  final String time; // HH:mm format
  final String title;
  final String frequency;
  final int durationInMinutes;
  final bool isEnabled;
  final List<int> selectedMotors;

  WateringSchedule({
    required this.id,
    required this.time,
    required this.title,
    required this.frequency,
    required this.durationInMinutes,
    required this.isEnabled,
    required this.selectedMotors,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time,
        'title': title,
        'frequency': frequency,
        'durationInMinutes': durationInMinutes,
        'isEnabled': isEnabled,
        'selectedMotors': selectedMotors,
      };

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      id: json['id']?.toString() ?? '',
      time: json['time'] ?? '08:00',
      title: json['title'] ?? 'Watering Task',
      frequency: json['frequency'] ?? 'Daily',
      durationInMinutes: json['durationInMinutes'] ?? 10,
      isEnabled: json['isEnabled'] == true || json['isEnabled'] == 1,
      selectedMotors: List<int>.from(json['selectedMotors'] ?? []),
    );
  }

  WateringSchedule copyWith({
    String? id,
    String? time,
    String? title,
    String? frequency,
    int? durationInMinutes,
    bool? isEnabled,
    List<int>? selectedMotors,
  }) {
    return WateringSchedule(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      selectedMotors: selectedMotors ?? this.selectedMotors,
    );
  }
}

class ScheduleService extends ChangeNotifier {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<WateringSchedule> _schedules = [];
  List<WateringSchedule> get schedules => _schedules;
  StreamSubscription? _subscription;

  ScheduleService._internal() {
    _initListener();
  }

  String get _uid => _auth.currentUser?.uid ?? "anonymous";

  void _initListener() {
    _auth.authStateChanges().listen((user) {
      _subscription?.cancel();
      if (user != null) {
        _subscription = _db.ref("schedule/${user.uid}").onValue.listen((event) {
          if (event.snapshot.exists) {
            final Map<dynamic, dynamic> data = event.snapshot.value as Map;
            _schedules = data.entries.map((e) {
              return WateringSchedule.fromJson(Map<String, dynamic>.from(e.value));
            }).toList();
            _schedules.sort((a, b) => a.time.compareTo(b.time));
          } else {
            _schedules = [];
          }
          notifyListeners();
        });
      }
    });
  }

  Future<String?> _getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? ip = prefs.getString("esp_ip");
      if (ip == null || ip.isEmpty) return null;
      return "http://$ip";
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchSchedules() async {
    // Listener already handles real-time updates, but we can do a manual fetch if needed
    try {
      final snapshot = await _db.ref("schedule/$_uid").get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        _schedules = data.entries.map((e) {
          return WateringSchedule.fromJson(Map<String, dynamic>.from(e.value));
        }).toList();
        _schedules.sort((a, b) => a.time.compareTo(b.time));
        notifyListeners();
      }
    } catch (e) {
      debugPrint("ScheduleService Fetch Error: $e");
    }
  }

  Future<void> addSchedule(WateringSchedule schedule) async {
    try {
      if (schedule.isEnabled) {
        await _disableAllSchedulesInFirebase();
      }

      await _db.ref("schedule/$_uid/${schedule.id}").set(schedule.toJson());
      
      if (schedule.isEnabled) {
        await _syncToEsp32(schedule);
      }
    } catch (e) {
      debugPrint("ScheduleService Add Error: $e");
      rethrow;
    }
  }

  Future<void> updateSchedule(WateringSchedule schedule) async {
    try {
      if (schedule.isEnabled) {
        await _disableAllSchedulesInFirebase(excludeId: schedule.id);
      }

      await _db.ref("schedule/$_uid/${schedule.id}").update(schedule.toJson());
      
      if (schedule.isEnabled) {
        await _syncToEsp32(schedule);
      } else {
        await _stopEsp32Alarm();
      }
    } catch (e) {
      debugPrint("ScheduleService Update Error: $e");
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      final schedule = _schedules.firstWhere((s) => s.id == id);
      await _db.ref("schedule/$_uid/$id").remove();
      
      if (schedule.isEnabled) {
        await _stopEsp32Alarm();
      }
    } catch (e) {
      debugPrint("ScheduleService Delete Error: $e");
      rethrow;
    }
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    final schedule = _schedules.firstWhere((s) => s.id == id);
    final updated = schedule.copyWith(isEnabled: enabled);
    await updateSchedule(updated);
  }

  Future<void> _disableAllSchedulesInFirebase({String? excludeId}) async {
    for (var s in _schedules) {
      if (s.id != excludeId && s.isEnabled) {
        await _db.ref("schedule/$_uid/${s.id}").update({'isEnabled': false});
      }
    }
  }

  Future<void> _syncToEsp32(WateringSchedule schedule) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) throw Exception("ESP32 IP not configured");

    try {
      final timeParts = schedule.time.split(':');
      
      List<int> esp32Motors = [1]; // Always include Main Motor (ID 1)
      for (var m in schedule.selectedMotors) {
        esp32Motors.add(m + 1); // Map UI 1-8 to hardware IDs 2-9
      }

      final body = {
        "hour": int.parse(timeParts[0]),
        "minute": int.parse(timeParts[1]),
        "duration": schedule.durationInMinutes,
        "motors": esp32Motors,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/api/alarm/set"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception("ESP32 responded with ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Sync to ESP32 failed: $e");
      rethrow;
    }
  }

  Future<void> _stopEsp32Alarm() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;

    try {
      await http.post(Uri.parse("$baseUrl/api/alarm/stop"))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Stop ESP32 alarm failed: $e");
    }
  }
}
