import asyncio
import importlib
import logging
import signal

import grpc

from .servicer import servicers

logger = logging.getLogger(__name__)

grpcs = {  # map grpc file -> servicer
    'echo': 'EchoServicer'
}


def configure(server):
    for grpc_name, servicer_name in grpcs.items():
        _grpc = importlib.import_module(f'protofiles.{grpc_name}_pb2_grpc')

        adder = getattr(_grpc, f'add_{servicer_name}_to_server')
        servicer = getattr(_grpc, servicer_name)

        class _Servicer(servicer):
            pass

        for handler_name, handler in servicers[servicer_name].items():
            setattr(_Servicer, handler_name, handler)

        adder(_Servicer, server)


def pre_init(server):

    loop = asyncio.get_event_loop()

    async def handle_shutdown(*_):
        logger.info('Received shutdown signal')
        await server.stop(30)
        logger.info('Shut down gracefully')

    for sig in [signal.SIGTERM, signal.SIGINT]:
        loop.add_signal_handler(sig,
                                lambda: asyncio.create_task(handle_shutdown()))


async def start_server() -> None:
    server = grpc.aio.server()
    configure(server)
    server.add_insecure_port('[::]:50051')
    logger.info('Start server')
    pre_init(server)
    await server.start()
    await server.wait_for_termination()
