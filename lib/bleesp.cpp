/*
  ESP32 BLE Motor Control Test
  Simple Bluetooth-only motor control for testing
  - No WiFi complications
  - No web interface
  - Just BLE motor control
  - Perfect for Flutter app testing
*/

#include <NimBLEDevice.h>
#include <ArduinoJson.h>

// Motor Configuration - Matching your hardware
const int NUM_MOTORS = 9;
const int MOTOR_PINS[NUM_MOTORS] = {19, 25, 26, 18, 2, 27, 22, 23, 5};  // Motor 4 = GPIO 2

// BLE Configuration
#define BLE_SERVICE_UUID "12345678-1234-1234-1234-1234567890ab"
#define BLE_CTRL_CHAR_UUID "12345678-1234-1234-1234-1234567890ac"
#define BLE_RESP_CHAR_UUID "12345678-1234-1234-1234-1234567890ad"

// Global Variables
bool motorStates[NUM_MOTORS] = {false};
NimBLEServer* pBLEServer = nullptr;
NimBLECharacteristic* pControlChar = nullptr;
NimBLECharacteristic* pResponseChar = nullptr;
bool deviceConnected = false;
bool newCommand = false;
String pendingCommand = "";

// BLE Server Callbacks
class MyServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer* pServer) {
        deviceConnected = true;
        Serial.println("=== BLE CLIENT CONNECTED ===");
        Serial.println("Connected clients: " + String(pServer->getConnectedCount()));
    }

    void onDisconnect(NimBLEServer* pServer) {
        deviceConnected = false;
        Serial.println("=== BLE CLIENT DISCONNECTED ===");
        Serial.println("Remaining clients: " + String(pServer->getConnectedCount()));

        // Restart advertising
        NimBLEDevice::startAdvertising();
        Serial.println("Advertising restarted");
    }
};

// BLE Control Callback
class MyControlCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        String command = pCharacteristic->getValue().c_str();

        if (command.length() > 0) {
            pendingCommand = command;
            newCommand = true;
            Serial.println("Command received: " + command);
        }
    }
};

// Process Motor Commands
String processCommand(String command) {
    command.trim();
    command.toUpperCase();

    JsonDocument doc;
    String response = "";

    Serial.println("Processing command: " + command);

    if (command.startsWith("ON:")) {
        String zoneStr = command.substring(3);

        if (zoneStr == "ALL") {
            // Turn all motors ON
            for (int i = 0; i < NUM_MOTORS; i++) {
                motorStates[i] = true;
                digitalWrite(MOTOR_PINS[i], HIGH);  // HIGH = ON for testing
            }

            doc["action"] = "ALL_ON";
            doc["status"] = "ok";
            Serial.println("All motors turned ON");

        } else {
            int zone = zoneStr.toInt();

            if (zone >= 0 && zone < NUM_MOTORS) {
                motorStates[zone] = true;
                digitalWrite(MOTOR_PINS[zone], HIGH);  // HIGH = ON for testing

                doc["zone"] = zone;
                doc["state"] = "ON";
                doc["status"] = "ok";

                if (zone == 4) {
                    Serial.println("=== MOTOR 4 HARDWARE TEST ===");
                    Serial.println("Motor " + String(zone) + " ON - GPIO " + String(MOTOR_PINS[zone]));
                    Serial.println("Check your hardware - Motor 4 should be active!");
                    Serial.println("============================");
                } else {
                    Serial.println("Motor " + String(zone) + " ON - GPIO " + String(MOTOR_PINS[zone]));
                }

            } else {
                doc["status"] = "error";
                doc["message"] = "Invalid zone number (0-" + String(NUM_MOTORS-1) + ")";
                Serial.println("ERROR: Invalid zone " + String(zone));
            }
        }
    }
    else if (command.startsWith("OFF:")) {
        String zoneStr = command.substring(4);

        if (zoneStr == "ALL") {
            // Turn all motors OFF
            for (int i = 0; i < NUM_MOTORS; i++) {
                motorStates[i] = false;
                digitalWrite(MOTOR_PINS[i], LOW);  // LOW = OFF for testing
            }

            doc["action"] = "ALL_OFF";
            doc["status"] = "ok";
            Serial.println("All motors turned OFF");

        } else {
            int zone = zoneStr.toInt();

            if (zone >= 0 && zone < NUM_MOTORS) {
                motorStates[zone] = false;
                digitalWrite(MOTOR_PINS[zone], LOW);  // LOW = OFF for testing

                doc["zone"] = zone;
                doc["state"] = "OFF";
                doc["status"] = "ok";

                if (zone == 4) {
                    Serial.println("=== MOTOR 4 HARDWARE TEST ===");
                    Serial.println("Motor " + String(zone) + " OFF - GPIO " + String(MOTOR_PINS[zone]));
                    Serial.println("Check your hardware - Motor 4 should be inactive!");
                    Serial.println("============================");
                } else {
                    Serial.println("Motor " + String(zone) + " OFF - GPIO " + String(MOTOR_PINS[zone]));
                }

            } else {
                doc["status"] = "error";
                doc["message"] = "Invalid zone number (0-" + String(NUM_MOTORS-1) + ")";
                Serial.println("ERROR: Invalid zone " + String(zone));
            }
        }
    }
    else if (command == "STATUS") {
        // Return status of all motors
        JsonArray motors = doc.createNestedArray("motors");

        for (int i = 0; i < NUM_MOTORS; i++) {
            JsonObject motorObj = motors.createNestedObject();
            motorObj["id"] = i;
            motorObj["state"] = motorStates[i] ? "ON" : "OFF";
            motorObj["gpio"] = MOTOR_PINS[i];
        }

        doc["connected"] = deviceConnected;
        doc["status"] = "ok";
        Serial.println("Status requested");

    }
    else {
        doc["status"] = "error";
        doc["message"] = "Unknown command. Use ON:0, OFF:0, ON:ALL, OFF:ALL, or STATUS";
        Serial.println("ERROR: Unknown command: " + command);
    }

    serializeJson(doc, response);
    return response;
}

// Initialize BLE
void initBLE() {
    Serial.println("=== INITIALIZING BLE ===");

    // Initialize NimBLE
    NimBLEDevice::init("ESP32_Motor_Test");
    NimBLEDevice::setMTU(512);
    NimBLEDevice::setPower(ESP_PWR_LVL_P6);  // Medium power

    Serial.println("Device Name: ESP32_Motor_Test");
    Serial.println("MTU Size: 512 bytes");
    Serial.println("Power Level: Medium (P6)");

    // Create BLE Server
    pBLEServer = NimBLEDevice::createServer();

    // Register callbacks
    static MyServerCallbacks serverCallbacks;
    pBLEServer->setCallbacks(&serverCallbacks);

    // Create BLE Service
    NimBLEService* pService = pBLEServer->createService(BLE_SERVICE_UUID);
    Serial.println("Service created: " + String(BLE_SERVICE_UUID));

    // Create Control Characteristic (WRITE only)
    pControlChar = pService->createCharacteristic(
            BLE_CTRL_CHAR_UUID,
            NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE
    );

    // Create Response Characteristic (NOTIFY only)
    pResponseChar = pService->createCharacteristic(
            BLE_RESP_CHAR_UUID,
            NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );

    // Set control callback
    static MyControlCallbacks controlCallbacks;
    pControlChar->setCallbacks(&controlCallbacks);

    // Start service
    pService->start();

    // Setup advertising
    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    NimBLEUUID serviceUUID(BLE_SERVICE_UUID);
    pAdvertising->addServiceUUID(serviceUUID);
    pAdvertising->setName("ESP32_Motor_Test");

    // Set advertising intervals
    pAdvertising->setMinInterval(160);  // 100ms
    pAdvertising->setMaxInterval(400);  // 250ms

    // Start advertising
    bool started = NimBLEDevice::startAdvertising();

    if (started) {
        Serial.println("=== BLE ADVERTISING STARTED ===");
        Serial.println("Device: ESP32_Motor_Test");
        Serial.println("Service: " + String(BLE_SERVICE_UUID));
        Serial.println("Control UUID: " + String(BLE_CTRL_CHAR_UUID));
        Serial.println("Response UUID: " + String(BLE_RESP_CHAR_UUID));
        Serial.println("=== READY FOR CONNECTION ===");
    } else {
        Serial.println("ERROR: BLE advertising failed!");
    }
}

void setup() {
    Serial.begin(115200);
    Serial.println("\n=== ESP32 BLE MOTOR CONTROL TEST ===");
    Serial.println("Simple Bluetooth-only motor control");
    Serial.println("Commands: ON:4, OFF:4, ON:ALL, OFF:ALL, STATUS");
    Serial.println("NOTE: Motor 4 (GPIO 22) is the hardware-connected motor");
    Serial.println("=====================================\n");

    // Initialize motor pins
    for (int i = 0; i < NUM_MOTORS; i++) {
        pinMode(MOTOR_PINS[i], OUTPUT);
        digitalWrite(MOTOR_PINS[i], LOW);  // Start with all motors OFF

        if (i == 4) {
            Serial.println("Motor " + String(i) + " -> GPIO " + String(MOTOR_PINS[i]) + "  <-- HARDWARE CONNECTED");
        } else {
            Serial.println("Motor " + String(i) + " -> GPIO " + String(MOTOR_PINS[i]));
        }
    }

    Serial.println("All motors initialized to OFF state\n");

    // Initialize BLE
    initBLE();

    Serial.println("\n=== SETUP COMPLETE ===");
    Serial.println("Ready for Bluetooth connection!");
    Serial.println("Scan for 'ESP32_Motor_Test' in your Flutter app");
}

void loop() {
    // Process pending commands
    if (newCommand && pendingCommand.length() > 0) {
        String response = processCommand(pendingCommand);

        // Send response via BLE
        if (deviceConnected && pResponseChar) {
            pResponseChar->setValue(response.c_str());
            pResponseChar->notify();
            Serial.println("Response sent: " + response);
        }

        pendingCommand = "";
        newCommand = false;
    }

    // Small delay to prevent overwhelming the BLE stack
    delay(10);
}