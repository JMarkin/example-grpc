from typing import AsyncIterable, Iterable

from protofiles.echo_pb2 import EchoRequest, EchoStreamResponse


async def handler(
    request: EchoRequest,
    unused_context,
) -> AsyncIterable[EchoStreamResponse]:
    for _ in range(request.extra_times):
        yield EchoStreamResponse(value=request.value)
