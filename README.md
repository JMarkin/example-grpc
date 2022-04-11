# Пример grpc echo сервера со сборкой в rpm пакет



### Запуск конечного варианта
```
docker run  --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup  --cap-add SYS_ADMIN --rm --name test-rpm -p 50051:50051 --tty ghcr.io/jmarkin/example-grpc:master
```

### Пример запуска на локальнйо машине
1. Установка звисимоcтей и вирт окружение `poetry install`
2. Генерация из протофайла `poe protogen`
3. Запуск `poe run`

### Сборка проверка через докер
1. docker build -t testrpm .
2. docker run --rm --name testrpm testrpm 
