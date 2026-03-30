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
  final ScheduleService _service = ScheduleService();
  final PlantService _plantService = PlantService();
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _plantService.init();
    _service.init();
    _service.addListener(_onServiceUpdate);
    _startScheduleChecker();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _startScheduleChecker() {
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndRunSchedules();
    });
  }

  void _checkAndRunSchedules() {
    final now = TimeOfDay.now();
    final nowStr = _formatTimeOfDay(now);

    for (var schedule in _service.schedules) {
      if (schedule.isEnabled && _formatTimeOfDay(TimeOfDay.fromDateTime(schedule.time)) == nowStr) {
        _runSchedule(schedule);
      }
    }
  }

  Future<void> _runSchedule(WateringSchedule schedule) async {
    final plants = _plantService.getPlants();
    
    for (int motorId in schedule.selectedMotors) {
      try {
        final plant = plants.firstWhere((p) => p.id == motorId);
        await _plantService.togglePlantMotor(plant, isOn: true);
      } catch (e) {
        debugPrint("Schedule Error: Plant $motorId not found");
      }
    }

    Timer(Duration(minutes: schedule.durationInMinutes), () async {
      for (int motorId in schedule.selectedMotors) {
        try {
          final plant = plants.firstWhere((p) => p.id == motorId);
          await _plantService.togglePlantMotor(plant, isOn: false);
        } catch (e) {
          debugPrint("Schedule Error: Plant $motorId not found");
        }
      }
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

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return "${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}..";
  }

  void _showScheduleSheet({WateringSchedule? schedule}) {
    String title = schedule?.title ?? "";
    String frequency = schedule?.frequency ?? "Daily";
    int duration = schedule?.durationInMinutes ?? 10;
    TimeOfDay selectedTime = schedule != null ? TimeOfDay.fromDateTime(schedule.time) : TimeOfDay.now();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(schedule == null ? "Add New Schedule" : "Edit Schedule",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    if (schedule != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        onPressed: () {
                          _service.deleteSchedule(schedule.id);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
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
                            if (selectedMotors.length > 1) selectedMotors.remove(motorNum);
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
                        ),
                        child: Center(
                          child: Text("$motorNum", style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
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
                        decoration: const InputDecoration(labelText: "Frequency", border: OutlineInputBorder()),
                        items: ["Daily", "Weekly", "Mon-Wed-Fri", "Weekends"]
                            .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) => setModalState(() => frequency = val!),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: duration,
                        decoration: const InputDecoration(labelText: "Duration (min)", border: OutlineInputBorder()),
                        items: [5, 10, 15, 20, 30].map((d) => DropdownMenuItem(value: d, child: Text("$d min"))).toList(),
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
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) => setModalState(() => smartSkip = val),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      final now = DateTime.now();
                      final DateTime scheduleTime = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                      
                      final newSchedule = WateringSchedule(
                        id: schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                        time: scheduleTime,
                        title: title.isEmpty ? "Watering Task" : title,
                        frequency: frequency,
                        durationInMinutes: duration,
                        isEnabled: schedule?.isEnabled ?? true,
                        smartSkip: smartSkip,
                        selectedMotors: selectedMotors,
                      );

                      if (schedule == null) {
                        _service.addSchedule(newSchedule);
                      } else {
                        _service.updateSchedule(newSchedule);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(schedule == null ? "Add Schedule" : "Update Schedule", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: Column(
        children: [
          _buildHeaderContent(),
          Expanded(
            child: _service.schedules.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: _service.schedules.length,
                    itemBuilder: (context, index) => _buildScheduleCard(_service.schedules[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleSheet(),
        backgroundColor: const Color(0xFF2E7D32),
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
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 15),
              const Text("Watering Schedule", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Automate your irrigation system", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(WateringSchedule schedule) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFF2E7D32), size: 24),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatTimeOfDay(TimeOfDay.fromDateTime(schedule.time)), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(schedule.frequency, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                Switch.adaptive(
                  value: schedule.isEnabled,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (val) => _service.toggleSchedule(schedule.id, val),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_truncateText(schedule.title, 20), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text("${schedule.durationInMinutes} min", style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(width: 12),
                          Icon(Icons.settings_input_component_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text("${schedule.selectedMotors.length} Motors", style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF2E7D32)), onPressed: () => _showScheduleSheet(schedule: schedule)),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: () => _showDeleteConfirmation(schedule.id)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Schedule"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () { _service.deleteSchedule(id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
