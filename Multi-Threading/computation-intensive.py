# use multi Thread to execute computationally intensive task, in my machine it consume 22 seconds
import threading
import time, os

# The interpreter of Python has GIL, one process has one thread to execute simultaneously.
# So Python multi threading only fit IO intensive scene.

def computation_intensive_mulThread():
    result = 0
    for i in range(100000000):
        result *= i
if __name__ == "__main__":
    list = []
    start = time.time()
    for i in range(12):
        thread = threading.Thread(target=computation_intensive_mulThread)
        list.append(thread)
        thread.start()
    for t in list:
        t.join()
    end = time.time()
    print(f"Time duration: {end - start} seconds")
