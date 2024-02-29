from amqtt.broker import Broker
import logging
import asyncio


async def broker_coro():
    config = {
        "listeners": {
            "default": {
                "type": "tcp",
                "max-connections": 100,
                "bind": "0.0.0.0:9999"
            }
        },
        "auth": {
            "allow-anonymous": True,
            "plugins": ["auth_anonymous"],
        },
        "topic-check": {
            "enabled": True,
            "plugins": ["topic_acl"],
            "acl": {
                # username: [list of allowed topics]
                "anonymous": [
                    "#"
                ],
            },
        },
    }
    broker = Broker(config=config)
    await broker.start()


if __name__ == '__main__':
    formatter = "[%(asctime)s] :: %(levelname)s :: %(name)s :: %(message)s"
    logging.basicConfig(level=logging.WARN, format=formatter)
    asyncio.get_event_loop().run_until_complete(broker_coro())
    asyncio.get_event_loop().run_forever()
