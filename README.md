# UNO Q MCU Bridge：安裝、燒錄與測試

本專案讓 **UNO Q 的 Linux** 直接透過 `arduino-router` 呼叫 **STM32 MCU**，測試板上的 **8×13 LED Matrix**。**不需要** Arduino App Lab 的 Python Container，也**不使用** `docker exec`。

> 本專案已在既有 UNO Q 環境驗證：`arduino-cli` 可編譯／燒錄，`arduino-router` Socket 可連線，Python Bridge 可使 LED 閃爍。不同系統映像、Board Core／Library 版本仍可能需要額外安裝，不能保證所有新板子零設定成功。

## 1. 你需要什麼？

- Arduino UNO Q，已能開機並連上 Wi-Fi。
- 在 UNO Q Linux 上操作（可透過 Mac/Windows VS Code Remote SSH）；**不是在 Mac 的本機 Terminal 執行**。
- 有可用的網路與 `sudo` 權限，第一次安裝套件時會使用。
- 已 Clone 或複製本 Git 專案到 UNO Q（以下假設目前就在 `src/mcu/`）。
- **專案內必須有 `sketch/sketch.ino`**，並註冊 `Bridge.provide_safe("set_led", set_led)`。本安裝包不會覆蓋既有 Sketch。

預期檔案：

```text
src/mcu/
├── README.md
├── setup.sh
├── Makefile
├── requirements.txt
├── .gitignore
├── sketch/
│   ├── sketch.ino       # 由你原來的專案保留
│   └── sketch.yaml      # 如果原專案已有，保留
└── tests/
    └── bridge_test.py
```

## 2. 首次安裝：照著做

### 步驟 A：進到專案目錄

在 UNO Q 的 VS Code Remote SSH Terminal 輸入：

```bash
cd ~/projects/mycard_integrate/src/mcu
pwd
```

確認看到的是 UNO Q 上的 `.../src/mcu` 路徑。其他使用者的專案位置不同時，改成自己的實際路徑即可。

### 步驟 B：執行環境安裝

```bash
bash setup.sh
```

腳本會：檢查 `make` / `python3` / `arduino-cli`、視需要安裝 Python `venv`、建立 `.venv`、安裝 Bridge Python 套件、檢查 Router 服務和 Socket；若使用者缺少 Socket 所需的群組權限，會嘗試加入群組。

**如果畫面要求重新登入**：關掉目前的 SSH / VS Code Remote SSH 連線，重新連到 UNO Q。這不是重開板子。重新登入後可執行：

```bash
id -nG
make status
```

### 步驟 C：編譯並燒錄 MCU

```bash
make install
```

這會對 `sketch/` 執行 Arduino CLI 編譯及燒錄。完成後，MCU 執行已燒入的 Sketch；**不需要啟動 Arduino 官方 Python Container**。首次使用也可以先以 `make build` 單獨確認編譯成功。

### 步驟 D：測試 Bridge

```bash
make test
```

**預期現象**：LED Matrix 全亮、全滅，重複 3 次；終端機看到 `[PASS] RPC requests completed`。這個 PASS 表示 RPC 呼叫未拋出錯誤，**請用眼睛確認 LED 確實閃爍**。

做到這裡，已經完成「Linux → Arduino Router → MCU → LED Matrix」。

## 3. 日後如何使用？

| 指令 | 用途 | 是否重新燒錄 |
| --- | --- | --- |
| `make setup` | 準備 Python 測試環境 | 否 |
| `make build` | 檢查 Sketch 是否可編譯 | 否 |
| `make install` | 編譯並燒錄 MCU | 是 |
| `make test` | 測試 Bridge 與 LED 閃爍 | 否 |
| `make status` | 查看 Router／Socket／Board | 否 |
| `make help` | 顯示命令 | 否 |

**不需要** `make start` / `make stop`：那是原先 Arduino App CLI 管理整個 App 與 Python Container 的做法。Arduino Router 是 UNO Q Linux 上的系統服務；MCU 韌體燒入後會自行執行。

## 4. 問題排除

**`make: command not found`**：重新執行 `bash setup.sh`（會嘗試安裝 `make`）。

**`ensurepip is not available` 或 `.venv/bin/pip` 不存在**：通常是 Python `venv` 套件缺失；`setup.sh` 會依目前 Python 版本嘗試安裝相應的 `pythonX.Y-venv` 並重建環境。

**`Permission denied` / 無法連 Router Socket**：

```bash
systemctl is-active arduino-router
ls -l /var/run/arduino-router.sock
id -nG
```

若 Socket 群組是 `arduino-router`，而帳號不在該群組，執行 `bash setup.sh`，再**完全斷線並重新登入**。**不要**使用 `chmod 777` 放寬 Socket 權限。

**`No module named arduino`**：檢查是否使用 `.venv` 的 Python；重新執行 `bash setup.sh`。

**`'str' object has no attribute '_connection'`**：可能把 `arduino.router_bridge.Bridge` 誤用成 `Bridge.call(...)` 的類別呼叫。獨立套件應先 `bridge = Bridge()`、`bridge.connect()`，再 `bridge.call(...)`。

**編譯時找不到 Board Core 或 Arduino Library**：先執行：

```bash
arduino-cli core list
arduino-cli lib list
```

UNO Q 目標 FQBN 是 `arduino:zephyr:unoq`；本專案另使用 `Arduino_RouterBridge`、`Arduino_LED_Matrix`。這兩個 Library 及其相依套件須與板子的 Core 版本相容。這部分腳本只檢查，不會擅自升級已能正常編譯的 Core；遇到缺件時依編譯錯誤與 Arduino 官方文件補齊。

**`make test` 顯示 RPC 失敗或 LED 不亮**：確認已執行 `make install`，且燒錄的 Sketch 確實使用 `Bridge.begin()` 與 `Bridge.provide_safe("set_led", set_led)`；再確認 Router 服務正常。若之前仍有測試 App 在呼叫 LED，先停止該 App 以排除干擾。

**原先 Arduino App 的 Container 還在**：`make install` 不會建立 Arduino 官方 Python Container，但不會自動移除既有 Container。請先用 `docker ps -a` 確認名稱與用途，並自行停止/移除；**腳本不會自動刪除 Docker 資源**。

## 5. Git 與安全

- 將 `README.md`、`setup.sh`、`Makefile`、`requirements.txt`、`tests/bridge_test.py`、`sketch/` 加入 Git。
- `.venv/` 是環境產物，不要提交到 Git；若根目錄已有 `.gitignore`，請合併本包的忽略規則。
- 不要把 `/var/run/arduino-router.sock` 對外網開放，亦不建議設成所有使用者可讀寫。取得 Socket 存取權限的程式，可呼叫 MCU 已註冊的 RPC。

## 6. 官方參考

- [Arduino UNO Q：Router RPC 多語言整合](https://docs.arduino.cc/tutorials/uno-q/routerbridge-multilanguage/)
- [Arduino Router Bridge Python（官方 GitHub）](https://github.com/arduino/arduino-router-bridge-py)
- [Arduino CLI：compile](https://docs.arduino.cc/arduino-cli/commands-reference/arduino-cli_compile/)
