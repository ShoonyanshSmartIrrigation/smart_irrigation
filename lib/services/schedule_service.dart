import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  ScheduleService._internal();

  List<WateringSchedule> _schedules = [];
  List<WateringSchedule> get schedules => _schedules;

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
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) throw Exception("ESP32 IP not configured");

    try {
      final response = await http
          .get(Uri.parse("$baseUrl/schedule"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _schedules = data.map((item) => WateringSchedule.fromJson(item)).toList();
        notifyListeners();
      } else {
        throw Exception("Failed to load schedules: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ScheduleService Fetch Error: $e");
      rethrow;
    }
  }

  Future<void> addSchedule(WateringSchedule schedule) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) throw Exception("ESP32 IP not configured");

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/schedule"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(schedule.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchSchedules();
      } else {
        throw Exception("Failed to add schedule: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ScheduleService Add Error: $e");
      rethrow;
    }
  }

  Future<void> updateSchedule(WateringSchedule schedule) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) throw Exception("ESP32 IP not configured");

    try {
      final response = await http.put(
        Uri.parse("$baseUrl/schedule"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(schedule.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await fetchSchedules();
      } else {
        throw Exception("Failed to update schedule: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("ScheduleService Update Error: $e");
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) throw Exception("ESP32 IP not configured");

    try {
      final response = await http
          .delete(Uri.parse("$baseUrl/schedule?id=$id"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await fetchSchedules();
      } else {
        throw Exception("Failed to delete schedule: ${response.statusCode}");
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
}
