import 'dart:async';
import 'package:flutter/material.dart';
import '../services/schedule_service.dart';
import '../Widgets/build_header.dart';
import '../Core/theme/app_colors.dart';

//-------------------------------------------------------- ScheduleScreen Class ----------------------------------------------------------
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

//-------------------------------------------------------- _ScheduleScreenState Class ----------------------------------------------------------
class _ScheduleScreenState extends State<ScheduleScreen> {
  final ScheduleService _service = ScheduleService();
  bool _isLoading = false;
  String? _togglingScheduleId;

  @override
    //-------------------------------------------------------- Init State ----------------------------------------------------------
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    // Fetch schedules from Firebase on init
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSchedules());
  }

  @override
    //-------------------------------------------------------- Dispose Method ----------------------------------------------------------
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _service.fetchSchedules();
    } catch (e) {
      _showError("Error: Could not fetch schedules. Check your internet connection.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = tod.minute.toString().padLeft(2, '0');
    return "${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final tod = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      return _formatTimeOfDay(tod);
    } catch (e) {
      return timeStr;
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  String _timeToString(TimeOfDay tod) {
    return "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return "${text.substring(0, maxLength)}..";
  }

  void _showScheduleSheet({WateringSchedule? schedule}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String title = schedule?.title ?? "";
    String frequency = schedule?.frequency ?? "Daily";
    int duration = schedule?.durationInMinutes ?? 10;
    TimeOfDay selectedTime = schedule != null ? _parseTimeString(schedule.time) : TimeOfDay.now();
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
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : AppColors.white,
            borderRadius: const BorderRadius.only(
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
                    decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: const BorderRadius.all(Radius.circular(10))),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(schedule == null ? "Add New Schedule" : "Edit Schedule",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.scheduleTextDark)),
                    if (schedule != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.scheduleDeleteIcon),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(schedule.id);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Set the time and frequency for automated watering. Multiple schedules can be active.",
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: title,
                  decoration: InputDecoration(
                    labelText: "Schedule Title",
                    hintText: "e.g. Morning Hydration",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
                  ),
                  onChanged: (val) => title = val,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.scheduleIconBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                  ),
                  title: const Text("Watering Time", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatTimeOfDay(selectedTime),
                      style: const TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  trailing: TextButton(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context, 
                        initialTime: selectedTime,
                      );
                      if (picked != null) setModalState(() => selectedTime = picked);
                    },
                    child: const Text("Pick Time", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text("Select Plants (Main Motor is always included)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text("$motorNum", style: TextStyle(color: isSelected ? AppColors.white : (isDark ? Colors.white70 : AppColors.black87), fontWeight: FontWeight.bold)),
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
                            initialValue: frequency,
                        decoration: InputDecoration(
                          labelText: "Frequency", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        items: ["Daily", "Weekly", "Mon-Wed-Fri", "Weekends"]
                            .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                        onChanged: (val) => setModalState(() => frequency = val!),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                            initialValue: duration,
                        menuMaxHeight: 300,
                        decoration: InputDecoration(
                          labelText: "Duration (min)", 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        items: List.generate(60, (index) => index + 1)
                            .map((d) => DropdownMenuItem(
                                  value: d, 
                                  child: Text("$d min"),
                                ))
                            .toList(),
                        onChanged: (val) => setModalState(() => duration = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                       // Ensure Main Motor (1) is not duplicated
                       final motors = List<int>.from(selectedMotors);
                       if (!motors.contains(1)) motors.insert(0, 1);
                       motors.removeWhere((e) => motors.indexOf(e) != motors.lastIndexOf(e));

                       final newSchedule = WateringSchedule(
                         id: schedule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                         time: _timeToString(selectedTime),
                         title: title.isEmpty ? "Watering Task" : title,
                         frequency: frequency,
                         durationInMinutes: duration,
                         isEnabled: schedule?.isEnabled ?? true,
                         selectedMotors: motors,
                       );

                      try {
                         setState(() => _isLoading = true);
                         if (schedule == null) {
                           await _service.addSchedule(newSchedule);
                           _showSuccess("Schedule added and synced");
                         } else {
                           await _service.updateSchedule(newSchedule);
                           _showSuccess("Schedule updated and synced");
                         }
                         if (mounted) Navigator.pop(context);
                         setState(() => _isLoading = false);
                      } catch (e) {
                        _showError("Failed to save schedule. Check ESP32 connection.");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(schedule == null ? "Add Schedule" : "Update Schedule", style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    //-------------------------------------------------------- Build Method ----------------------------------------------------------
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? null : AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refreshSchedules,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderContent(),
              _isLoading && _service.schedules.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  : _service.schedules.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _service.schedules.length,
                          itemBuilder: (context, index) => _buildScheduleCard(_service.schedules[index]),
                        ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.white),
        label: const Text("New Schedule", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: AppColors.scheduleEmptyIcon),
            const SizedBox(height: 16),
            Text("No schedules set", style: TextStyle(color: AppColors.scheduleSubtext, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text("Tap 'New Schedule' to get started", style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _refreshSchedules,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text("Sync Now", style: TextStyle(color: AppColors.primary)),
            )
          ],
        ),
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
                     color: AppColors.white.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 18),
                ),
              ),
              const SizedBox(width: 15),
              const Text("Watering Schedule", style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isLoading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 5),
          const Text("Automate irrigation via Firebase & Device", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(WateringSchedule schedule) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white24, width: 1) : null,
        boxShadow: [BoxShadow(color: AppColors.scheduleShadow, blurRadius: 10, offset: const Offset(0, 4))],
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
                      decoration: BoxDecoration(color: AppColors.scheduleIconBg, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatTimeString(schedule.time), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(schedule.frequency, style: TextStyle(color: AppColors.scheduleSubtext, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                _togglingScheduleId == schedule.id
                    ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch.adaptive(
                        value: schedule.isEnabled,
                                                                  activeThumbColor: AppColors.primary,
                        onChanged: (val) async {
                          setState(() => _togglingScheduleId = schedule.id);
                          try {
                            await _service.toggleSchedule(schedule.id, val);
                            _showSuccess(val ? "Schedule enabled & synced" : "Schedule disabled");
                          } catch (e) {
                            _showError("Failed to toggle schedule. Check ESP32.");
                          }
                          setState(() => _togglingScheduleId = null);
                        },
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
                           Icon(Icons.timer_outlined, size: 14, color: AppColors.grey.withAlpha((0.5 * 255).toInt())),
                          const SizedBox(width: 4),
                           Text("${schedule.durationInMinutes} min", style: TextStyle(color: AppColors.grey.withAlpha((0.5 * 255).toInt()))),
                          const SizedBox(width: 12),
                           Icon(Icons.settings_input_component_rounded, size: 14, color: AppColors.grey.withAlpha((0.5 * 255).toInt())),
                          const SizedBox(width: 4),
                           Text("${schedule.selectedMotors.length} Plants", style: TextStyle(color: AppColors.grey.withAlpha((0.5 * 255).toInt()))),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, color: AppColors.primary), onPressed: () => _showScheduleSheet(schedule: schedule)),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.scheduleDeleteIcon), onPressed: () => _showDeleteConfirmation(schedule.id)),
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
        content: const Text("Are you sure? This will remove the schedule from Firebase."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async { 
              Navigator.pop(context);
              try {
                await _service.deleteSchedule(id); 
                _showSuccess("Schedule deleted");
              } catch (e) {
                _showError("Failed to delete schedule.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.scheduleDeleteIcon),
            child: const Text("DELETE", style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}
