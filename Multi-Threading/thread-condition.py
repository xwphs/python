import threading, time

product_num =  0
class Productor (threading.Thread):
    def __init__(self, cond, num):
    # cond is condition, num is the number of products planned to be producted.
        super().__init__()
        self.cond = cond
        self.max_count = num
    def run(self):
        # self.cond.acquire()
        global product_num
        for i in range(1, self.max_count + 1):
            self.cond.acquire()
            time.sleep(1)
            print(f"Starting product, This is the {i} products")
            product_num += 1
            if (product_num >=5):
                print("Up to 5 goods, can not continue to produce")
                self.cond.notify()
                self.cond.wait()
        self.cond.release()

class Consumer (threading.Thread):
    def __init__(self, cond):
        super().__init__()
        self.cond = cond
    def run(self):
        num = 1
        global product_num
        while product_num :
            self.cond.acquire()
            time.sleep(2)
            print(f"consume the {num} product")
            num += 1
            product_num -= 1
            if (product_num < 4):
                self.cond.notify()
                self.cond.wait()
        self.cond.release()

if __name__ == "__main__":
    condition = threading.Condition()
    productor = Productor(condition, 11)
    consumer = Consumer(condition)
    productor.start()
    time.sleep(2)
    consumer.start()
    productor.join()
    consumer.join()
