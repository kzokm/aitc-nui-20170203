#ifndef DHT11_H
#define DHT11_H

#include "Arduino.h"

class DHT11 {
  public:
    DHT11(uint8_t pin);
    boolean read();
    double humidity;
    double temperature;
    const char *error;
  private:
    uint8_t _pin;
};

#endif
