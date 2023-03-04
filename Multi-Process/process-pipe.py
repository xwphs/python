import multiprocessing
import time

def send(pipe):
   for i in range(5):
    str = f"task-{i}"
    print(f"{time.strftime('%H:%M:%S')} send message:{str}")
    pipe.send(str)
    # time.sleep(2)
def receive(pipe):
    for i in range(5):
    #    time.sleep(2)
       str = pipe.recv()
       print(f"{time.strftime('%H:%M:%S')} receive message:{str}")

if __name__ == "__main__":
    pipe = multiprocessing.Pipe()
    p1 = multiprocessing.Process(target=send, args=(pipe[0],))
    p2 = multiprocessing.Process(target=receive, args=(pipe[1],))
    p1.start(); p2.start()
