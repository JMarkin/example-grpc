# Пример grpc echo сервера со сборкой в rpm пакет


### Пример запуска
1. Установка звисимоcтей и вирт окружение `poetry install`
2. Генерация из протофайла `poe protogen`
3. Запуск `poe run`

### Cборка и запуск докера с рпм
1. `docker build -t test-rpm .`
2. `docker run --privileged --tmpfs /tmp --tmpfs /run -v /sys/fs/cgroup:/sys/fs/cgroup --rm --name test-rpm test-rpm`
