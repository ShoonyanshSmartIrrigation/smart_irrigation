import 'dart:async';
import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../services/plant_service.dart';
import '../Widgets/build_header.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _scheduleService = ScheduleService();
  final PlantService _plantService = PlantService();
  List<WateringSchedule> schedules = [];
  bool isLoading = true;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    _startScheduleChecker();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  void _startScheduleChecker() {
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndRunSchedules();
    });
  }

  void _checkAndRunSchedules() {
    final now = TimeOfDay.now();
    final nowStr = _formatTimeOfDay(now);

    for (var schedule in schedules) {
      if (schedule.isEnabled && schedule.time == nowStr) {
        _runSchedule(schedule);
      }
    }
  }

  Future<void> _runSchedule(WateringSchedule schedule) async {
    // 1. Turn ON the selected motors
    for (int motorId in schedule.selectedMotors) {
      await _plantService.togglePlantMotor(motorId, true);
    }
    if (mounted) setState(() {});

    // 2. Wait for the duration
    int durationMinutes = int.tryParse(schedule.duration.split(' ')[0]) ?? 10;
    
    Timer(Duration(minutes: durationMinutes), () async {
      // 3. Turn OFF the selected motors after duration is complete
      for (int motorId in schedule.selectedMotors) {
        await _plantService.togglePlantMotor(motorId, false);
      }
      if (mounted) setState(() {});
      
      _showCompletionNotification(schedule);
    });
  }

  void _showCompletionNotification(WateringSchedule schedule) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Schedule '${schedule.title}' completed. Motors turned off."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _loadSchedules() async {
    final loadedSchedules = await _scheduleService.loadSchedules();
    setState(() {
      schedules = loadedSchedules;
      isLoading = false;
    });
  }

  Future<void> _saveSchedules() async {
    await _scheduleService.saveSchedules(schedules);
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return "${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String period = parts[1];

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}..";
  }

  void _showScheduleSheet({WateringSchedule? schedule, int? index}) {
    String title = schedule?.title ?? "";
    String frequency = schedule?.frequency ?? "Daily";
    String duration = schedule?.duration ?? "10 mins";
    TimeOfDay selectedTime = schedule != null ? _parseTimeOfDay(schedule.time) : TimeOfDay.now();
    bool smartSkip = schedule?.smartSkip ?? true;
    List<int> selectedMotors = schedule != null ? List.from(schedule.selectedMotors) : [1];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                const SizedBox(height: 20),
                Text(schedule == null ? "Add New Schedule" : "Edit Schedule",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 25),
                TextFormField(
                  initialValue: title,
                  decoration: InputDecoration(
                    labelText: "Schedule Title",
                    hintText: "e.g. Morning Hydration",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF2E7D32)),
                  ),
                  onChanged: (val) => title = val,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFF2E7D32)),
                  ),
                  title: const Text("Watering Time", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatTimeOfDay(selectedTime),
                      style: const TextStyle(fontSize: 18, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  trailing: TextButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context, 
                        initialTime: selectedTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF2E7D32),
                                onPrimary: Colors.white,
                                onSurface: Color(0xFF1A1A1A),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setModalState(() => selectedTime = picked);
                    },
                    child: const Text("Pick Time", style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Select Motors", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(8, (i) {
                    int motorNum = i + 1;
                    bool isSelected = selectedMotors.contains(motorNum);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            if (selectedMotors.length > 1) {
                              selectedMotors.remove(motorNum);
                            }
                          } else {
                            selectedMotors.add(motorNum);
                            selectedMotors.sort();
                          }
                        });
                      },
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "$motorNum",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: frequency,
                        decoration: InputDecoration(labelText: "Frequency", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                        items: ["Daily", "Weekly", "Mon-Wed-Fri", "Weekends"]
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) => setModalState(() => frequency = val!),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: duration,
                        decoration: InputDecoration(labelText: "Duration", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                        items: ["5 mins", "10 mins", "15 mins", "20 mins", "30 mins"]
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (val) => setModalState(() => duration = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Smart Skip", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Skip watering if rain is predicted"),
                  value: smartSkip,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF2E7D32),
                  onChanged: (val) => setModalState(() => smartSkip = val),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (title.isEmpty) title = "Watering Task";
                      setState(() {
                        final newSchedule = WateringSchedule(
                          time: _formatTimeOfDay(selectedTime),
                          title: title,
                          frequency: frequency,
                          duration: duration,
                          isEnabled: schedule?.isEnabled ?? true,
                          smartSkip: smartSkip,
                          selectedMotors: selectedMotors,
                        );

                        if (index == null) {
                          schedules.add(newSchedule);
                        } else {
                          schedules[index] = newSchedule;
                        }
                      });
                      _saveSchedules();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    child: Text(schedule == null ? "Add Schedule" : "Update Schedule",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteSchedule(int index) {
    setState(() {
      schedules.removeAt(index);
    });
    _saveSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Column(
        children: [
          _buildHeaderContent(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
                : schedules.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
                        itemCount: schedules.length,
                        itemBuilder: (context, index) {
                          return _buildScheduleCard(schedules[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleSheet(),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("New Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No schedules set", style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("Tap 'New Schedule' to get started", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHeaderContent() {
    return BuildHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 15),
              const Text(
                "Irrigation",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Scheduler",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(WateringSchedule schedule, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule.time,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Switch.adaptive(
                      value: schedule.isEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF2E7D32),
                      onChanged: (val) {
                        setState(() {
                          schedule.isEnabled = val;
                        });
                        _saveSchedules();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _truncateText(schedule.title, 20),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    if (schedule.smartSkip) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_queue_rounded, size: 12, color: Colors.blueAccent),
                            SizedBox(width: 4),
                            Text("Smart Skip", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 15,
                  runSpacing: 10,
                  children: [
                    _buildInfoBadge(Icons.calendar_today_rounded, schedule.frequency),
                    _buildInfoBadge(Icons.timer_outlined, schedule.duration),
                    _buildInfoBadge(Icons.developer_board, "Motors: ${schedule.selectedMotors.join(', ')}"),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionButton(
                  onPressed: () => _showScheduleSheet(schedule: schedule, index: index),
                  icon: Icons.edit_outlined,
                  label: "Edit",
                  color: Colors.grey[600]!,
                ),
                const SizedBox(width: 15),
                _actionButton(
                  onPressed: () => _deleteSchedule(index),
                  icon: Icons.delete_outline_rounded,
                  label: "Delete",
                  color: Colors.red[400]!,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
