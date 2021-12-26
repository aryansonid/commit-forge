.PHONY: build run test clean lint fmt vet docker-build docker-up docker-down

BINARY_NAME=commit-forge
GO=go

build:
	$(GO) build -o $(BINARY_NAME) .

run: build
	./$(BINARY_NAME)

test:
	$(GO) test ./... -v

clean:
	rm -f $(BINARY_NAME)
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
