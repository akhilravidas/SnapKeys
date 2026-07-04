APP_NAME := SnapKeys
BUILD_DIR := .build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
ICONSET_DIR := $(BUILD_DIR)/AppIcon.iconset
ICON_FILE := $(BUILD_DIR)/AppIcon.icns
INSTALL_DIR := $(HOME)/Applications
INSTALLED_APP := $(INSTALL_DIR)/$(APP_NAME).app

.PHONY: all clean install run run-installed

all: $(APP_DIR)

$(APP_DIR): Sources/main.swift Info.plist $(ICON_FILE)
	rm -rf "$(APP_DIR)"
	mkdir -p "$(MACOS_DIR)" "$(RESOURCES_DIR)"
	swiftc Sources/main.swift \
		-o "$(MACOS_DIR)/$(APP_NAME)" \
		-framework AppKit \
		-framework ApplicationServices \
		-framework Carbon
	cp Info.plist "$(CONTENTS_DIR)/Info.plist"
	cp "$(ICON_FILE)" "$(RESOURCES_DIR)/AppIcon.icns"
	codesign --force --deep --sign - "$(APP_DIR)"

$(ICON_FILE): Tools/generate_icon.swift
	rm -rf "$(ICONSET_DIR)" "$(ICON_FILE)"
	mkdir -p "$(ICONSET_DIR)"
	swift Tools/generate_icon.swift 16 "$(ICONSET_DIR)/icon_16x16.png"
	swift Tools/generate_icon.swift 32 "$(ICONSET_DIR)/icon_16x16@2x.png"
	swift Tools/generate_icon.swift 32 "$(ICONSET_DIR)/icon_32x32.png"
	swift Tools/generate_icon.swift 64 "$(ICONSET_DIR)/icon_32x32@2x.png"
	swift Tools/generate_icon.swift 128 "$(ICONSET_DIR)/icon_128x128.png"
	swift Tools/generate_icon.swift 256 "$(ICONSET_DIR)/icon_128x128@2x.png"
	swift Tools/generate_icon.swift 256 "$(ICONSET_DIR)/icon_256x256.png"
	swift Tools/generate_icon.swift 512 "$(ICONSET_DIR)/icon_256x256@2x.png"
	swift Tools/generate_icon.swift 512 "$(ICONSET_DIR)/icon_512x512.png"
	swift Tools/generate_icon.swift 1024 "$(ICONSET_DIR)/icon_512x512@2x.png"
	iconutil -c icns "$(ICONSET_DIR)" -o "$(ICON_FILE)"

run: $(APP_DIR)
	open "$(APP_DIR)"

install: $(APP_DIR)
	mkdir -p "$(INSTALL_DIR)"
	rm -rf "$(INSTALLED_APP)"
	ditto "$(APP_DIR)" "$(INSTALLED_APP)"
	codesign --force --deep --sign - "$(INSTALLED_APP)"

run-installed: install
	open "$(INSTALLED_APP)"

clean:
	rm -rf "$(BUILD_DIR)"
