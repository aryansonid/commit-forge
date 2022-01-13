FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server .

FROM alpine:3.19

# Install git, bash, and certs for HTTPS clones
RUN apk add --no-cache git bash ca-certificates

RUN adduser -D -g '' appuser
USER appuser

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 8080

ENTRYPOINT ["./server"]