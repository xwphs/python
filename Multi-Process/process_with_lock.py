import multiprocessing
import time

# you can use 'with' or 'lock.acquire()&lock.release()' to acquire and release lock
def task1(lock):
    with lock:
        for i in range(5):
            print(time.strftime("%H:%M:%S") + " task1 executed")
            time.sleep(1)
def task2(lock):
    lock.acquire()
    for i in range(5):
        print(time.strftime("%H:%M:%S") + " task2 executed")
        time.sleep(1)
    lock.release()
def task3(lock):
    lock.acquire()
    for i in range(5):
        print(time.strftime("%H:%M:%S") + " task3 executed")
        time.sleep(1)
    lock.release()
if __name__ == "__main__":
    lock = multiprocessing.Lock()
    p1 = multiprocessing.Process(target=task1, args=(lock,))
    p2 = multiprocessing.Process(target=task2, args=(lock,))
    p3 = multiprocessing.Process(target=task3, args=(lock,))
    p1.start(); p2.start(); p3.start()
