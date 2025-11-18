.PHONY: build test run clean help

# Default target
all: build

# Variables
IMAGE_NAME ?= alpine-certificates
IMAGE_TAG ?= latest
ALPINE_VERSION ?= 3.19

# Build the Docker image
build:
	@echo "Building Docker image $(IMAGE_NAME):$(IMAGE_TAG) with Alpine $(ALPINE_VERSION)..."
	docker build \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		.

# Build with specific Alpine version
build-alpine:
	@if [ -z "$(VERSION)" ]; then echo "Usage: make build-alpine VERSION=3.18"; exit 1; fi
	@echo "Building with Alpine $(VERSION)..."
	docker build \
		--build-arg ALPINE_VERSION=$(VERSION) \
		-t $(IMAGE_NAME):alpine-$(VERSION) \
		.

# Test the container
test:
	@echo "Testing container..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Container test passed!"

# Run the container interactively
run:
	@echo "Running container..."
	docker run --rm -it $(IMAGE_NAME):$(IMAGE_TAG)

# Run with mounted volumes
run-volumes:
	@echo "Running container with mounted volumes..."
	mkdir -p ./test-certs/etc-ssl-certs ./test-certs/local-ca-certs
	docker run --rm \
		-v $(PWD)/test-certs/etc-ssl-certs:/etc/ssl/certs \
		-v $(PWD)/test-certs/local-ca-certs:/usr/local/share/ca-certificates \
		$(IMAGE_NAME):$(IMAGE_TAG)

# Check health status
health:
	@echo "Checking container health..."
	docker run --rm --health-interval=5s --health-timeout=3s $(IMAGE_NAME):$(IMAGE_TAG) sleep 30

# Clean up
clean:
	@echo "Cleaning up..."
	docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	docker rmi -f $(IMAGE_NAME):alpine-* 2>/dev/null || true
	rm -rf ./test-certs

# Clean everything including test artifacts
clean-all: clean
	@echo "Cleaning all artifacts..."
	rm -rf ./test-certs

# Security scan
security-scan:
	@echo "Running security scan..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-aquasec/trivy image $(IMAGE_NAME):$(IMAGE_TAG)

# Lint Dockerfile
lint:
	@echo "Linting Dockerfile..."
	docker run --rm -v $(PWD):/.cache/ hadolint/hadolint hadolint alpine-certificates/Dockerfile

# Show image size
size:
	@echo "Image sizes:"
	docker images $(IMAGE_NAME)

# Shell access for debugging
shell:
	@echo "Opening shell in container..."
	docker run --rm -it --entrypoint /bin/sh $(IMAGE_NAME):$(IMAGE_TAG)

# Show help
help:
	@echo "Available targets:"
	@echo "  build          - Build Docker image"
	@echo "  build-alpine   - Build with specific Alpine version (VERSION=3.18)"
	@echo "  test           - Test the container"
	@echo "  run            - Run container interactively"
	@echo "  run-volumes    - Run with mounted volumes"
	@echo "  health         - Check container health"
	@echo "  clean          - Remove built images"
	@echo "  clean-all      - Remove all artifacts"
	@echo "  security-scan  - Run security scan with Trivy"
	@echo "  lint           - Lint Dockerfile with hadolint"
	@echo "  size           - Show image sizes"
	@echo "  shell          - Open shell in container"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME     - Docker image name (default: alpine-certificates)"
	@echo "  IMAGE_TAG      - Docker image tag (default: latest)"
	@echo "  ALPINE_VERSION - Alpine Linux version (default: 3.19)"
