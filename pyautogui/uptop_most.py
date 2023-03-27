from win32 import win32gui
from win32 import win32api
from win32 import win32process
from win32.lib import win32con
# import pyautogui
import psutil
import time

class Wnd:
    def __init__(self, hwnd):
        self.hwnd = hwnd
        self.pid = win32process.GetWindowThreadProcessId(self.hwnd)[1]
        self.pname = psutil.Process(self.pid).name()
        self.ppath = psutil.Process(self.pid).exe()
        self.wtitle = win32gui.GetWindowText(self.hwnd)
    def uptop(self):
        win32gui.SetWindowPos(self.hwnd, win32con.HWND_TOPMOST, 0, 0, 0, 0,win32con.SWP_NOMOVE | win32con.SWP_NOACTIVATE | win32con.SWP_NOOWNERZORDER | win32con.SWP_SHOWWINDOW | win32con.SWP_NOSIZE)
    def downtop(self):
        win32gui.SetWindowPos(self.hwnd, win32con.HWND_NOTOPMOST, 0, 0, 0, 0, win32con.SWP_SHOWWINDOW | win32con.SWP_NOSIZE | win32con.SWP_NOMOVE)
    def max(self):
        win32gui.ShowWindow(self.hwnd, win32con.SW_MAXIMIZE)
    def min(self):
        win32gui.ShowWindow(self.hwnd, win32con.SW_MINIMIZE)

def get_hwnd_basedon_cursor():
    point = win32api.GetCursorPos()
    return win32gui.WindowFromPoint(point)
def get_hwnd_basedon_title(str):
    point = win32api.GetCursorPos()
    return win32gui.FindWindow(None, str)

if __name__ == "__main__":
    print("Wait 5 seconds to put cursor on the window that you want to uptop")
    time.sleep(5)
    hwnd = get_hwnd_basedon_cursor()
    wnd = Wnd(hwnd)
    wnd.uptop()
    
