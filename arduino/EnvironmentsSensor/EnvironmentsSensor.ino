#include <Wire.h>

// LPS331 I2C気圧センサー
#include <LPS331.h>
LPS331 lps;

// DHT11 デジタル温湿度センサー
#include "DHT11.h"
#define DHT11_PIN 13
DHT11 dht(DHT11_PIN);

// AS-SS アナログ音量センサー
#define SS_PIN A0

// 風速センサー
#define WIND_PIN A1

// 照度センサー（CdS）
#define LIGHT_PIN A2

#define SERIAL_SPEED 115200
#define INTERVAL_MILLIS 500


void setup() {
  Serial.begin(SERIAL_SPEED);
  Wire.begin();

  if (!lps.init()) {
    Serial.println("Failed to autodetect pressure sensor!");
    while (1);
  }

  lps.enableDefault();

  pinMode(SS_PIN, INPUT);
  pinMode(WIND_PIN, INPUT);
}


int seq = 0;

void loop() {
  Serial.print("{\"i\":");
  Serial.print(++seq);

  float pressure = lps.readPressureMillibars();
  float altitude = lps.pressureToAltitudeMeters(pressure);
  float temperature = lps.readTemperatureC();

  Serial.print(",\"p\":");
  Serial.print(pressure);

  Serial.print(",\"a\":");
  Serial.print(altitude);

  Serial.print(",\"t\":");
  Serial.print(temperature);

  if (dht.read()) {
    Serial.print(",\"h\":");
    Serial.print(dht.humidity);
  }

  Serial.print(",\"s\":");
  Serial.print(analogRead(SS_PIN));

  Serial.print(",\"w\":");
  Serial.print(analogRead(WIND_PIN));

  Serial.print(",\"l\":");
  Serial.print(analogRead(LIGHT_PIN));

  Serial.println("}");
  delay(INTERVAL_MILLIS);
}
