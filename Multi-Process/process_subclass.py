from multiprocessing import Process
import os
import time

# a MyProcess class extends Process
class MyProcess(Process):
    def __init__(self, delay):
        self.delay = delay
        super().__init__()
    def run(self):
        num = 0
        for i in range(self.delay * 100000000):
            num += i
        print(f"pid: {os.getpid()}")
if __name__ == "__main__":
    print(f"main process pid: {os.getpid()}")
    p1 = MyProcess(3)
    p2 = MyProcess(3)
    t0 = time.time()
    p1.start(); p2.start()
    p1.join(); p2.join()
    t1 = time.time()
    print(f"Execute successfully, Duration: {t1 - t0}")
