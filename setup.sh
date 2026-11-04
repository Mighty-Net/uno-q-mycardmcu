#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

info() { printf '\n[INFO] %s\n' "$*"; }
warn() { printf '\n[WARN] %s\n' "$*" >&2; }
fail() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Linux" ]] || fail "請在 UNO Q 的 Linux 環境執行，不是在 Mac 上執行。"
command -v sudo >/dev/null || fail "找不到 sudo。"
command -v apt-get >/dev/null || fail "此腳本適用 UNO Q 的 Debian/Ubuntu 系統（需要 apt-get）。"

info "檢查必要工具"
missing=()
for cmd in make python3; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if ((${#missing[@]})); then
  info "安裝必要工具：${missing[*]}"
  sudo apt-get update
  sudo apt-get install -y make python3
fi
command -v arduino-cli >/dev/null || fail "找不到 arduino-cli；請先確認 UNO Q 官方 Linux 映像與 Arduino CLI 安裝。"

info "確認 MCU Board Core"
if ! arduino-cli core list | grep -Eq 'arduino:zephyr([[:space:]]|$)'; then
  warn "未在 Arduino CLI 的 core list 找到 arduino:zephyr。"
  warn "請依 Arduino UNO Q 官方文件安裝對應 Board Core，再執行 make build。"
fi

info "建立 Python 虛擬環境"
if [[ ! -x .venv/bin/python ]]; then
  if ! python3 -m venv .venv; then
    warn "建立 venv 失敗，嘗試安裝對應 Python venv 套件。"
    py_ver="$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
    sudo apt-get update
    sudo apt-get install -y "python${py_ver}-venv" || fail "安裝 python${py_ver}-venv 失敗，請檢查系統軟體來源。"
    rm -rf .venv
    python3 -m venv .venv || fail "無法建立虛擬環境。"
  fi
fi
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

info "檢查 Arduino Router"
if ! systemctl is-active --quiet arduino-router; then
  fail "arduino-router 未啟動。請先確認：sudo systemctl status arduino-router"
fi
SOCKET=/var/run/arduino-router.sock
[[ -S "$SOCKET" ]] || fail "找不到 $SOCKET"

info "檢查 Router Socket 權限"
router_group="$(stat -c '%G' "$SOCKET")"
if ! python3 - <<'PY'
import socket
s = socket.socket(socket.AF_UNIX)
try:
    s.settimeout(2)
    s.connect('/var/run/arduino-router.sock')
except OSError:
    raise SystemExit(1)
finally:
    s.close()
PY
then
  if [[ "$router_group" == "arduino-router" ]] && ! id -nG | grep -qw arduino-router; then
    info "目前帳號尚未具備 arduino-router 群組權限，嘗試加入"
    sudo usermod -aG arduino-router "$(id -un)"
    warn "已修改帳號群組。請完全登出 SSH / VS Code Remote SSH 再重新登入，然後執行 make test。"
  else
    warn "Socket 仍無法連線；請檢查 ls -l $SOCKET、id -nG、Router 服務狀態。"
  fi
else
  info "Router Socket 連線成功"
fi

info "安裝準備完成；接下來執行：make install，接著 make test"
