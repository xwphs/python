import threading, time
def lighting(event):
    """
    event.flag = False  ==> red light
    event.flag = True   ==> green light
    """
    event.set()
    count = 0
    while True:
        if (10<= count <15):
            event.clear()
            print("Red light")
        elif (count == 15):
            count = 0
            event.set()
        else:
            print("Green light")
        time.sleep(1)
        count += 1

def caring(event):
    while True:
        if event.is_set():
            print("run")
        else:
            print("no run")
            event.wait()
            print("Now, run")
        time.sleep(1)
        
if __name__ == "__main__":
    event = threading.Event()
    lighter = threading.Thread(target=lighting, args=(event,))
    car = threading.Thread(target=caring, args=(event,))
    lighter.start(); car.start()
    lighter.join(); car.join()
