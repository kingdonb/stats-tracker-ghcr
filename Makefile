.PHONY: foreman lib clean test all docker base gems gem-cache

IMAGE:=kingdonb/opernator
TAG:=latest
BASE_TAG:=base
GEMS_TAG:=gems
GEM_CACHE_TAG:=gem-cache

all: clean lib test

docker:
	docker buildx build --push --target deploy -t $(IMAGE):$(TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEM_CACHE_TAG) .

gems:
	docker buildx build --push --target gems -t $(IMAGE):$(GEMS_TAG) .

# Based on: https://blog.saeloun.com/2022/07/12/docker-cache/
gem-cache:
	docker buildx build --push --target gem-cache -t $(IMAGE):$(GEM_CACHE_TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEMS_TAG) .

base: lib
	docker buildx build --push --target base -t $(IMAGE):$(BASE_TAG) . #  BASE_IMAGE=$(IMAGE):$(BASE_TAG) .

foreman:
	date && time foreman start --no-timestamp

lib:
	make -C lib stat.wasm

clean:
	make -C lib clean

test:
	make -C lib test
