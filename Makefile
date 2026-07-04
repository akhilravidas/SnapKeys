APP_NAME := SnapKeys
BUILD_DIR := .build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS

.PHONY: all clean run

all: $(APP_DIR)

$(APP_DIR): Sources/main.swift Info.plist
	rm -rf "$(APP_DIR)"
	mkdir -p "$(MACOS_DIR)"
	swiftc Sources/main.swift \
		-o "$(MACOS_DIR)/$(APP_NAME)" \
		-framework AppKit \
		-framework ApplicationServices \
		-framework Carbon
	cp Info.plist "$(CONTENTS_DIR)/Info.plist"
	codesign --force --deep --sign - "$(APP_DIR)"

run: $(APP_DIR)
	open "$(APP_DIR)"

clean:
	rm -rf "$(BUILD_DIR)"
