.DEFAULT_GOAL := submission
.PHONY: submission clean

PROJECT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
DIST_DIR := $(PROJECT_DIR)/.development/dist
LOGIN ?= xvoldrv00

submission:
	@python3 "$(PROJECT_DIR)/.development/package.py" --login "$(LOGIN)"

clean:
	@rm -rf "$(DIST_DIR)"
