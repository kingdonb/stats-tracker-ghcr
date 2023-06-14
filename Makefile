.PHONY: foreman lib clean test all docker
.PHONY: base gems gem-cache clean-cache

IMAGE:=ghcr.io/kingdonb/stats-tracker-ghcr
TAG:=latest
BASE_TAG:=base
GEMS_TAG:=gems
GEM_CACHE_TAG:=gem-cache
PLATFORM:=linux/amd64
OUTIMAGE:=kingdonb/opernator

all: clean lib test

docker:
	docker pull --platform $(PLATFORM) $(IMAGE):$(BASE_TAG)
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEMS_TAG)
	docker buildx build --push --platform $(PLATFORM) --target deploy -t $(OUTIMAGE):$(TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEMS_TAG) .

gems:
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEMS_TAG)
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEM_CACHE_TAG)
	docker buildx build --push --target gems -t $(OUTIMAGE):$(GEMS_TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEM_CACHE_TAG) .

gem-cache:
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEMS_TAG)
	docker buildx build --push --target gem-cache -t $(OUTIMAGE):$(GEM_CACHE_TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEMS_TAG) .

clean-cache:
	docker buildx build --push --target gem-cache -t $(OUTIMAGE):$(GEM_CACHE_TAG) .

base: lib
	docker buildx build --push --target base -t $(OUTIMAGE):$(BASE_TAG) .

foreman:
	date && time foreman start --no-timestamp

lib:
	make -C lib stat.wasm

clean:
	make -C lib clean

test:
	make -C lib test
