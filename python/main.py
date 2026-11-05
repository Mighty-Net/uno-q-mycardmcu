
from enum import IntEnum

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, StrictBool
from arduino.router_bridge import Bridge

app = FastAPI()


class LedRequest(BaseModel):
    on: StrictBool


class LedPattern(IntEnum):
    standby = 1
    detected = 2
    recognizing = 3
    success = 4
    failure = 5


class PatternRequest(BaseModel):
    pattern: LedPattern


def call_mcu(function, value):
    bridge = Bridge()

    try:
        bridge.connect(timeout=5)
        bridge.call(function, value, timeout=5)

    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"MCU Bridge error: {e}"
        )

    finally:
        bridge.disconnect()


# 全部亮／滅
@app.post("/led")
def set_led(request: LedRequest):
    call_mcu("set_led", request.on)

    return {
        "success": True,
        "on": request.on
    }


# 新增：切換 LED Pattern
@app.post("/pattern")
def set_led_pattern(request: PatternRequest):
    call_mcu("set_led_pattern", int(request.pattern))

    return {
        "success": True,
        "pattern": request.pattern.name
    }
