import multiprocessing
import time

# a productor keeps producting ice-cold drink and put them in a queue, product one per second.
def productor(queue):
    name = 1
    while True:
        queue.put(f"ice-cold drink {name}")
        print(f'{time.strftime("%H:%M:%S")} A put [ice-cold drink {name}]')
        name += 1
        time.sleep(1)

# a consumer keeps consume ice-cold drink from a queue, consume one every three seconds.
def consumer(queue):
    while True:
        print(f"{time.strftime('%H:%M:%S')} B get [{queue.get()}]")
        time.sleep(3)

if __name__ == "__main__":
    queue = multiprocessing.Queue(maxsize=5)
    p1 = multiprocessing.Process(target=productor, args=(queue,))
    p2 = multiprocessing.Process(target=consumer, args=(queue,))
    p1.start(); p2.start()
