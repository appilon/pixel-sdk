IMAGE := pixel-sdk-build
ZIG_GLOBAL_CACHE_DIR ?= $(HOME)/.cache/zig

DOCKER_RUN = docker run --rm \
	-u "$(shell id -u):$(shell id -g)" \
	-e HOME=/tmp/home \
	-e ZIG_GLOBAL_CACHE_DIR=/zig-cache \
	-v "$(CURDIR):/workspace" \
	-v "$(ZIG_GLOBAL_CACHE_DIR):/zig-cache" \
	$(IMAGE)

.PHONY: fmt image test

image:
	@mkdir -p "$(ZIG_GLOBAL_CACHE_DIR)"
	docker build -t $(IMAGE) -f build/Dockerfile .

test: image
	$(DOCKER_RUN) zig build test

fmt: image
	$(DOCKER_RUN) zig fmt build.zig src/
