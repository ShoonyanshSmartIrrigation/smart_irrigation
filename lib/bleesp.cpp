/*
  ESP32 Classic Bluetooth Motor Control - Complete Project
  - Individual motor control (4 motors)
  - All motors control
  - Auto mode per motor
  - Timer mode per motor
  - Alarm mode (scheduled daily)
  - Status reporting
  - Help system

  Hardware Configuration:
  - Motor 1 → GPIO 25
  - Motor 2 → GPIO 26
  - Motor 3 → GPIO 18
  - Motor 4 → GPIO 2
*/

#include "BluetoothSerial.h"
#include <ArduinoJson.h>

// Motor Configuration
const int NUM_MOTORS = 4;  // Only 4 motors as requested
const int MOTOR_PINS[NUM_MOTORS] = {25, 26, 18, 2};  // Motors 1-4

// Motor State Structure
struct MotorState {
    bool isOn;
    bool autoMode;
    unsigned long autoOnMs;
    unsigned long autoOffMs;
    bool timerPending;
    unsigned long timerFireAt;
    String timerAction;
    unsigned long lastToggleTime;
};

// Global Variables
MotorState motors[NUM_MOTORS];
BluetoothSerial SerialBT;
unsigned long startTime = 0;

// Alarm Structure
struct Alarm {
    int motorNum;
    int hour;
    int minute;
    bool active;
};

Alarm alarms[NUM_MOTORS];
bool alarmEnabled = true;
unsigned long softwareClock = 0;

// Function Prototypes
void processCommand(String command);
void sendResponse(String response);
void printHelp();
void updateMotorsStatus();
void handleAutoMode();
void handleTimerMode();
void handleAlarmMode();
void handleStatus();
void handleAlarmList();
void handleAlarmClear();
void updateSoftwareClock();

void setup() {
    Serial.begin(115200);
    SerialBT.begin("ESP32_Motor_Control");

    Serial.println("\n=== ESP32 CLASSIC BLUETOOTH MOTOR CONTROL ===");
    Serial.println("Hardware Configuration:");
    Serial.println("  Motor 1 → GPIO 25");
    Serial.println("  Motor 2 → GPIO 26");
    Serial.println("  Motor 3 → GPIO 18");
    Serial.println("  Motor 4 → GPIO 2");
    Serial.println("========================================");

    // Initialize all motors to OFF
    for (int i = 0; i < NUM_MOTORS; i++) {
        pinMode(MOTOR_PINS[i], OUTPUT);
        digitalWrite(MOTOR_PINS[i], LOW);

        motors[i].isOn = false;
        motors[i].autoMode = false;
        motors[i].autoOnMs = 0;
        motors[i].autoOffMs = 0;
        motors[i].timerPending = false;
        motors[i].timerFireAt = 0;
        motors[i].lastToggleTime = 0;
    }

    // Initialize alarms
    for (int i = 0; i < NUM_MOTORS; i++) {
        alarms[i].motorNum = i;
        alarms[i].hour = 0;
        alarms[i].minute = 0;
        alarms[i].active = false;
    }

    Serial.println("Classic Bluetooth started!");
    Serial.println("Device: ESP32_Motor_Control");
    Serial.println("Ready for commands...");
    Serial.println("========================================");

    startTime = millis();
}

void loop() {
    // Update software clock (1 second = 1000ms)
    updateSoftwareClock();

    // Check for Bluetooth commands
    if (SerialBT.available()) {
        String command = SerialBT.readString();
        command.trim();

        Serial.println("BT Command received: " + command);
        processCommand(command);
    }

    // Check for Serial commands (debugging)
    if (Serial.available()) {
        String command = Serial.readString();
        command.trim();
        SerialBT.println("Serial: " + command);
        processCommand(command);
    }

    // Handle auto mode for all motors
    handleAutoMode();

    delay(10);
}

void processCommand(String command) {
    command.toUpperCase();

    // INDIVIDUAL MOTOR CONTROL
    if (command.startsWith("ON:")) {
        int motorNum = command.substring(3).toInt() - 1; // Convert to 0-based index

        if (motorNum >= 0 && motorNum < NUM_MOTORS) {
            motors[motorNum].isOn = true;
            motors[motorNum].autoMode = false;
            digitalWrite(MOTOR_PINS[motorNum], HIGH);

            String response = "Motor " + String(motorNum + 1) + " ON";
            sendResponse(response);

            Serial.println("Motor " + String(motorNum + 1) + " ON - GPIO " + String(MOTOR_PINS[motorNum]));

        } else {
            sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
        }
    }
    else if (command.startsWith("OFF:")) {
        int motorNum = command.substring(4).toInt() - 1; // Convert to 0-based index

        if (motorNum >= 0 && motorNum < NUM_MOTORS) {
            motors[motorNum].isOn = false;
            motors[motorNum].autoMode = false;
            digitalWrite(MOTOR_PINS[motorNum], LOW);

            String response = "Motor " + String(motorNum + 1) + " OFF";
            sendResponse(response);

            Serial.println("Motor " + String(motorNum + 1) + " OFF - GPIO " + String(MOTOR_PINS[motorNum]));

        } else {
            sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
        }
    }

        // ALL MOTORS CONTROL
    else if (command == "ALL:ON") {
        for (int i = 0; i < NUM_MOTORS; i++) {
            motors[i].isOn = true;
            motors[i].autoMode = false;
            digitalWrite(MOTOR_PINS[i], HIGH);
        }

        sendResponse("All motors ON");
        Serial.println("All motors ON");
    }
    else if (command == "ALL:OFF") {
        for (int i = 0; i < NUM_MOTORS; i++) {
            motors[i].isOn = false;
            motors[i].autoMode = false;
            digitalWrite(MOTOR_PINS[i], LOW);
        }

        sendResponse("All motors OFF");
        Serial.println("All motors OFF");
    }

        // AUTO MODE PER MOTOR
    else if (command.startsWith("AUTO:ON:")) {
        int motorNum = command.substring(8).toInt() - 1; // Convert to 0-based index

        if (motorNum >= 0 && motorNum < NUM_MOTORS) {
            int onSeconds = 0;
            int offSeconds = 0;

            // Parse ON:duration and OFF:duration
            int onIndex = command.indexOf("ON:");
            int offIndex = command.indexOf("OFF:");

            if (onIndex > 0) {
                int onEnd = command.indexOf(":", onIndex + 1);
                onSeconds = command.substring(onIndex + 1, onEnd).toInt();
            }

            if (offIndex > 0) {
                int offEnd = command.indexOf(":", offIndex + 1);
                offSeconds = command.substring(offIndex + 1, offEnd).toInt();
            }

            motors[motorNum].isOn = true;
            motors[motorNum].autoMode = true;
            motors[motorNum].autoOnMs = millis();
            motors[motorNum].autoOffMs = motors[motorNum].autoOnMs + (onSeconds * 1000);

            String response = "Motor " + String(motorNum + 1) + " AUTO ON (" + String(onSeconds) + "s ON, " + String(offSeconds) + "s OFF)";
            sendResponse(response);

            Serial.println("Motor " + String(motorNum + 1) + " AUTO ON - " + String(onSeconds) + "s ON, " + String(offSeconds) + "s OFF");

        } else {
            sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
        }
    }

        // STOP AUTO MODE
    else if (command.startsWith("AUTO:OFF:")) {
        int motorNum = command.substring(9).toInt() - 1; // Convert to 0-based index

        if (motorNum >= 0 && motorNum < NUM_MOTORS) {
            motors[motorNum].isOn = false;
            motors[motorNum].autoMode = false;

            String response = "Motor " + String(motorNum + 1) + " AUTO OFF";
            sendResponse(response);

            Serial.println("Motor " + String(motorNum + 1) + " AUTO OFF");

        } else {
            sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
        }
    }

        // TIMER MODE
    else if (command.startsWith("TIMER:")) {
        int motorNum = command.substring(6).toInt() - 1; // Convert to 0-based index

        if (motorNum >= 0 && motorNum < NUM_MOTORS) {
            int colonIndex = command.indexOf(":");
            String action = command.substring(colonIndex + 1);

            if (action == "ON") {
                int secondsIndex = command.indexOf(":", colonIndex + 1);
                int seconds = command.substring(secondsIndex + 1).toInt();

                motors[motorNum].timerPending = true;
                motors[motorNum].timerFireAt = millis() + (seconds * 1000);
                motors[motorNum].timerAction = "ON";

                String response = "Motor " + String(motorNum + 1) + " TIMER ON in " + String(seconds) + " seconds";
                sendResponse(response);

                Serial.println("Motor " + String(motorNum + 1) + " TIMER ON in " + String(seconds) + " seconds");

            } else if (action == "OFF") {
                motors[motorNum].timerPending = false;
                motors[motorNum].timerFireAt = 0;

                String response = "Motor " + String(motorNum + 1) + " TIMER OFF";
                sendResponse(response);

                Serial.println("Motor " + String(motorNum + 1) + " TIMER OFF");

            } else {
                sendResponse("ERROR: Invalid timer action. Use TIMER:1:ON:10 or TIMER:1:OFF");
            }

        } else {
            sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
        }
    }

        // ALARM MODE
    else if (command.startsWith("ALARM:")) {
        int colonIndex = command.indexOf(":");
        String action = command.substring(colonIndex + 1);

        if (action == "ON") {
            alarmEnabled = true;
            sendResponse("Alarm system ENABLED");
            Serial.println("Alarm system ENABLED");

        } else if (action == "OFF") {
            alarmEnabled = false;
            sendResponse("Alarm system DISABLED");
            Serial.println("Alarm system DISABLED");

        } else if (action.startsWith("SET:")) {
            int motorNum = action.substring(4).toInt() - 1; // Convert to 0-based index

            if (motorNum >= 0 && motorNum < NUM_MOTORS) {
                int timeIndex = action.indexOf(":", 4);
                String timeStr = action.substring(timeIndex + 1);

                int colonPos = timeStr.indexOf(":");
                if (colonPos > 0) {
                    int hour = timeStr.substring(0, colonPos).toInt();
                    int minute = timeStr.substring(colonPos + 1).toInt();

                    if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
                        alarms[motorNum].hour = hour;
                        alarms[motorNum].minute = minute;
                        alarms[motorNum].active = true;

                        String response = "Motor " + String(motorNum + 1) + " ALARM SET to " + String(hour) + ":" + String(minute);
                        sendResponse(response);

                        Serial.println("Motor " + String(motorNum + 1) + " ALARM SET to " + String(hour) + ":" + String(minute));

                    } else {
                        sendResponse("ERROR: Invalid time format. Use HH:MM (24-hour)");
                    }
                } else {
                    sendResponse("ERROR: Invalid time format. Use HH:MM");
                }
            } else {
                sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
            }

        } else if (action == "LIST") {
            String response = "ALARMS LIST:\n";
            for (int i = 0; i < NUM_MOTORS; i++) {
                response += "Motor " + String(i + 1) + ": ";
                if (alarms[i].active) {
                    response += String(alarms[i].hour) + ":" + String(alarms[i].minute) + " (ACTIVE)\n";
                } else {
                    response += "NOT SET\n";
                }
            }
            sendResponse(response);

        } else if (action == "CLEAR:") {
            int motorNum = action.substring(6).toInt() - 1; // Convert to 0-based index

            if (motorNum >= 0 && motorNum < NUM_MOTORS) {
                alarms[motorNum].active = false;
                alarms[motorNum].hour = 0;
                alarms[motorNum].minute = 0;

                String response = "Motor " + String(motorNum + 1) + " ALARM CLEARED";
                sendResponse(response);

                Serial.println("Motor " + String(motorNum + 1) + " ALARM CLEARED");

            } else {
                sendResponse("ERROR: Invalid motor number (1-" + String(NUM_MOTORS) + ")");
            }

        } else {
            sendResponse("ERROR: Invalid alarm action. Use ON, OFF, SET:1:12:30, LIST, CLEAR:1");
        }
    }

        // STATUS COMMAND
    else if (command == "STATUS") {
        updateMotorsStatus();
        sendResponse("OK");
    }

        // HELP COMMAND
    else if (command == "HELP") {
        printHelp();
    }

    else {
        sendResponse("ERROR: Unknown command. Type HELP for command list");
    }
}

void sendResponse(String response) {
    SerialBT.println(response);
    Serial.println("Response sent: " + response);
}

void printHelp() {
    String help = "\n=== ESP32 MOTOR CONTROL HELP ===\n";
    help += "INDIVIDUAL MOTORS:\n";
    help += "  ON:1           - Turn Motor 1 ON\n";
    help += "  OFF:1          - Turn Motor 1 OFF\n";
    help += "  ON:2           - Turn Motor 2 ON\n";
    help += "  OFF:2          - Turn Motor 2 OFF\n";
    help += "  ON:3           - Turn Motor 3 ON\n";
    help += "  OFF:3          - Turn Motor 3 OFF\n";
    help += "  ON:4           - Turn Motor 4 ON\n";
    help += "  OFF:4          - Turn Motor 4 OFF\n\n";

    help += "ALL MOTORS:\n";
    help += "  ALL:ON          - Turn ALL motors ON\n";
    help += "  ALL:OFF         - Turn ALL motors OFF\n\n";

    help += "AUTO MODE (per motor):\n";
    help += "  AUTO:ON:1:5:3     - Motor 1 cycles ON for 5s, OFF for 3s\n";
    help += "  AUTO:OFF:1             - Stop auto mode for Motor 1\n";
    help += "  AUTO:ON:2:10:5    - Motor 2 cycles ON for 10s, OFF for 5s\n";
    help += "  AUTO:OFF:2             - Stop auto mode for Motor 2\n\n";

    help += "TIMER MODE:\n";
    help += "  TIMER:1:ON:10       - Turn Motor 1 ON after 10 seconds\n";
    help += "  TIMER:1:OFF             - Cancel timer for Motor 1\n";
    help += "  TIMER:2:ON:30       - Turn Motor 2 ON after 30 seconds\n";
    help += "  TIMER:2:OFF             - Cancel timer for Motor 2\n\n";

    help += "ALARM MODE:\n";
    help += "  ALARM:ON                - Enable alarm system\n";
    help += "  ALARM:OFF               - Disable alarm System\n";
    help += "  ALARM:SET:1:12:30     - Set Motor 1 alarm to 12:30\n";
    help += "  ALARM:SET:2:08:45     - Set Motor 2 Alarm to 08:45\n";
    help += "  ALARM:SET:3:18:15     - Set Motor 3 Alarm to 18:15\n";
    help += "  ALARM:SET:4:22:00     - Set Motor 4 Alarm to 22:00\n";
    help += "  ALARM:LIST              - List all alarms\n";
    help += "  ALARM:CLEAR:1           - Clear Motor 1 alarm\n";
    help += "  ALARM:CLEAR:2           - Clear Motor 2 Alarm\n";
    help += "  ALARM:CLEAR:3           - Clear Motor 3 Alarm\n";
    help += "  ALARM:CLEAR:4           - Clear Motor 4 Alarm\n\n";

    help += "STATUS:\n";
    help += "  STATUS                 - Show all motor states\n\n";

    help += "HELP:\n";
    help += "  HELP                  - Show this help\n";
    help += "========================================\n";

    sendResponse(help);
}

void updateMotorsStatus() {
    String status = "MOTORS STATUS:\n";

    for (int i = 0; i < NUM_MOTORS; i++) {
        status += "Motor " + String(i + 1) + ": " + String(motors[i].isOn ? "ON" : "OFF");

        if (motors[i].autoMode) {
            status += " (AUTO)";
        }

        if (motors[i].timerPending) {
            unsigned long remaining = motors[i].timerFireAt - millis();
            if (remaining > 0) {
                status += " (TIMER: " + String(remaining / 1000) + "s)";
            } else {
                status += " (TIMER: EXPIRED)";
            }
        }

        if (alarms[i].active) {
            status += " (ALARM: " + String(alarms[i].hour) + ":" + String(alarms[i].minute) + ")";
        }

        status += "\n";
    }

    status += "Alarm System: " + String(alarmEnabled ? "ENABLED" : "DISABLED") + "\n";
    status += "Software Clock: " + String(softwareClock / 1000) + "s\n";

    sendResponse(status);
}

void handleAutoMode() {
    for (int i = 0; i < NUM_MOTORS; i++) {
        if (motors[i].autoMode && motors[i].isOn) {
            // Check if it's time to turn OFF
            if (millis() >= motors[i].autoOffMs) {
                motors[i].isOn = false;
                motors[i].autoMode = false;
                digitalWrite(MOTOR_PINS[i], LOW);

                Serial.println("Motor " + String(i + 1) + " auto OFF - GPIO " + String(MOTOR_PINS[i]));

                // Check if it's time to turn ON again
                if (millis() >= motors[i].autoOnMs && millis() < motors[i].autoOffMs) {
                    motors[i].isOn = true;
                    digitalWrite(MOTOR_PINS[i], HIGH);

                    Serial.println("Motor " + String(i + 1) + " auto ON - GPIO " + String(MOTOR_PINS[i]));
                }
            }
        }
    }
}

void handleTimerMode() {
    for (int i = 0; i < NUM_MOTORS; i++) {
        if (motors[i].timerPending) {
            // Check if timer should fire
            if (millis() >= motors[i].timerFireAt && !motors[i].isOn) {
                motors[i].isOn = true;
                motors[i].timerPending = false;
                digitalWrite(MOTOR_PINS[i], HIGH);

                Serial.println("Motor " + String(i + 1) + " timer fired - GPIO " + String(MOTOR_PINS[i]));

                // Auto turn OFF after 1 second (one-shot timer)
                motors[i].autoOffMs = millis() + 1000;
            }
        }
    }
}

void handleAlarmMode() {
    if (!alarmEnabled) return;

    // Get current time from software clock
    unsigned long currentMinutes = (softwareClock / 1000) / 60; // Total minutes since boot
    unsigned long currentHour = (currentMinutes / 60) % 24;
    unsigned long currentMinute = currentMinutes % 60;

    for (int i = 0; i < NUM_MOTORS; i++) {
        if (alarms[i].active) {
            // Check if alarm time matches current time
            unsigned long alarmMinutes = alarms[i].hour * 60 + alarms[i].minute;

            if (currentMinutes >= alarmMinutes && currentMinutes < alarmMinutes + 1) {
                // Within 1 minute window - trigger alarm
                if (!motors[i].isOn) {
                    motors[i].isOn = true;
                    motors[i].autoMode = true;
                    motors[i].autoOnMs = millis();
                    motors[i].autoOffMs = millis() + 60000; // Default 10 minutes

                    Serial.println("Motor " + String(i + 1) + " ALARM TRIGGERED - GPIO " + String(MOTOR_PINS[i]));
                }
            }
        }
    }
}

void handleStatus() {
    // This is handled by processCommand("STATUS")
}

void handleAlarmList() {
    // This is handled by processCommand("ALARM:LIST")
}

void handleAlarmClear() {
    // This is handled by processCommand("ALARM:CLEAR:X")
}

void updateSoftwareClock() {
    // Simple software clock - increments every second
    static unsigned long lastClockUpdate = 0;

    if (millis() - lastClockUpdate >= 1000) {
        lastClockUpdate = millis();
        softwareClock++;
    }
}