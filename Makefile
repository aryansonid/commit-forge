.PHONY: build run test test-cover clean lint fmt vet docker-build docker-up docker-down

BINARY_NAME=commit-forge
GO=go

build:
	$(GO) build -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

test:
	$(GO) test ./... -v

test-cover:
	$(GO) test ./... -v -coverprofile=coverage.out
	$(GO) tool cover -html=coverage.out -o coverage.html

test-race:
	$(GO) test ./... -v -race

clean:
	rm -f $(BINARY_NAME) coverage.out coverage.html
	$(GO) clean

lint:
	golangci-lint run ./...

fmt:
	$(GO) fmt ./...

vet:
	$(GO) vet ./...

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down
