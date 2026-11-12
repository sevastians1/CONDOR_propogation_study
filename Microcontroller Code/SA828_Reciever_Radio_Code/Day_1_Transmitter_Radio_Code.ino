#include <Arduino.h>

// --- Pin Definitions ---
#define SA828_TX_PIN    17  // Connect to SA828 RXD (Pin 18)
#define SA828_RX_PIN    16  // Connect to SA828 TXD (Pin 19)
#define SA828_PTT_PIN   4   // Connect to SA828 PTT (Pin 20)
#define SA828_CS_PIN    5   // Connect to SA828 CS  (Pin 23)
#define SA828_SPKEN_PIN 18  // Connect to SA828 SPKEN (Pin 9)
#define ADC_PIN         34  // Analog Input Pin (ADC1_CH6)

HardwareSerial RadioSerial(2);

void sendCommand(const String &cmd) {
  Serial.print("[ESP32 -> SA828]: ");
  Serial.print(cmd);
  RadioSerial.print(cmd);
}

void readResponse() {
  delay(200); // Wait for SA828 to process and reply
  if (RadioSerial.available()) {
    Serial.print("[SA828 -> ESP32]: ");
    while (RadioSerial.available()) {
      char c = RadioSerial.read();
      Serial.write(c);
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000); // Allow serial monitor to settle

  // Initialize Hardware Serial 2 at 9600 8N1
  RadioSerial.begin(9600, SERIAL_8N1, SA828_RX_PIN, SA828_TX_PIN);

  // Set GPIO outputs
  pinMode(SA828_PTT_PIN, OUTPUT);
  digitalWrite(SA828_PTT_PIN, HIGH); // HIGH = Receive / Listen Mode

  pinMode(SA828_CS_PIN, OUTPUT);
  digitalWrite(SA828_CS_PIN, HIGH);  // HIGH = Normal Active Mode

  pinMode(SA828_SPKEN_PIN, INPUT);   // RF Carrier Detection Input Pin
  
  // Set GPIO 34 as Analog Input (Default 12-bit resolution: 0 - 4095)
  pinMode(ADC_PIN, INPUT);
  analogReadResolution(12);

  delay(500); // Allow module power to stabilize

  Serial.println("\n==========================================");
  Serial.println("  SA828 Receiver & ADC Sampler (162.550 MHz)");
  Serial.println("==========================================");

  // 1. Query Version
  sendCommand("AAFAA\r\n");
  readResponse();

  // 2. Program 162.5500 MHz across channels (NOAA Channel 1)
  String configCmd = "AAFA3";
  for (int i = 0; i < 16; i++) {
    configCmd += "162.5500,162.5500,";
  }
  configCmd += "000,000,0\r\n"; // Squelch level 1

  sendCommand(configCmd);
  readResponse();

  Serial.println("\n[STATUS] Configuration active. Listening and sampling ADC...\n");
}

bool lastCarrierState = false;

void loop() {
  // 1. Read Carrier State
  bool carrierDetected = digitalRead(SA828_SPKEN_PIN);

  // 2. Sample the ADC Pin (GPIO 34)
  int rawAdc = analogRead(ADC_PIN);

  
  float voltage = (rawAdc / 4095.0) * 3.3; // Convert raw reading to Volts
/*
  // Handle Carrier State Changes
  if (carrierDetected && !lastCarrierState) {
    Serial.printf(">>> [RF CARRIER DETECTED] Signal active! Raw ADC: %d (%.2fV)\n", rawAdc, voltage);
    lastCarrierState = true;
  } else if (!carrierDetected && lastCarrierState) {
    Serial.printf("<<< [CARRIER LOST] Channel clear. Raw ADC: %d (%.2fV)\n", rawAdc, voltage);
    lastCarrierState = false;
  }
  */

  // Optional: Output ADC samples continuously while carrier is active
  if (carrierDetected) {
    Serial.printf("[ADC Sample]: %d | Voltage: %.2fV\n", rawAdc, voltage);
  }

  // Check for serial input from SA828
  if (RadioSerial.available()) {
    readResponse();
  }

  delay(50);
}