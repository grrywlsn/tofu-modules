SHELL := bash

MODULES := $(patsubst %/versions.tf,%,$(wildcard */versions.tf))
MODULE_DIRS := $(addsuffix /,$(MODULES))

# Optional: limit targets to one module, e.g. make build MODULE=scaleway-database-instance
MODULE_FILTER = $(if $(MODULE),$(filter $(MODULE)/,$(MODULE_DIRS)),$(MODULE_DIRS))

.DEFAULT: build

define run-in-modules
	@for dir in $(MODULE_FILTER); do \
		echo "==== Running $(1) in $$dir ===="; \
		(cd "$$dir" && $(2)) || exit 1; \
	done
endef

init:
	$(call run-in-modules,init,tofu init)

test:
	$(call run-in-modules,test,tofu test)

validate:
	$(call run-in-modules,validate,tofu validate)

docs:
	$(call run-in-modules,docs,terraform-docs markdown table --output-file README.md --output-mode inject .)

lint:
	$(call run-in-modules,lint,tflint --init && tflint)

format:
	$(call run-in-modules,format,tofu fmt -recursive .)

build: init format lint docs test validate

clean:
	$(call run-in-modules,clean,rm -rf .terraform)

list-modules:
	@echo "Modules:"
	@for dir in $(MODULE_DIRS); do \
		echo "  - $$dir"; \
	done

.PHONY: init test validate docs lint format build clean list-modules
