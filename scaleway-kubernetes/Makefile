SHELL := bash

init:
	tofu init

test:
	tofu test

validate:
	tofu validate

docs:
	terraform-docs markdown table --output-file README.md --output-mode inject .

lint:
	tflint --init
	tflint

format:
	tofu fmt -recursive .

build: init format lint docs test validate

clean:
	rm -rf .terraform

.PHONY: init test validate docs lint format build clean
