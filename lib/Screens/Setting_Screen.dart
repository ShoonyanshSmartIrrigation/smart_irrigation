import 'package:flutter/material.dart';
import '../Routes/app_Routes.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  int minMoisture = 30;
  int maxMoisture = 70;
  int timerMinutes = 5;
  String esp32Ip = "192.168.1.100";

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: ListView(
        children: [

          // 🌱 Min Moisture
          ListTile(
            title: Text("Minimum Moisture"),
            subtitle: Text("$minMoisture%"),
            onTap: () => showMoistureDialog(
              "Set Minimum Moisture",
              minMoisture,
              0,
              maxMoisture - 1,
                  (value) {
                setState(() => minMoisture = value);
              },
            ),
          ),

          // 🌱 Max Moisture
          ListTile(
            title: Text("Maximum Moisture"),
            subtitle: Text("$maxMoisture%"),
            onTap: () => showMoistureDialog(
              "Set Maximum Moisture",
              maxMoisture,
              minMoisture + 1,
              100,
                  (value) {
                setState(() => maxMoisture = value);
              },
            ),
          ),

          // ⏱ Timer
          ListTile(
            title: Text("Motor Timer"),
            subtitle: Text("$timerMinutes min"),
            onTap: showTimerDialog,
          ),

          // 🌐 ESP32 IP
          ListTile(
            title: Text("ESP32 IP Address"),
            subtitle: Text(esp32Ip),
            onTap: showIpDialog,
          ),

          // ⚙️ ESP32 Config Button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/esp32Config');
              },
              child: Text("ESP32 Configuration"),
            ),
          ),

          // 🚪 Logout
          ListTile(
            title: Text("Logout"),
            leading: Icon(Icons.logout),
            onTap: showLogoutDialog,
          ),
        ],
      ),
    );
  }

  // ---------------- Moisture Dialog ----------------
  void showMoistureDialog(
      String title,
      int currentValue,
      int min,
      int max,
      Function(int) onChanged,
      ) {
    TextEditingController controller =
    TextEditingController(text: currentValue.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "Enter value",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              int? value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onChanged(value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Enter value between $min and $max"),
                  ),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- Timer Dialog ----------------
  void showTimerDialog() {
    List<int> options = [5, 10, 15, 30];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Motor Timer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...options.map((e) => ListTile(
              title: Text("$e minutes"),
              onTap: () {
                setState(() => timerMinutes = e);
                Navigator.pop(context);
              },
            )),

            ListTile(
              title: Text("Custom"),
              onTap: () {
                Navigator.pop(context);
                showCustomTimerDialog();
              },
            )
          ],
        ),
      ),
    );
  }

  // ---------------- Custom Timer ----------------
  void showCustomTimerDialog() {
    TextEditingController controller =
    TextEditingController(text: timerMinutes.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Custom Timer"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter minutes"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              int? value = int.tryParse(controller.text);
              if (value != null && value >= 1 && value <= 120) {
                setState(() => timerMinutes = value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Enter 1–120 minutes"),
                  ),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- IP Dialog ----------------
  void showIpDialog() {
    TextEditingController controller =
    TextEditingController(text: esp32Ip);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("ESP32 IP Address"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "192.168.1.100"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String value = controller.text.trim();
              if (isValidIp(value)) {
                setState(() => esp32Ip = value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Invalid IP Address")),
                );
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // ---------------- IP Validation ----------------
  bool isValidIp(String ip) {
    final regex = RegExp(
        r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$');
    return regex.hasMatch(ip);
  }

  // ---------------- Logout ----------------
  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                    (route) => false,
              );
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }
}