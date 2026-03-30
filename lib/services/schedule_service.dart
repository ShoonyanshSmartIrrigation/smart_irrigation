import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WateringSchedule {
  final String id;
  final DateTime time;
  final String title;
  final String frequency;
  final int durationInMinutes;
  bool isEnabled;
  final bool smartSkip;
  final List<int> selectedMotors;

  WateringSchedule({
    required this.id,
    required this.time,
    required this.title,
    required this.frequency,
    required this.durationInMinutes,
    required this.isEnabled,
    required this.smartSkip,
    required this.selectedMotors,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'title': title,
        'frequency': frequency,
        'durationInMinutes': durationInMinutes,
        'isEnabled': isEnabled,
        'smartSkip': smartSkip,
        'selectedMotors': selectedMotors,
      };

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: json['time'] != null 
          ? DateTime.parse(json['time']) 
          : DateTime.now(),
      title: json['title'] ?? 'Watering Task',
      frequency: json['frequency'] ?? 'Daily',
      durationInMinutes: json['durationInMinutes'] ?? 10,
      isEnabled: json['isEnabled'] ?? true,
      smartSkip: json['smartSkip'] ?? true,
      selectedMotors: List<int>.from(json['selectedMotors'] ?? []),
    );
  }

  WateringSchedule copyWith({
    String? id,
    DateTime? time,
    String? title,
    String? frequency,
    int? durationInMinutes,
    bool? isEnabled,
    bool? smartSkip,
    List<int>? selectedMotors,
  }) {
    return WateringSchedule(
      id: id ?? this.id,
      time: time ?? this.time,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      smartSkip: smartSkip ?? this.smartSkip,
      selectedMotors: selectedMotors ?? this.selectedMotors,
    );
  }
}

class ScheduleService extends ChangeNotifier {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static const String _storageKey = 'watering_schedules';
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  List<WateringSchedule> _schedules = [];

  List<WateringSchedule> get schedules => _schedules;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      await loadSchedules();
      _isInitialized = true;
    } catch (e) {
      debugPrint("ScheduleService Init Error: $e");
    }
  }

  Future<List<WateringSchedule>> loadSchedules() async {
    final String? schedulesJson = _prefs.getString(_storageKey);
    if (schedulesJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(schedulesJson);
        _schedules = decoded.map((item) => WateringSchedule.fromJson(item)).toList();
      } catch (e) {
        debugPrint("Error decoding schedules: $e");
        _schedules = _getDefaultSchedules();
      }
    } else {
      _schedules = _getDefaultSchedules();
    }
    notifyListeners();
    return _schedules;
  }

  List<WateringSchedule> _getDefaultSchedules() {
    return [
      WateringSchedule(
        id: "default_1",
        time: DateTime.now(),
        title: "Morning Hydration",
        frequency: "Daily",
        durationInMinutes: 15,
        isEnabled: true,
        smartSkip: true,
        selectedMotors: [1],
      ),
    ];
  }

  Future<void> _persistSchedules() async {
    try {
      final String encoded = jsonEncode(_schedules.map((s) => s.toJson()).toList());
      await _prefs.setString(_storageKey, encoded);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving schedules: $e");
    }
  }

  Future<void> addSchedule(WateringSchedule schedule) async {
    _schedules.add(schedule);
    await _persistSchedules();
  }

  Future<void> updateSchedule(WateringSchedule updatedSchedule) async {
    int index = _schedules.indexWhere((s) => s.id == updatedSchedule.id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
      await _persistSchedules();
    }
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    await _persistSchedules();
  }

  Future<void> toggleSchedule(String id, bool isEnabled) async {
    int index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schedules[index].isEnabled = isEnabled;
      await _persistSchedules();
    }
  }
}
