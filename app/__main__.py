#!/usr/bin/env python
import asyncio
import logging

log_fmt = '%(asctime)s %(levelname)s %(message)s'
logging.basicConfig(level=logging.INFO, format=log_fmt)


async def start():

    from app import start_server

    await start_server()


asyncio.run(start())
