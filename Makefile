.PHONY: foreman lib clean test all docker base

IMAGE:=kingdonb/opernator
TAG:=latest
BASE_TAG:=base

all: clean lib test

docker:
	docker buildx build --push --target app -t $(IMAGE):$(TAG) .

base: lib
	docker buildx build --push --target base -t $(IMAGE):$(BASE_TAG) .

foreman:
	date && time foreman start --no-timestamp

lib:
	make -C lib stat.wasm

clean:
	make -C lib clean

test:
	make -C lib test
