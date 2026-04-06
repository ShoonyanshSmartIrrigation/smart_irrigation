import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

//-------------------------------------------------------- WateringSchedule Class ----------------------------------------------------------
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

//-------------------------------------------------------- ScheduleService Class ----------------------------------------------------------
class ScheduleService extends ChangeNotifier {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<WateringSchedule> _schedules = [];
  List<WateringSchedule> get schedules => _schedules;
  StreamSubscription? _subscription;
  
  Timer? _localCheckTimer;
  final Set<String> _triggeredKeys = {};

  ScheduleService._internal() {
    _initListener();
    _startLocalTimer();
  }

  String get _userEmailKey => _auth.currentUser?.email?.replaceAll('.', ',') ?? "anonymous";
  String get _basePath => "users/$_userEmailKey/schedule/data";

  void _initListener() {
    _auth.authStateChanges().listen((user) {
      _subscription?.cancel();
      if (user != null) {
        final emailKey = user.email?.replaceAll('.', ',') ?? "anonymous";
        _subscription = _db.ref("users/$emailKey/schedule/data").onValue.listen((event) {
          if (event.snapshot.exists) {
            try {
              final Map<dynamic, dynamic> data = event.snapshot.value as Map;
              _schedules = data.entries.map((e) {
                return WateringSchedule.fromJson(Map<String, dynamic>.from(e.value));
              }).toList();
              _schedules.sort((a, b) => a.time.compareTo(b.time));
            } catch (e) {
              debugPrint("Error parsing schedules: $e");
              _schedules = [];
            }
          } else {
            _schedules = [];
          }
          notifyListeners();
        });
      } else {
        _schedules = [];
        notifyListeners();
      }
    });
  }

  void _startLocalTimer() {
    _localCheckTimer?.cancel();
    _localCheckTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      _checkAndTriggerSchedules();
    });
  }

  void _checkAndTriggerSchedules() {
    final now = DateTime.now();
    final currentTimeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final todayKey = "${now.year}-${now.month}-${now.day}";

    _triggeredKeys.removeWhere((key) => !key.contains(todayKey));

    for (var schedule in _schedules) {
      if (schedule.isEnabled && schedule.time == currentTimeStr) {
        final triggerKey = "${schedule.id}-$currentTimeStr-$todayKey";
        if (!_triggeredKeys.contains(triggerKey)) {
          _triggeredKeys.add(triggerKey);
          _triggerImmediateIrrigation(schedule);
        }
      }
    }
  }

  Future<void> _triggerImmediateIrrigation(WateringSchedule schedule) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;

    try {
      List<int> esp32Motors = [1];
      for (var m in schedule.selectedMotors) {
        if (m + 1 <= 9) esp32Motors.add(m + 1);
      }

      final body = {
        "duration": schedule.durationInMinutes,
        "motors": esp32Motors,
      };

      await http.post(
        Uri.parse("$baseUrl/api/schedule/start"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));
      
      debugPrint("📱 Local WiFi Trigger: Started ${schedule.title}");
    } catch (e) {
      debugPrint("📱 Local WiFi Trigger Failed: $e");
    }
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
    try {
      final snapshot = await _db.ref(_basePath).get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        _schedules = data.entries.map((e) {
          return WateringSchedule.fromJson(Map<String, dynamic>.from(e.value));
        }).toList();
        _schedules.sort((a, b) => a.time.compareTo(b.time));
      } else {
        _schedules = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("ScheduleService Fetch Error: $e");
    }
  }

  Future<void> addSchedule(WateringSchedule schedule) async {
    // Try local sync first
    if (schedule.isEnabled) {
      _syncToEsp32(schedule).catchError((e) => debugPrint("Local sync failed: $e"));
    }

    try {
      await _db.ref("$_basePath/${schedule.id}").set(schedule.toJson());
    } catch (e) {
      debugPrint("ScheduleService Add Error: $e");
      rethrow;
    }
  }

  Future<void> updateSchedule(WateringSchedule schedule) async {
    // Try local sync first
    if (schedule.isEnabled) {
      _syncToEsp32(schedule).catchError((e) => debugPrint("Local sync failed: $e"));
    }

    try {
      await _db.ref("$_basePath/${schedule.id}").update(schedule.toJson());
    } catch (e) {
      debugPrint("ScheduleService Update Error: $e");
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      final scheduleIndex = _schedules.indexWhere((s) => s.id == id);
      if (scheduleIndex == -1) return;
      
      await _db.ref("$_basePath/$id").remove();
    } catch (e) {
      debugPrint("ScheduleService Delete Error: $e");
      rethrow;
    }
  }

  Future<void> toggleSchedule(String id, bool enabled) async {
    try {
      final schedule = _schedules.firstWhere((s) => s.id == id);
      final updated = schedule.copyWith(isEnabled: enabled);
      await updateSchedule(updated);
    } catch (e) {
       debugPrint("ScheduleService Toggle Error: $e");
       rethrow;
    }
  }

  Future<void> _syncToEsp32(WateringSchedule schedule) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;

    try {
      final timeParts = schedule.time.split(':');
      List<int> esp32Motors = [1];
      for (var m in schedule.selectedMotors) {
        esp32Motors.add(m + 1);
      }

      final body = {
        "hour": int.parse(timeParts[0]),
        "minute": int.parse(timeParts[1]),
        "duration": schedule.durationInMinutes,
        "motors": esp32Motors,
      };

      await http.post(
        Uri.parse("$baseUrl/api/alarm/set"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Sync to ESP32 failed: $e");
    }
  }

  Future<void> stopEsp32Alarm() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;
    try {
      await http.post(Uri.parse("$baseUrl/api/alarm/stop"))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Stop ESP32 alarm failed: $e");
    }
  }

  @override
    //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
  void dispose() {
    _localCheckTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
