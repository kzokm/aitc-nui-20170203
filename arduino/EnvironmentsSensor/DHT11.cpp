#include "DHT11.h"

DHT11::DHT11(uint8_t pin) {
  _pin = pin;
  pinMode(_pin, INPUT_PULLUP);
}

boolean DHT11::read() {
  error = NULL;
  humidity = temperature = NAN;

  // Request sample
  pinMode(_pin, OUTPUT);
  digitalWrite(_pin, LOW);
  delay(20);

  digitalWrite(_pin, HIGH);
  delayMicroseconds(40);

  pinMode(_pin, INPUT_PULLUP);
  if (digitalRead(_pin) != LOW) {
    error = "Error 1: DHT start condition 1 not met.";
    return false;
  }
  delayMicroseconds(80);

  if(digitalRead(_pin) != HIGH) {
    error = "Error 2: DHT start condition 2 not met.";
    return false;
  }
  delayMicroseconds(80);

  // Read pulse
  byte buffer[5];
  int i;
  for (i = 0; i < 5; i++) {
    byte data = 0;
    int b = 0;
    for (b = 0; b < 8; b++) {
      while (digitalRead(_pin) == LOW);
      delayMicroseconds(30);
      if (digitalRead(_pin) == HIGH) {
        data |= (1 << (7 - b));
      }
      while (digitalRead(_pin) == HIGH);
    }
    buffer[i] = data;
  }

  byte check_sum = buffer[0] + buffer[1] + buffer[2] + buffer[3];
  if(buffer[4] != check_sum) {
    error = "DHT checksum error.";
    return false;
  }

  humidity = buffer[0] + (double)buffer[1] / 100.0;
  temperature = buffer[2] + (double)buffer[3] / 100.0;
  return true;
}
