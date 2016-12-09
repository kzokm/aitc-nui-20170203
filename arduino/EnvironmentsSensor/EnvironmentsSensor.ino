#define SERIAL_SPEED    9600
#define INTERVAL_MILLIS  500

#include <Wire.h>

// LPS331AP/LPS25H I2C気圧センサー
#include "LPS.h"
LPS lps;

// HDC1000 I2C温度湿度センサー
#include "HDC1000.h"
HDC1000 hdc;

// 照度センサー（NJL7502L）
#define LIGHT_PIN A0


void setup() {
  Serial.begin(SERIAL_SPEED);
  Serial.println("Start");

  Wire.begin();

  if (! lps.init(LPS::device_auto, LPS::sa0_auto)) {
    Serial.println("Failed to autodetect pressure sensor!");
  }
  lps.enableDefault();

  hdc.init();

  pinMode(LIGHT_PIN, INPUT);
}


int seq = 0;

void loop() {
  Serial.print("{\"i\":");
  Serial.print(++seq);

  float pressure = lps.readPressureMillibars();
  Serial.print(",\"p\":");
  Serial.print(pressure);

  float temperature = hdc.getTemperature();
  if (temperature == HDC1000_ERROR_CODE) {
      temperature = lps.readTemperatureC();
  }
  Serial.print(",\"t\":");
  Serial.print(temperature);

  float humidity = hdc.getHumidity();
  if (humidity != HDC1000_ERROR_CODE) {
      Serial.print(",\"h\":");
      Serial.print(humidity);
  }

  Serial.print(",\"l\":");
  Serial.print(analogRead(LIGHT_PIN));

  Serial.println("}");
  delay(INTERVAL_MILLIS);
}
