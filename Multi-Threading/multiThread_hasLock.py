import threading
import time

sum = 0
lock = threading.Lock()
def task1(num):
    global sum
    lock.acquire()
    for i in range(1000000):
        sum += num
        sum -= num
    lock.release()

# the result(sum is always 0) because of lock
if __name__ == "__main__":    
    t1 = threading.Thread(target=task1, args=(3,))
    t2 = threading.Thread(target=task1, args=(5,))
    t3 = threading.Thread(target=task1, args=(18,))
    start = time.time()
    t1.start()
    t2.start()
    t3.start()
    t1.join(); t2.join(); t3.join()
    end = time.time()
    print(f"sum= {sum}")
    print(f"Duration: {end - start}s")
