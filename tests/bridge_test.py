"""UNO Q Bridge RPC / LED Matrix smoke test; requires flashed sketch with set_led(bool)."""
import argparse
import sys
import time
from arduino.router_bridge import Bridge


def main():
    parser = argparse.ArgumentParser(description="UNO Q MCU Bridge LED diagnostic")
    parser.add_argument("--count", type=int, default=3, help="blink cycles (default: 3)")
    args = parser.parse_args()
    if args.count < 1:
        parser.error("--count must be >= 1")

    bridge = Bridge()
    print("[TEST] Connecting to Arduino Router", flush=True)
    try:
        if not bridge.connect(timeout=5):
            raise RuntimeError("Router connection timed out")
        print("[PASS] Router connected", flush=True)
        for i in range(args.count):
            print(f"[TEST] LED ON ({i + 1}/{args.count})", flush=True)
            bridge.call("set_led", True, timeout=5)
            time.sleep(0.5)
            print("[TEST] LED OFF", flush=True)
            bridge.call("set_led", False, timeout=5)
            time.sleep(0.5)
        print("[PASS] RPC requests completed; visually confirm LED blinked", flush=True)
    except Exception as exc:
        print(f"[FAIL] {type(exc).__name__}: {exc}", file=sys.stderr, flush=True)
        return 1
    finally:
        bridge.disconnect()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
