from concurrent.futures import ThreadPoolExecutor
import threading, time

def fun():
    time.sleep(1)
    print("xwphs")

if __name__ == "__main__":
    tpool = ThreadPoolExecutor(max_workers=12)
    for i in range(12):
        tpool.submit(fun)
