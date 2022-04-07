from protofiles.echo_pb2 import EchoRequest, EchoResponse


async def handler(request: EchoRequest, unused_context) -> EchoResponse:
    return EchoResponse(values=[request.value for _ in range(request.extra_times)])
