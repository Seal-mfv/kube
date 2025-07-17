export GOBIN := $(abspath bin)
export PATH := $(GOBIN):$(shell printenv PATH)
export GOPRIVATE := github.com/moneyforward

install-modules:
	go mod tidy

install-tools:
	mkdir -p $(GOBIN)
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.8

lint:
	@$(GOBIN)/golangci-lint run ./...

ut:
	@go test ./...

.PHONY: docker-compose-up
docker-compose-up:
	@docker compose -f deploy/docker-compose.yaml up --build $(svc)

.PHONY: docker-compose-down
docker-compose-down:
	@docker compose -f deploy/docker-compose.yaml down $(svc)

.PHONY: docker-compose-run
docker-compose-run:
	@docker compose -f deploy/docker-compose.yaml $(args)
