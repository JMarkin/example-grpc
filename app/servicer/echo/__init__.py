from .echo import handler as echo_handler
from .echostream import handler as echostream_handler

handler_map = {'Echo': echo_handler, 'EchoStream': echostream_handler}

__all__ = ['handler_map']
