
#include <Arduino_LED_Matrix.h>
#include <Arduino_RouterBridge.h>
#include "LedPatterns.h"

Arduino_LED_Matrix matrix;
uint8_t pixels[104] = {0};

// LED 顯示模式
enum LedMode {
    LED_MANUAL,
    LED_STANDBY,
    LED_DETECTED,
    LED_RECOGNIZING,
    LED_SUCCESS,
    LED_FAILURE
};

volatile LedMode currentMode = LED_STANDBY;

const unsigned long STANDBY_INTERVAL = 800;
unsigned long lastFrameTime = 0;
bool standbyFrame = false;

// 顯示指定 Pattern
void drawPattern(LedPatterns::Pattern pattern) {
    // memcpy(pixels, LedPatterns::get(pattern), sizeof(pixels));

    // 顯示指定 Pattern（旋轉 180 度）
    const auto& source = LedPatterns::get(pattern);
    for (int row = 0; row < 8; row++) { 
        for (int col = 0; col < 13; col++) {
            pixels[row * 13 + col] = source[7 - row][12 - col];
        }
    }

    matrix.draw(pixels);
}

// LED 全亮／全滅
void set_led(bool on) {
    currentMode = LED_MANUAL;
    memset(pixels, on ? 1 : 0, sizeof(pixels));
    matrix.draw(pixels);
}

// 切換 LED Pattern
void set_led_pattern(int mode) {
    if (mode < LED_STANDBY || mode > LED_FAILURE) {
        return;
    }

    currentMode = static_cast<LedMode>(mode);

    switch (currentMode) {
        case LED_STANDBY:
            standbyFrame = false;
            lastFrameTime = millis();
            drawPattern(LedPatterns::Pattern::Standby1);
            break;

        case LED_DETECTED:
            drawPattern(LedPatterns::Pattern::Detected);
            break;

        case LED_RECOGNIZING:
            drawPattern(LedPatterns::Pattern::Recognizing);
            break;

        case LED_SUCCESS:
            drawPattern(LedPatterns::Pattern::Success);
            break;

        case LED_FAILURE:
            drawPattern(LedPatterns::Pattern::Failure);
            break;

        default:
            break;
    }
}

void setup() {
    matrix.begin();
    matrix.setGrayscaleBits(1);

    // 開機預設待機
    set_led_pattern(LED_STANDBY);

    Bridge.begin();
    Bridge.provide_safe("set_led", set_led);
    Bridge.provide_safe("set_led_pattern", set_led_pattern);
}

void loop() {
    if (currentMode != LED_STANDBY) {
        return;
    }

    unsigned long now = millis();

    if (now - lastFrameTime >= STANDBY_INTERVAL) {
        lastFrameTime = now;
        standbyFrame = !standbyFrame;

        drawPattern(
            standbyFrame
                ? LedPatterns::Pattern::Standby2
                : LedPatterns::Pattern::Standby1
        );
    }
}
