import multiprocessing
import time

def worker(event, name):
    while not event.is_set():
        print(f"{time.strftime('%H:%M:%S')} Process{name} is ready!")
        event.wait(1)
    print(f"Process{name} is running!")

if __name__ == "__main__":     
    event = multiprocessing.Event()
    # event has an bool value, default is False. event.clear() set value False, event.set() set value True.
    # when value is True, event.wait() not block!
    for i in range(1,3):
        multiprocessing.Process(target=worker, args=(event, i)).start()
    time.sleep(5)
    event.set()
