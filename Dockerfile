# ---- build stage ----
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend

COPY frontend/package*.json ./

RUN rm -f package-lock.json && npm install

COPY frontend/ .
RUN npm run build

FROM golang:1.22-alpine AS backend-builder

WORKDIR /app

COPY backend/go.mod backend/go.sum ./
RUN go mod tidy

COPY backend/ .

#RUN go mod tidy && CGO_ENABLED=0 go build -ldflags="-w -s" -o server ./cmd/server
RUN CGO_ENABLED=0 go build -ldflags="-w -s" -o server ./cmd/server

# ---- runtime stage ----
FROM alpine:3.19

RUN apk add --no-cache ca-certificates bash nginx openssl

WORKDIR /app

COPY --from=backend-builder /app/server /app/server
COPY --from=backend-builder /app/migrations /app/migrations
COPY --from=backend-builder /app/docs /app/docs

COPY --from=frontend-builder /frontend/build /usr/share/nginx/html

RUN mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/key.pem \
    -out /etc/nginx/certs/cert.pem \
    -subj "/C=RU/ST=Moscow/O=TransportCards/CN=localhost"

COPY deploy/nginx.conf /etc/nginx/nginx.conf
COPY deploy/start.sh /start.sh

RUN chmod +x /start.sh && \
    chmod +x /app/server

RUN mkdir -p /run/nginx && touch /run/nginx/nginx.pid

EXPOSE 8888

ENV DB_PATH=/app/transport.db
ENV PORT=8080

CMD ["/start.sh"]
