import multiprocessing
import time

def worke(s, i):
    s.acquire()
    print(time.strftime("%H:%M:%S"), multiprocessing.current_process().name + " acquire lock!")
    time.sleep(i)
    print(time.strftime("%H:%M:%S"), multiprocessing.current_process().name + " release lock!")
    s.release()

if __name__ == "__main__":
    s = multiprocessing.Semaphore(2)      # Execute two processes simultaneously
    for i in range(6):
        p = multiprocessing.Process(target=worke, args=(s, 2))
        p.start()
