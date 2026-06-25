# Glimpse — build interface
#
# SwiftPM produces a bare executable; macOS needs an .app bundle carrying the
# Info.plist (camera-usage description + LSUIElement menu-bar-only behaviour).
# These targets wrap `swift build` and assemble that bundle.

APP_NAME   := Glimpse
CONFIG     ?= release
BUILD_ROOT := .build
BUILD_DIR  := $(BUILD_ROOT)/$(CONFIG)
APP_BUNDLE := $(BUILD_ROOT)/$(APP_NAME).app
EXECUTABLE := $(BUILD_DIR)/$(APP_NAME)

.DEFAULT_GOAL := app

.PHONY: help build app run test clean

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

build: ## Compile the executable (CONFIG=debug|release)
	swift build -c $(CONFIG)

app: build ## Assemble $(APP_NAME).app
	@echo "▸ Assembling $(APP_NAME).app…"
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"
	@cp "$(EXECUTABLE)" "$(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)"
	@cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@# Ad-hoc sign so the camera TCC prompt can attribute access to the bundle.
	@codesign --force --deep --sign - "$(APP_BUNDLE)" >/dev/null 2>&1 \
		|| echo "  (codesign skipped)"
	@echo "✓ Built $(APP_BUNDLE)"

run: app ## Build the bundle and launch it
	open "$(APP_BUNDLE)"

test: ## Run the unit tests
	swift test

clean: ## Remove all build artifacts
	swift package clean
	rm -rf "$(BUILD_ROOT)"
