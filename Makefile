.PHONY: version-set prerel release git-status
.PHONY: foreman lib clean test all docker
.PHONY: base gems gem-cache clean-cache gems-base

IMAGE:=ghcr.io/kingdonb/stats-tracker-ghcr
TAG:=latest
BASE_TAG:=base
GEMS_TAG:=gems
GEM_CACHE_TAG:=gem-cache
PLATFORM:=linux/arm64
OUTIMAGE:=kingdonb/opernator
VERSION:=$(shell rake app:version | awk '{ print $$3 }')

all: clean lib test

release: git-status
	git tag $(VERSION)
	git push origin $(VERSION)

prerel: set-version

# https://kgolding.co.uk/snippets/makefile-check-git-status/
git-status:
	@status=$$(git status --porcelain); \
	if [ ! -z "$${status}" ]; \
	then \
		echo "Error - working directory is dirty. Commit those changes!"; \
		exit 1; \
	fi

set-version:
	rake app:render
	@next="$$(rake app:version | awk '{ print $$3 }')" && \
	current="$(VERSION)" && \
	echo "Replacing current version strings: $$current" && \
	rake app:version && \
	/usr/bin/sed -i '' "s/newTag: $$current/newTag: $$next/g" deploy/overlays/production/kustomization.yaml && \
	echo "Version $$next set in code and manifests"

docker:
	# docker pull --platform $(PLATFORM) $(IMAGE):$(BASE_TAG)
	# docker pull --platform $(PLATFORM) $(IMAGE):$(GEMS_TAG)
	docker buildx build --push --platform $(PLATFORM) --target deploy -t $(OUTIMAGE):$(TAG) --build-arg CACHE_IMAGE=$(OUTIMAGE):$(GEMS_TAG) .

gems-base:
	docker pull --platform $(PLATFORM) $(IMAGE):$(BASE_TAG)
	docker buildx build --push --target gems -t $(OUTIMAGE):$(GEMS_TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(BASE_TAG) .

gems:
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEMS_TAG)
	docker pull --platform $(PLATFORM) $(IMAGE):$(GEM_CACHE_TAG)
	docker buildx build --push --target gems -t $(OUTIMAGE):$(GEMS_TAG) --build-arg CACHE_IMAGE=$(OUTIMAGE):$(GEM_CACHE_TAG) .

gem-cache:
	# docker pull --platform $(PLATFORM) $(OUTIMAGE):$(GEMS_TAG)
	docker tag $(OUTIMAGE):$(GEMS_TAG) $(OUTIMAGE):$(GEM_CACHE_TAG)
	docker push $(OUTIMAGE):$(GEM_CACHE_TAG)
	# docker buildx build --push --target gem-cache -t $(OUTIMAGE):$(GEM_CACHE_TAG) --build-arg CACHE_IMAGE=$(IMAGE):$(GEMS_TAG) .

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
