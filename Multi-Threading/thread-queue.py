import threading, time
import queue

def prod(queue):
    for i in range(20):
        queue.put(f"ice-drink{i}")
        print(f"put ice-drink{i} in the queue")
        time.sleep(0.5)

def cons(queue):
    for i in range(20):
        print(f"get {queue.get()} from the queue")
        time.sleep(2)

queue = queue.Queue(maxsize=5)
productor = threading.Thread(target=prod, args=(queue,))
consumer = threading.Thread(target=cons, args=(queue,))
productor.start(); consumer.start()
