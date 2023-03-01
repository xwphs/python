from multiprocessing import Process
import os
import time

# a time-consuming task to test multi process
def task_process(delay):
    sum = 0
    for i in range(delay * 100000000):
        sum += i
    print(f"Process execute successfuly, pid: {os.getpid()}")

if __name__ == "__main__":
    print(f"ppid: {os.getpid()}")
    t0 = time.time()
    task_process(3)
    task_process(3)
    t1 = time.time()
    print(f"Duration: {t1 - t0}")
    # Create two process p0,p1
    p0 = Process(target=task_process, args=(3,))
    p1 = Process(target=task_process, args=(3,))
    t2 = time.time()
    p0.start(); p1.start()
    p0.join(); p1.join()
    t3 = time.time()
    print(f"Multi process execute duration: {t3 - t2}")
