SHELL := bash

MODULES := $(dir $(wildcard */versions.tf))

.DEFAULT: build

init:
	@for dir in $(MODULES); do \
		echo "==== Running init in $$dir ===="; \
		$(MAKE) -C $$dir init || exit 1; \
	done

test:
	@for dir in $(MODULES); do \
		echo "==== Running test in $$dir ===="; \
		$(MAKE) -C $$dir test || exit 1; \
	done

validate:
	@for dir in $(MODULES); do \
		echo "==== Running validate in $$dir ===="; \
		$(MAKE) -C $$dir validate || exit 1; \
	done

docs:
	@for dir in $(MODULES); do \
		echo "==== Running docs in $$dir ===="; \
		$(MAKE) -C $$dir docs || exit 1; \
	done

lint:
	@for dir in $(MODULES); do \
		echo "==== Running lint in $$dir ===="; \
		$(MAKE) -C $$dir lint || exit 1; \
	done

format:
	@for dir in $(MODULES); do \
		echo "==== Running format in $$dir ===="; \
		$(MAKE) -C $$dir format || exit 1; \
	done

build:
	@for dir in $(MODULES); do \
		echo "==== Running build in $$dir ===="; \
		$(MAKE) -C $$dir build || exit 1; \
	done

clean:
	@for dir in $(MODULES); do \
		echo "==== Running clean in $$dir ===="; \
		$(MAKE) -C $$dir clean || exit 1; \
	done

list-modules:
	@echo "Modules:"
	@for dir in $(MODULES); do \
		echo "  - $$dir"; \
	done

.PHONY: init test validate docs lint format build clean list-modules
