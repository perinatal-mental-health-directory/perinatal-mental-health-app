FROM golang:1.20-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o server ./cmd/server

FROM alpine:latest
WORKDIR /root/

COPY --from=builder /app/server ./server
COPY internal/configs/config.go ./configs/config.yaml

EXPOSE 8080
CMD ["./server"]