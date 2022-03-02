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

help:
	@echo "Available targets:"
	@echo "  build        - Build the binary"
	@echo "  run          - Build and run the server"
	@echo "  test         - Run all tests"
	@echo "  test-cover   - Run tests with coverage report"
	@echo "  test-race    - Run tests with race detector"
	@echo "  clean        - Remove build artifacts"
	@echo "  lint         - Run golangci-lint"
	@echo "  fmt          - Format Go code"
	@echo "  vet          - Run go vet"
	@echo "  docker-build - Build Docker image"
	@echo "  docker-up    - Start Docker containers"
	@echo "  docker-down  - Stop Docker containers"
	@echo "  help         - Show this help message"
