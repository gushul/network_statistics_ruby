# Variables
DOCKER_IMAGE_NAME := network-stats-microservice
DOCKER_CONTAINER_NAME := network-stats-container
DOCKER_PORT := 4567
RSPEC_OPTIONS := --format documentation

.PHONY: all build run test stop

all: run

build:
	docker build -t $(DOCKER_IMAGE_NAME) .

run: build
	docker run -d --name $(DOCKER_CONTAINER_NAME) -p $(DOCKER_PORT):$(DOCKER_PORT) $(DOCKER_IMAGE_NAME)

stop:
	docker stop $(DOCKER_CONTAINER_NAME)
	docker rm $(DOCKER_CONTAINER_NAME)

test:
	rspec $(RSPEC_OPTIONS)
