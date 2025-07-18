# Makefile for CPU Prebuilt Binaries
# This Makefile builds cpu and cpud binaries for aarch64

# Configuration
SHELL := /bin/bash
.PHONY: all clean build binaries initramfs install help
.DEFAULT_GOAL := help

# Directories
BUILD_DIR := build
BINARIES_DIR := $(BUILD_DIR)/binaries
INITRAMFS_DIR := $(BUILD_DIR)/initramfs
REPOS_DIR := $(BUILD_DIR)/repos
CPU_REPO := $(REPOS_DIR)/cpu
UROOT_REPO := $(REPOS_DIR)/u-root

# Go configuration
GOOS := linux
GOARCH := arm64
CGO_ENABLED := 0

# Files
UROOT_BIN := $(BUILD_DIR)/u-root-bin
GO_WORK := $(BUILD_DIR)/go.work
CPU_BINARY := $(BINARIES_DIR)/cpu
CPUD_BINARY := $(BINARIES_DIR)/cpud
INITRAMFS_FILE := $(INITRAMFS_DIR)/cpud-initramfs.cpio.gz
BUILD_INFO := $(BINARIES_DIR)/BUILD_INFO.txt

# Version detection
CPU_VERSION := $(shell cd $(CPU_REPO) 2>/dev/null && git describe --tags --always 2>/dev/null || echo "unknown")
GO_VERSION := $(shell go version 2>/dev/null || echo "go version unknown")

help: ## Show this help message
	@echo "=== CPU Prebuilt Build System ==="
	@echo "This Makefile builds cpu and cpud binaries for aarch64"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

all: binaries initramfs ## Build everything (binaries and initramfs)

check-go: ## Check if Go is installed
	@if ! command -v go &> /dev/null; then \
		echo "Error: Go is not installed. Please install Go 1.21 or later."; \
		exit 1; \
	fi
	@echo "Using Go version: $(shell go version | cut -d' ' -f3 | sed 's/go//')"

$(BUILD_DIR):
	@mkdir -p $(BINARIES_DIR) $(INITRAMFS_DIR) $(REPOS_DIR)

$(CPU_REPO): | $(BUILD_DIR)
	@echo "Cloning u-root/cpu repository..."
	@if [ -d "$(CPU_REPO)" ]; then \
		echo "cpu directory already exists, updating..."; \
		cd $(CPU_REPO) && git pull; \
	else \
		git clone https://github.com/u-root/cpu.git $(CPU_REPO); \
	fi

$(GO_WORK): $(CPU_REPO) $(UROOT_REPO)
	@echo "Setting up Go workspace..."
	@echo "go 1.24.0" > $(GO_WORK)
	@echo "" >> $(GO_WORK)
	@echo "use ./repos/cpu" >> $(GO_WORK)
	@echo "use ./repos/u-root" >> $(GO_WORK)

# Repository management
repos: $(CPU_REPO) $(UROOT_REPO)  ## Clone all repositories

$(UROOT_REPO): | $(BUILD_DIR)
	@echo "Cloning u-root/u-root repository..."
	@if [ -d "$(UROOT_REPO)" ]; then \
		echo "u-root directory already exists, updating..."; \
		cd $(UROOT_REPO) && git pull; \
	else \
		git clone https://github.com/u-root/u-root.git $(UROOT_REPO); \
	fi
	@echo "Building u-root from source..."
	@cd $(BUILD_DIR) && cd repos/u-root && go build -o ../../u-root-bin ./

$(CPU_BINARY): $(GO_WORK) $(UROOT_BIN)
	@echo "Building cpu binary for aarch64..."
	@cd $(CPU_REPO) && go mod download
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o ../../binaries/cpu ./cmds/cpu

$(CPUD_BINARY): $(GO_WORK) $(UROOT_BIN)
	@echo "Building cpud binary for aarch64..."
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o ../../binaries/cpud ./cmds/cpud

$(BUILD_INFO): $(CPU_BINARY) $(CPUD_BINARY)
	@echo "Creating build info..."
	@cd $(CPU_REPO) && CPU_VERSION=$$(git describe --tags --always) && \
	echo "U-Root CPU Binaries for aarch64 (Local Build)" > ../../binaries/BUILD_INFO.txt && \
	echo "Built on: $$(date -u)" >> ../../binaries/BUILD_INFO.txt && \
	echo "CPU version: $$CPU_VERSION" >> ../../binaries/BUILD_INFO.txt && \
	echo "Target architecture: $(GOOS)/$(GOARCH)" >> ../../binaries/BUILD_INFO.txt && \
	echo "Go version: $(GO_VERSION)" >> ../../binaries/BUILD_INFO.txt && \
	echo "" >> ../../binaries/BUILD_INFO.txt && \
	echo "Files in this archive:" >> ../../binaries/BUILD_INFO.txt && \
	echo "- cpu: CPU client binary" >> ../../binaries/BUILD_INFO.txt && \
	echo "- cpud: CPU daemon binary" >> ../../binaries/BUILD_INFO.txt && \
	echo "- cpud-initramfs.cpio.gz: U-root initramfs with cpud as init" >> ../../binaries/BUILD_INFO.txt && \
	echo "" >> ../../binaries/BUILD_INFO.txt && \
	echo "Usage:" >> ../../binaries/BUILD_INFO.txt && \
	echo "  ./cpu -h    # Show CPU client help" >> ../../binaries/BUILD_INFO.txt && \
	echo "  ./cpud -h   # Show CPU daemon help" >> ../../binaries/BUILD_INFO.txt && \
	echo "" >> ../../binaries/BUILD_INFO.txt && \
	echo "Initramfs usage:" >> ../../binaries/BUILD_INFO.txt && \
	echo "  Use cpud-initramfs.cpio.gz as initrd with Linux kernel" >> ../../binaries/BUILD_INFO.txt && \
	echo "  Boot parameters: init=/init" >> ../../binaries/BUILD_INFO.txt && \
	echo "" >> ../../binaries/BUILD_INFO.txt && \
	echo "Build system: Makefile" >> ../../binaries/BUILD_INFO.txt

binaries: check-go $(CPU_BINARY) $(CPUD_BINARY) $(BUILD_INFO) ## Build cpu and cpud binaries
	@echo "Verifying built binaries..."
	@ls -la $(BINARIES_DIR)/
	@echo ""
	@echo "CPU binary info:"
	@file $(CPU_BINARY)
	@echo "CPUD binary info:"
	@file $(CPUD_BINARY)
	@echo ""
	@echo "Binary sizes:"
	@du -h $(BINARIES_DIR)/*

$(INITRAMFS_FILE): $(CPUD_BINARY) $(UROOT_BIN)
	@echo "Creating u-root initramfs with cpud as init..."
	@rm -f $(INITRAMFS_DIR)/*
	@echo "Building initramfs with u-root..."
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) ../../u-root-bin -format=cpio -o ../../initramfs/cpud-initramfs.cpio \
		-initcmd="cpud" \
		./cmds/cpud \
		../u-root/cmds/core/ls \
		../u-root/cmds/core/ip \
		../u-root/cmds/core/mount \
		../u-root/cmds/core/mkdir \
		../u-root/cmds/core/gosh
	@echo "Compressing initramfs..."
	@gzip -9 $(INITRAMFS_DIR)/cpud-initramfs.cpio
	@echo "Initramfs created successfully:"
	@ls -la $(INITRAMFS_DIR)/

initramfs: $(INITRAMFS_FILE) ## Build initramfs with cpud as init
	@echo "Initramfs info:"
	@ls -la $(INITRAMFS_DIR)/
	@echo "Initramfs size:"
	@du -h $(INITRAMFS_DIR)/*

build: all ## Alias for 'all' target

install: $(CPU_BINARY) $(CPUD_BINARY) ## Install binaries to /usr/local/bin
	@echo "Installing CPU binaries to /usr/local/bin..."
	@if [ "$$EUID" -eq 0 ]; then \
		SUDO=""; \
	else \
		SUDO="sudo"; \
	fi; \
	$$SUDO cp $(CPU_BINARY) /usr/local/bin/; \
	$$SUDO cp $(CPUD_BINARY) /usr/local/bin/; \
	$$SUDO chmod +x /usr/local/bin/cpu /usr/local/bin/cpud
	@echo "Installation complete!"
	@echo "You can now run 'cpu -h' or 'cpud -h' from anywhere"

clean: ## Remove all build artifacts
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned."

distclean: clean ## Remove all build artifacts and cloned repositories
	@echo "Performing deep clean..."

show-versions: repos ## Show version information
	@echo "=== Version Information ==="
	@echo "Go version: $(shell go version | cut -d' ' -f3 | sed 's/go//')"
	@if [ -d "$(CPU_REPO)" ]; then \
		echo "CPU version: $$(cd $(CPU_REPO) && git describe --tags --always)"; \
	else \
		echo "CPU version: not available (repositories not cloned)"; \
	fi

list-cpio: $(INITRAMFS_FILE) ## List contents of the initramfs CPIO archive
	@echo "Contents of initramfs CPIO archive:"
	@gzip -dc $(INITRAMFS_FILE) | cpio -tv

status: ## Show build status
	@echo "=== Build Status ==="
	@echo "Build directory: $(if $(wildcard $(BUILD_DIR)),✓ exists,✗ missing)"
	@echo "CPU repository: $(if $(wildcard $(CPU_REPO)),✓ cloned,✗ not cloned)"
	@echo "U-root repository: $(if $(wildcard $(UROOT_REPO)),✓ cloned,✗ not cloned)"
	@echo "U-root binary: $(if $(wildcard $(UROOT_BIN)),✓ built,✗ not built)"
	@echo "CPU binary: $(if $(wildcard $(CPU_BINARY)),✓ built,✗ not built)"
	@echo "CPUD binary: $(if $(wildcard $(CPUD_BINARY)),✓ built,✗ not built)"
	@echo "Initramfs: $(if $(wildcard $(INITRAMFS_FILE)),✓ built,✗ not built)"

summary: all ## Build everything and show summary
	@echo ""
	@echo "=== Build Complete ==="
	@echo "Binaries are available in the '$(BINARIES_DIR)/' directory:"
	@ls -la $(BINARIES_DIR)/
	@echo ""
	@echo "Initramfs is available in the '$(INITRAMFS_DIR)/' directory:"
	@ls -la $(INITRAMFS_DIR)/
	@echo ""
	@echo "To use the binaries on an aarch64 system:"
	@echo "1. Copy the binaries to your target system"
	@echo "2. Make them executable: chmod +x cpu cpud"
	@echo "3. Run them: ./cpu -h or ./cpud -h"
	@echo ""
	@echo "To use the initramfs:"
	@echo "1. Copy cpud-initramfs.cpio.gz to your boot system"
	@echo "2. Use as initrd with your kernel"
	@echo "3. Boot with: init=/init"
	@echo ""
	@echo "To list initramfs contents: make list-cpio"
