import threading
import time

def thread_task(num):
    print(f"Thread_name: {threading.current_thread().name}, Start_time: {time.strftime('%H:%M:%S')}")
    while num:
        time.sleep(3)
        num -= 1
    print(f"Thread_name: {threading.current_thread().name}, End_time: {time.strftime('%H:%M:%S')}")

# a subclass of Thread
class MyThread (threading.Thread):
    def __init__(self, target, args):
        super().__init__()
        self.target = target
        self.args = args
    def run(self):
        self.target(*self.args)

if __name__ == "__main__":
    t1 = MyThread(target=thread_task, args=(3,))
    t2 = MyThread(target=thread_task, args=(2,))
    t3 = MyThread(target=thread_task, args=(1,))
    t1.start(); t2.start(); t3.start()
    t1.join(); t2.join(); t3.join()
