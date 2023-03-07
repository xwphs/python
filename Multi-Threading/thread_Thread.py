import threading
import time

def thread_task(num):
    print(f"Thread name: {threading.current_thread().name}, Start time: {time.strftime('%H:%M:%S')}")
    while num:
        time.sleep(3)
        num -= 1    
    print(f"Thread name: {threading.current_thread().name}, End time: {time.strftime('%H:%M:%S')}")

    if __name__ == "__main__":
    thread1 = threading.Thread(target=thread_task, args=(3,))
    thread2 = threading.Thread(target=thread_task, args=(2,))
    thread3 = threading.Thread(target=thread_task, args=(1,))
    thread1.start(); thread2.start(); thread3.start()
    thread1.join(); t
