import logging
import asyncio
import random
import time
import struct
import sys

from amqtt.client import MQTTClient

logger = logging.getLogger(__name__)


def generate_vectors():
    # NOTE: might be 1-dimensional, not 3-dimensional
    val = [
        struct.pack(
            '%sf' % 3,
            *[random.uniform(-5, 5) for i in range(3)]
        ) for j in range(10_000)]

    buf = b''.join(val)
    print(len(buf))
    return buf


async def publish_events(i):
    C = MQTTClient()
    random.seed(None)
    await C.connect('mqtt://localhost:9999')
    try:
        while True:
            await C.publish(
                f'sensor{i}',
                generate_vectors()
            )
            print(f"message published from sensor {i}")
            time.sleep(1)
    except KeyboardInterrupt:
        await C.disconnect()


if __name__ == '__main__':
    formatter = "[%(asctime)s] %(name)s {%(filename)s:%(lineno)d} %(levelname)s - %(message)s"
    logging.basicConfig(level=logging.ERROR, format=formatter)
    sensor = int(sys.argv[1])
    asyncio.get_event_loop().run_until_complete(publish_events(sensor))
