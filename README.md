# Transport Card Payment

Оплата проезда транспортной картой.

## Запуск

### Docker

```bash
docker build -t transport-api .
docker run -p 8888:8888 transport-api
```

Или через docker-compose:

```bash
docker-compose up -d
```

### Локальная разработка

```bash
go mod download
go run ./cmd/server
```

## Swagger документация

Доступна по адресу: https://localhost:8888/api/v1/swagger/index.html

## Данные по умолчанию

- Логин: `admin`
- Пароль: `password`

## Сайт

Доступен по адресу: https://localhost:8888

## Запуска Flatter приложения 

```bash
flutter run -d windows --release    
```


