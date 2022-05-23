# syntax=docker/dockerfile:1.2

# example ci for packaging app
FROM python:3.10-slim as ci

RUN pip install poetry && mkdir /app
WORKDIR /app

COPY . /app

RUN poetry build -f sdist

FROM python:3.10-slim as app

COPY --from=ci /app/dist/ /tmp

RUN pip install /tmp/*.tar.gz && rm -rf /tmp/*.tar.gz

WORKDIR /tmp
CMD ["python -m app"]
