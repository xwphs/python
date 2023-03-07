import threading
import time

# When multi threads modify the same resource, you should use threading.Lock()
sum = 0
def task1(num):
    global sum
    for i in range(1000000):
        sum += num
        sum -= num

# You will find the result (sum is not 0)
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
