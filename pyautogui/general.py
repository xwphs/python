import pyautogui

# mouse manipulation
screenWidth, screenHeight = pyautogui.size()
currentMouseX, currentMouseY = pyautogui.position()
pyautogui.moveTo(200,300)       # move the mouse to the x, y coordinates (200, 300).
pyautogui.click(200, 300, button=pyautogui.RIGHT, duration=5)       # move the mouse to the coordinates (200, 300), wait 5 seconds then right click
pyautogui.move(0, 200)          # move mouse 200 pixels down
pyautogui.moveTo(200,300, duration=2)
pyautogui.doubleclick('k')

# Keyboard manipulation
pyautogui.write("Hello,world!", interval=0.25)      # Type with 1/4 second pause in between each key.
pyautogui.press("k", presses=3, interval=3)        # simulate pressing k key every three seconds, total 3 times.
pyautogui.keyDown("k")      # 按下k键不释放，但不会发生重复输入k的情况（你在一个文本编辑器里按下k不释放）
pyautogui.hotkey('ctrl', 'shift', 'p')      # simulate comb-key Ctrl-Shift-P

# Message box
pyautogui.alert("This is an alert box")     # alert box
abc = pyautogui.confirm("Shall I proceed?")      # confirm box    abc is Cancel or OK according to your choice.
aa = pyautogui.confirm('Enter option.', buttons=['A', 'B', 'C'])        # give three buttons: A,B,C , then assign the result to variable aa according to your choice.
names = pyautogui.prompt("What's your name?")
password = pyautogui.password('Enter password (text will be hidden)')

pyautogui.screenshot("screenshot1.png")     # screenshot and save it as file screenshot1.png
