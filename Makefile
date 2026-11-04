APP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SKETCH_DIR := $(APP_DIR)/sketch
FQBN := arduino:zephyr:unoq
PYTHON := $(APP_DIR)/.venv/bin/python

.PHONY: help setup build install test status

help:
	@printf 'UNO Q MCU 指令：\n'
	@printf '  make setup    安裝 Linux Bridge 測試環境\n'
	@printf '  make build    編譯 MCU Sketch（不燒錄）\n'
	@printf '  make install  編譯並燒錄 MCU Sketch\n'
	@printf '  make test     測試 Bridge RPC 與 LED Matrix 閃爍\n'
	@printf '  make status   檢查 Router 服務與 Socket\n'

setup:
	bash $(APP_DIR)/setup.sh

build:
	arduino-cli compile --fqbn $(FQBN) $(SKETCH_DIR)

install:
	arduino-cli compile --fqbn $(FQBN) --upload $(SKETCH_DIR)

test:
	@test -x "$(PYTHON)" || (echo '尚未安裝 Python 環境，請先執行 bash setup.sh' >&2; exit 1)
	$(PYTHON) $(APP_DIR)/tests/bridge_test.py

status:
	@systemctl is-active arduino-router
	@ls -l /var/run/arduino-router.sock
	@arduino-cli board list
