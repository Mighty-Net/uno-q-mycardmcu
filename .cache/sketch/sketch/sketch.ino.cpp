#include <Arduino.h>
#line 1 "/home/arduino/projects/mycard_integrate/src/mcu/sketch/sketch.ino"

#include <Arduino_LED_Matrix.h>
#include <Arduino_RouterBridge.h>

Arduino_LED_Matrix matrix;
uint8_t pixels[104] = {0};

#line 8 "/home/arduino/projects/mycard_integrate/src/mcu/sketch/sketch.ino"
void set_led(bool on);
#line 13 "/home/arduino/projects/mycard_integrate/src/mcu/sketch/sketch.ino"
void setup();
#line 21 "/home/arduino/projects/mycard_integrate/src/mcu/sketch/sketch.ino"
void loop();
#line 8 "/home/arduino/projects/mycard_integrate/src/mcu/sketch/sketch.ino"
void set_led(bool on) {
    memset(pixels, on ? 1 : 0, sizeof(pixels));
    matrix.draw(pixels);
}

void setup() {
    matrix.begin();
    matrix.setGrayscaleBits(1);

    Bridge.begin();
    Bridge.provide_safe("set_led", set_led);
}

void loop() {
}

