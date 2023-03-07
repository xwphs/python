import threading, time

# Only five threads can run in a time
semaphore = threading.BoundedSemaphore(5)
def business_management(name):
    semaphore.acquire()
    time.sleep(3)
    print(f"Thread_name: {threading.current_thread().name}, {name} is running business")
    semaphore.release()

if __name__ == "__main__":
    list = []
    for i in range(12):
        thread = threading.Thread(target=business_management, args=(i,))
        list.append(thread)
    for thread in list:
        thread.start()
    for thread in list:
        thread.join()
