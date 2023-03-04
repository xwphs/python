import multiprocessing
import time

def task(name):
    print(f"{time.strftime('%H:%M:%S')} task{name}")
    time.sleep(2)

if __name__ == "__main__":
    process_pool = multiprocessing.Pool(processes=3)
    for i in range(10):
        process_pool.apply_async(func=task, args=(i,))
    process_pool.close()
    process_pool.join()
