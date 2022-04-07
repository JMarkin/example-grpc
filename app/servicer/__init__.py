from .echo import handler_map as echo_handler_map

servicers = {
    'EchoServicer': echo_handler_map,
}

__all__ = ['servicers']
