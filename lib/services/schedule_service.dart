import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WateringSchedule {
  final String time;
  final String title;
  final String frequency;
  final String duration;
  bool isEnabled;
  final bool smartSkip;
  final List<int> selectedMotors; // Added this field

  WateringSchedule({
    required this.time,
    required this.title,
    required this.frequency,
    required this.duration,
    required this.isEnabled,
    required this.smartSkip,
    required this.selectedMotors, // Added this field
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'title': title,
        'frequency': frequency,
        'duration': duration,
        'isEnabled': isEnabled,
        'smartSkip': smartSkip,
        'selectedMotors': selectedMotors, // Added this field
      };

  factory WateringSchedule.fromJson(Map<String, dynamic> json) => WateringSchedule(
        time: json['time'],
        title: json['title'],
        frequency: json['frequency'],
        duration: json['duration'],
        isEnabled: json['isEnabled'],
        smartSkip: json['smartSkip'],
        selectedMotors: List<int>.from(json['selectedMotors'] ?? []), // Added this field
      );
}

class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  static const String _storageKey = 'watering_schedules';

  Future<List<WateringSchedule>> loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? schedulesJson = prefs.getString(_storageKey);

    if (schedulesJson != null) {
      final List<dynamic> decoded = jsonDecode(schedulesJson);
      return decoded.map((item) => WateringSchedule.fromJson(item)).toList();
    } else {
      List<WateringSchedule> defaultSchedules = [
        WateringSchedule(
          time: "06:30 AM",
          title: "Morning Hydration",
          frequency: "Daily",
          duration: "15 mins",
          isEnabled: true,
          smartSkip: true,
          selectedMotors: [1], // Default motor 1
        ),
      ];
      await saveSchedules(defaultSchedules);
      return defaultSchedules;
    }
  }

  Future<void> saveSchedules(List<WateringSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(schedules.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
