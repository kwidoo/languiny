SHELL := /bin/bash

.PHONY: bootstrap build-engine build-app build clean run fmt test

bootstrap:
	./scripts/bootstrap.sh

build-engine:
	./scripts/build_engine.sh

build-app:
	./scripts/build_app.sh

build: build-engine build-app

clean:
	./scripts/clean.sh

run:
	open dist/Languiny.app || true

fmt:
	cd engine && go fmt ./...
	@echo "Swift format: install swiftformat if needed"

test:
	cd engine && go test ./...
