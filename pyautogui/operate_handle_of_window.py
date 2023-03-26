from win32 import win32gui
from win32 import win32api
from win32 import win32process
from win32.lib import win32con
import pyautogui
import psutil

point = win32api.GetCursorPos()     # get the current mouse position
print(point)
hwnd = win32gui.WindowFromPoint(point)      # get the handle of window for the current position
print(hwnd)
thread_id, process_id = win32process.GetWindowThreadProcessId(hwnd)     # get the thread_id and process_id of the handle
print(process_id, thread_id)
process_name = psutil.Process(process_id).name()        # get process name by process id.
print(process_name)
process_bin = psutil.Process(process_id).exe()          # get process absolute path.
print(process_bin)
num_percent = psutil.Process(process_id).memory_percent()
print(num_percent)
num_threads = psutil.Process(process_id).num_threads()
print(num_threads)
left, top, right, bottom = win32gui.GetWindowRect(hwnd)     # obtain the position of window corresponding to hwnd
print(left, top, right, bottom)
hwnd2 = win32gui.FindWindow(None, "Windows")         # get a handle based on the window title
print(hwnd2)
window_title = win32gui.GetWindowText(hwnd)         # get a window title based on the handle
print(window_title)
win32gui.SetWindowPos(hwnd2, win32con.HWND_TOPMOST, 0, 0, 0, 0,win32con.SWP_NOMOVE | win32con.SWP_NOACTIVATE | win32con.SWP_NOOWNERZORDER | win32con.SWP_SHOWWINDOW | win32con.SWP_NOSIZE)      # top most
win32gui.SetWindowPos(hwnd2, win32con.HWND_NOTOPMOST, 0, 0, 0, 0, win32con.SWP_SHOWWINDOW | win32con.SWP_NOSIZE | win32con.SWP_NOMOVE)      # uptop most
win32gui.SetForegroundWindow(hwnd2)         # set window foreground
win32gui.IsWindow(hwnd2)            # Exist 1, else 0
win32gui.ShowWindow(hwnd2, win32con.SW_MAXIMIZE)        # maximize a window based on hwnd
win32gui.ShowWindow(hwnd2, win32con.SW_MINIMIZE)        # minimize a window based on hwnd
