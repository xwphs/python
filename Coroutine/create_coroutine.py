import asyncio
import time

# async defines a coroutine function.
async def task1():
    print(f"{time.strftime('%H:%M:%S')} task start...")
    time.sleep(2)
    print(f"{time.strftime('%H:%M:%S')} task end.")

# call a coroutine function will not execute it, will return a coroutine object.
coroutine = task1()
print(f"{time.strftime('%H:%M:%S')} generate coroutine object {coroutine}. The function is not called")
loop = asyncio.get_event_loop()
start = time.time()
# use loop.run_until_complete() to execute coroutine.
loop.run_until_complete(coroutine)
end = time.time()
print(f"{time.strftime('%H:%M:%S')} coroutine task finished, duration: {end - start}seconds")
