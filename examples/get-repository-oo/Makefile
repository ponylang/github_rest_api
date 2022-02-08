GET_DEPENDENCIES_WITH := corral fetch
COMPILE_WITH ?= corral run -- ponyc

BUILD_DIR ?= build
SRC_DIR := .
BINARY_NAME := get-repository-oo
LIB_SRC := ../../github_rest_api/

PONYC = $(COMPILE_WITH)

ssl=1.1.x
ifeq ($(ssl), 1.1.x)
	PONYC += -Dopenssl_1.1.x
else ifeq ($(ssl), 0.9.0)
	PONYC += -Dopenssl_0.9.0
else
	$(error Unknown SSL version "$(ssl)". Must set using 'ssl=FOO')
endif

SOURCE_FILES := $(shell find $(LIB_SRC) -name "*.pony")

$(BUILD_DIR)/$(BINARY_NAME): $(SOURCE_FILES) main.pony | $(BUILD_DIR)
	$(GET_DEPENDENCIES_WITH)
	$(PONYC) -o $(BUILD_DIR) $(SRC_DIR)

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: clean
