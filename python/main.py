
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, StrictBool
from arduino.router_bridge import Bridge

app = FastAPI()

class LedRequest(BaseModel):
    on: StrictBool

@app.post("/led")
def set_led(request: LedRequest):
    bridge = Bridge()

    try:
        bridge.connect(timeout=5)
        bridge.call("set_led", request.on, timeout=5)

        return {
            "success": True,
            "on": request.on
        }

    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail=f"MCU Bridge error: {e}"
        )

    finally:
        bridge.disconnect()
