import logging
import asyncio

from amqtt.client import MQTTClient, ClientException
from amqtt.mqtt.constants import QOS_1

logger = logging.getLogger(__name__)


async def uptime_coro():
    C = MQTTClient()
    await C.connect('mqtt://localhost:9999')
    # Subscribe to '$SYS/broker/uptime' with QOS=1
    # Subscribe to '$SYS/broker/load/#' with QOS=2
    await C.subscribe([
        ('sensor0', QOS_1),
    ])
    try:
        for i in range(1, 10000):
            message = await C.deliver_message()
            packet = message.publish_packet
            print("%d:  %s => %d" % (
                i, packet.variable_header.topic_name, len(packet.payload.data)))
        await C.unsubscribe(['$SYS/broker/uptime', '$SYS/broker/load/#'])
        await C.disconnect()
    except ClientException as c_e:
        logger.error("Client exception: %s" % c_e)

if __name__ == '__main__':
    formatter = "[%(asctime)s] %(name)s {%(filename)s:%(lineno)d} %(levelname)s - %(message)s"
    logging.basicConfig(level=logging.ERROR, format=formatter)
    asyncio.get_event_loop().run_until_complete(uptime_coro())
