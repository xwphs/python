import pyautogui
import time

# draw a square spiral
time.sleep(5)
distance = 400
while distance > 0:
    pyautogui.drag(distance, 0, duration=0.5)
    distance -= 10
    pyautogui.drag(0, distance, duration=0.5)
    pyautogui.drag(-distance, 0, duration=0.5)
    distance -= 10
    pyautogui.drag(0, -distance, duration=0.5)
