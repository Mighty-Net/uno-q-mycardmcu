from arduino.app_utils import App
import time

def loop():
    time.sleep(60)

App.run(user_loop=loop)