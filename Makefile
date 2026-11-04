
APP_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SKETCH_DIR := $(APP_DIR)/sketch
FQBN := arduino:zephyr:unoq
PYTHON := $(APP_DIR)/.venv/bin/python

SERVICE := mycard-mcu
SERVICE_FILE := $(APP_DIR)/systemd/$(SERVICE).service

PROXY_SERVICE := mycard-mcu-proxy
PROXY_SERVICE_FILE := $(APP_DIR)/systemd/$(PROXY_SERVICE).service
RUN_DIR := $(abspath $(APP_DIR)/../../runtime)

SERVICES := $(SERVICE) $(PROXY_SERVICE)

.PHONY: help setup build install test status \
        service-install start stop restart logs service-status

help:
	@printf 'UNO Q MCU 指令：\n'
	@printf '  make setup            安裝 Python Bridge/API 環境\n'
	@printf '  make build            編譯 MCU Sketch（不燒錄）\n'
	@printf '  make install          編譯並燒錄 MCU Sketch\n'
	@printf '  make test             測試 Bridge RPC 與 LED Matrix 閃爍\n'
	@printf '  make status           檢查 Router 服務與 Socket\n'
	@printf '  make service-install  安裝並啟用 MCU API 與 Proxy 服務\n'
	@printf '  make start            啟動 MCU API 與 Proxy\n'
	@printf '  make stop             停止 MCU API 與 Proxy\n'
	@printf '  make restart          重新啟動 MCU API 與 Proxy\n'
	@printf '  make logs             查看 MCU API 與 Proxy 即時日誌\n'
	@printf '  make service-status   查看 MCU API 與 Proxy 服務狀態\n'

setup:
	bash $(APP_DIR)/setup.sh

build:
	arduino-cli compile --fqbn $(FQBN) $(SKETCH_DIR)

install:
	arduino-cli compile --fqbn $(FQBN) --upload $(SKETCH_DIR)

test:
	@test -x "$(PYTHON)" || (echo '尚未安裝 Python 環境，請先執行 make setup' >&2; exit 1)
	$(PYTHON) $(APP_DIR)/tests/bridge_test.py

status:
	@systemctl is-active arduino-router
	@ls -l /var/run/arduino-router.sock
	@arduino-cli board list

service-install:
	@command -v socat >/dev/null 2>&1 || { echo "[ERROR] 請先安裝 socat"; exit 1; }
	@mkdir -p "$(RUN_DIR)"
	@sudo systemctl stop $(PROXY_SERVICE) 2>/dev/null || true

	@sed 's|__APP_DIR__|$(APP_DIR)|g' $(SERVICE_FILE) | \
		sudo tee /etc/systemd/system/$(SERVICE).service > /dev/null

	@sed \
		-e 's|__APP_DIR__|$(APP_DIR)|g' \
		-e 's|__RUN_DIR__|$(RUN_DIR)|g' \
		$(PROXY_SERVICE_FILE) | \
		sudo tee /etc/systemd/system/$(PROXY_SERVICE).service > /dev/null

	sudo systemctl daemon-reload
	sudo systemctl enable $(SERVICES)
	sudo systemctl restart $(SERVICES)

start:
	sudo systemctl start $(SERVICES)

stop:
	sudo systemctl stop $(SERVICES)

restart:
	sudo systemctl restart $(SERVICES)

logs:
	journalctl -u $(SERVICE) -u $(PROXY_SERVICE) -f

service-status:
	systemctl status $(SERVICES) --no-pager