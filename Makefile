NAME = aospan/joker-ap
VERSION = 0.0.1

.PHONY: all build

all: build

build:
	docker build -t $(NAME) .

run:
	docker run --name joker-ap --net host --rm --privileged -v /dev:/dev -it $(NAME) /bin/bash
