config ?= release

PACKAGE := github_rest_api
GET_DEPENDENCIES_WITH := corral fetch
CLEAN_DEPENDENCIES_WITH := corral clean
COMPILE_WITH := corral run -- ponyc

BUILD_DIR ?= build/$(config)
SRC_DIR := $(PACKAGE)
EXAMPLES_DIR := examples
tests_binary := $(BUILD_DIR)/$(PACKAGE)
docs_dir := build/$(PACKAGE)-docs

ifdef config
	ifeq (,$(filter $(config),debug release))
		$(error Unknown configuration "$(config)")
	endif
endif

ifeq ($(config),release)
	PONYC = $(COMPILE_WITH)
else
	PONYC = $(COMPILE_WITH) --debug
endif

ifeq ($(ssl), 3.0.x)
	SSL = -Dopenssl_3.0.x
else ifeq ($(ssl), 1.1.x)
	SSL = -Dopenssl_1.1.x
else ifeq ($(ssl), 0.9.0)
	SSL = -Dopenssl_0.9.0
else
	$(error Unknown SSL version "$(ssl)". Must set using 'ssl=FOO')
endif

PONYC := $(PONYC) $(SSL)

SOURCE_FILES := $(shell find $(SRC_DIR) -name "*.pony")
EXAMPLES := $(notdir $(shell find $(EXAMPLES_DIR)/* ! -name build -type d))
EXAMPLES_SOURCE_FILES := $(shell find $(EXAMPLES_DIR) -name "*.pony")
EXAMPLES_BINARIES := $(addprefix $(BUILD_DIR)/,$(EXAMPLES))

mkfile_path := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

test: unit-tests build-examples

unit-tests: $(tests_binary)
	$^ --exclude=integration --sequential

$(tests_binary): $(SOURCE_FILES) | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

build-examples: $(EXAMPLES_BINARIES)

$(EXAMPLES_BINARIES): $(BUILD_DIR)/%: $(SOURCE_FILES) $(EXAMPLES_SOURCE_FILES) | $(BUILD_DIR)
	BUILD_DIR=$(mkfile_path)$(BUILD_DIR) make -C $(EXAMPLES_DIR)/$*

clean:
	$(CLEAN_DEPENDENCIES_WITH)
	rm -rf $(BUILD_DIR)

$(docs_dir): $(SOURCE_FILES)
	rm -rf $(docs_dir)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) --docs-public --pass=docs --output build $(SRC_DIR)

docs: $(docs_dir)

TAGS:
	ctags --recurse=yes $(SRC_DIR)

all: test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: all build-examples clean TAGS test
