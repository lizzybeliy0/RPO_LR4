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

a3  fc  7d  05
21 карта

# Регистрация карты
dart run bin/nfc_wallet.dart register "Иван Петров" 500

# Проверить инфо
dart run bin/nfc_wallet.dart info

# Оплатить
dart run bin/nfc_wallet.dart pay

# Пополнить
dart run bin/nfc_wallet.dart replenish

