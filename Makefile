# Makefile for CPU Prebuilt Binaries
# This Makefile builds cpu and cpud binaries for multiple architectures

# Configuration
SHELL := /bin/bash
.PHONY: all clean build binaries initramfs install help all-architectures
.DEFAULT_GOAL := help

# Architecture configuration
# Supported: aarch64, x86_64
ARCH ?= aarch64
SUPPORTED_ARCHS := aarch64 x86_64

# Map ARCH to GOARCH
ifeq ($(ARCH),aarch64)
    GOARCH := arm64
else ifeq ($(ARCH),x86_64)
    GOARCH := amd64
else
    $(error Unsupported architecture: $(ARCH). Supported: $(SUPPORTED_ARCHS))
endif

# Directories
BUILD_DIR := build
BASE_BINARIES_DIR := $(BUILD_DIR)/binaries
BASE_INITRAMFS_DIR := $(BUILD_DIR)/initramfs
BINARIES_DIR := $(BASE_BINARIES_DIR)/$(ARCH)
INITRAMFS_DIR := $(BASE_INITRAMFS_DIR)/$(ARCH)
REPOS_DIR := $(BUILD_DIR)/repos
CPU_REPO := $(REPOS_DIR)/cpu
UROOT_REPO := $(REPOS_DIR)/u-root

# Go configuration
GOOS := linux
CGO_ENABLED := 0

# Files
UROOT_BIN := $(BUILD_DIR)/u-root-bin
GO_WORK := $(BUILD_DIR)/go.work
CPU_BINARY := $(BINARIES_DIR)/cpu
CPUD_BINARY := $(BINARIES_DIR)/cpud
INITRAMFS_FILE := $(INITRAMFS_DIR)/cpud-initramfs.cpio.gz
BUILD_INFO := $(BINARIES_DIR)/BUILD_INFO.txt
SSH_PRIVATE_KEY := $(BINARIES_DIR)/identity
SSH_PUBLIC_KEY := $(BINARIES_DIR)/identity.pub

# Version detection
CPU_VERSION := $(shell cd $(CPU_REPO) 2>/dev/null && git describe --tags --always 2>/dev/null || echo "unknown")
GO_VERSION := $(shell go version 2>/dev/null || echo "go version unknown")

help: ## Show this help message
	@echo "=== CPU Prebuilt Build System ==="
	@echo "This Makefile builds cpu and cpud binaries for multiple architectures"
	@echo ""
	@echo "Architecture configuration:"
	@echo "  Current ARCH: $(ARCH) (GOARCH: $(GOARCH))"
	@echo "  Supported: $(SUPPORTED_ARCHS)"
	@echo "  Usage: make ARCH=x86_64 all"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'

all: binaries initramfs ## Build everything (binaries and initramfs) for current ARCH

all-architectures: ## Build binaries and initramfs for all supported architectures
	@echo "Building for all supported architectures: $(SUPPORTED_ARCHS)"
	@for arch in $(SUPPORTED_ARCHS); do \
		echo "=== Building for $$arch ==="; \
		$(MAKE) ARCH=$$arch all; \
		echo ""; \
	done

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

$(SSH_PRIVATE_KEY): | $(BUILD_DIR)
	@echo "Generating default SSH keys for CPU ($(ARCH))..."
	@mkdir -p $(BINARIES_DIR)
	@if [ ! -f "$(SSH_PRIVATE_KEY)" ]; then \
		ssh-keygen -t rsa -b 4096 -f $(SSH_PRIVATE_KEY) -N "" -C "cpu-default-key-$(ARCH)"; \
		echo "SSH keys generated for $(ARCH):"; \
		echo "  Private key: $(SSH_PRIVATE_KEY)"; \
		echo "  Public key: $(SSH_PUBLIC_KEY)"; \
	else \
		echo "SSH keys already exist for $(ARCH), skipping generation"; \
	fi

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
	@echo "Building cpu binary for $(ARCH) (GOARCH: $(GOARCH))..."
	@cd $(CPU_REPO) && go mod download
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o ../../binaries/$(ARCH)/cpu ./cmds/cpu

$(CPUD_BINARY): $(GO_WORK) $(UROOT_BIN)
	@echo "Building cpud binary for $(ARCH) (GOARCH: $(GOARCH))..."
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) CGO_ENABLED=$(CGO_ENABLED) go build -o ../../binaries/$(ARCH)/cpud ./cmds/cpud

$(BUILD_INFO): $(CPU_BINARY) $(CPUD_BINARY) $(SSH_PRIVATE_KEY)
	@echo "Creating build info for $(ARCH)..."
	@cd $(CPU_REPO) && CPU_VERSION=$$(git describe --tags --always) && \
	echo "U-Root CPU Binaries for $(ARCH) (Local Build)" > ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Built on: $$(date -u)" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "CPU version: $$CPU_VERSION" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Target architecture: $(GOOS)/$(GOARCH) ($(ARCH))" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Go version: $(GO_VERSION)" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Files in this archive:" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "- cpu: CPU client binary" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "- cpud: CPU daemon binary" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "- identity: Default SSH private key" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "- identity.pub: Default SSH public key" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "- cpud-initramfs.cpio.gz: U-root initramfs with cpud as init" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Usage:" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  ./cpu -h    # Show CPU client help" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  ./cpud -h   # Show CPU daemon help" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "SSH Keys:" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  Default SSH keys are provided for convenience" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  Private key: identity" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  Public key: identity.pub (also embedded in initramfs)" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  WARNING: These are default keys - generate your own for production!" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Initramfs usage:" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  Use cpud-initramfs.cpio.gz as initrd with Linux kernel" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  Boot parameters: init=/init" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  SSH public key is embedded at /etc/identity.pub" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "  cpud automatically uses the embedded SSH key for authentication" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "" >> ../../binaries/$(ARCH)/BUILD_INFO.txt && \
	echo "Build system: Makefile (multi-architecture)" >> ../../binaries/$(ARCH)/BUILD_INFO.txt

binaries: check-go $(CPU_BINARY) $(CPUD_BINARY) $(BUILD_INFO) $(SSH_PRIVATE_KEY) ## Build cpu and cpud binaries for current ARCH
	@echo "Verifying built binaries for $(ARCH)..."
	@ls -la $(BINARIES_DIR)/
	@echo ""
	@echo "CPU binary info:"
	@file $(CPU_BINARY)
	@echo "CPUD binary info:"
	@file $(CPUD_BINARY)
	@echo ""
	@echo "SSH key info:"
	@echo "Private key: $(SSH_PRIVATE_KEY)"
	@echo "Public key: $(SSH_PUBLIC_KEY)"
	@echo ""
	@echo "Binary sizes:"
	@du -h $(BINARIES_DIR)/*

$(INITRAMFS_FILE): $(CPUD_BINARY) $(UROOT_BIN) $(SSH_PUBLIC_KEY)
	@echo "Creating u-root initramfs with cpud as init for $(ARCH)..."
	@rm -f $(INITRAMFS_DIR)/*
	@echo "Building initramfs with u-root..."
	@cd $(CPU_REPO) && GOOS=$(GOOS) GOARCH=$(GOARCH) ../../u-root-bin -format=cpio -o ../../initramfs/$(ARCH)/cpud-initramfs.cpio \
		-files "../../binaries/$(ARCH)/identity.pub:key.pub" \
		-initcmd="cpud" \
		./cmds/cpud \
		../u-root/cmds/core/ls \
		../u-root/cmds/core/ip \
		../u-root/cmds/core/mount \
		../u-root/cmds/core/mkdir \
		../u-root/cmds/core/gosh
	@echo "Compressing initramfs..."
	@gzip -9 $(INITRAMFS_DIR)/cpud-initramfs.cpio
	@echo "Initramfs created successfully for $(ARCH):"
	@ls -la $(INITRAMFS_DIR)/

initramfs: $(INITRAMFS_FILE) ## Build initramfs with cpud as init for current ARCH
	@echo "Initramfs info for $(ARCH):"
	@ls -la $(INITRAMFS_DIR)/
	@echo "Initramfs size:"
	@du -h $(INITRAMFS_DIR)/*

compile: binaries initramfs ## Build everything (alternative to 'all')

install: $(CPU_BINARY) $(CPUD_BINARY) ## Install binaries to /usr/local/bin
	@echo "Installing CPU binaries for $(ARCH) to /usr/local/bin..."
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

clean-arch: ## Remove build artifacts for current ARCH only
	@echo "Cleaning build artifacts for $(ARCH)..."
	@rm -rf $(BINARIES_DIR) $(INITRAMFS_DIR)
	@echo "Build artifacts for $(ARCH) cleaned."

distclean: clean ## Remove all build artifacts and cloned repositories
	@echo "Performing deep clean..."

show-versions: repos ## Show version information
	@echo "=== Version Information ==="
	@echo "Go version: $(shell go version | cut -d' ' -f3 | sed 's/go//')"
	@echo "Current ARCH: $(ARCH) (GOARCH: $(GOARCH))"
	@if [ -d "$(CPU_REPO)" ]; then \
		echo "CPU version: $$(cd $(CPU_REPO) && git describe --tags --always)"; \
	else \
		echo "CPU version: not available (repositories not cloned)"; \
	fi

list-cpio: $(INITRAMFS_FILE) ## List contents of the initramfs CPIO archive for current ARCH
	@echo "Contents of initramfs CPIO archive for $(ARCH):"
	@gzip -dc $(INITRAMFS_FILE) | cpio -tv

status: ## Show build status for current ARCH
	@echo "=== Build Status for $(ARCH) ==="
	@echo "Build directory: $(if $(wildcard $(BUILD_DIR)),✓ exists,✗ missing)"
	@echo "CPU repository: $(if $(wildcard $(CPU_REPO)),✓ cloned,✗ not cloned)"
	@echo "U-root repository: $(if $(wildcard $(UROOT_REPO)),✓ cloned,✗ not cloned)"
	@echo "U-root binary: $(if $(wildcard $(UROOT_BIN)),✓ built,✗ not built)"
	@echo "CPU binary ($(ARCH)): $(if $(wildcard $(CPU_BINARY)),✓ built,✗ not built)"
	@echo "CPUD binary ($(ARCH)): $(if $(wildcard $(CPUD_BINARY)),✓ built,✗ not built)"
	@echo "Initramfs ($(ARCH)): $(if $(wildcard $(INITRAMFS_FILE)),✓ built,✗ not built)"

status-all: ## Show build status for all architectures
	@echo "=== Build Status for All Architectures ==="
	@for arch in $(SUPPORTED_ARCHS); do \
		echo "--- $$arch ---"; \
		$(MAKE) ARCH=$$arch status | grep -E "(CPU binary|CPUD binary|Initramfs)"; \
		echo ""; \
	done

summary: all ## Build everything and show summary for current ARCH
	@echo ""
	@echo "=== Build Complete for $(ARCH) ==="
	@echo "Binaries are available in the '$(BINARIES_DIR)/' directory:"
	@ls -la $(BINARIES_DIR)/
	@echo ""
	@echo "Initramfs is available in the '$(INITRAMFS_DIR)/' directory:"
	@ls -la $(INITRAMFS_DIR)/
	@echo ""
	@echo "To use the binaries on an $(ARCH) system:"
	@echo "1. Copy the binaries to your target system"
	@echo "2. Make them executable: chmod +x cpu cpud"
	@echo "3. Run them: ./cpu -h or ./cpud -h"
	@echo ""
	@echo "To use the initramfs:"
	@echo "1. Copy cpud-initramfs.cpio.gz to your boot system"
	@echo "2. Use as initrd with your kernel"
	@echo "3. Boot with: init=/init"
	@echo ""
	@echo "To list initramfs contents: make ARCH=$(ARCH) list-cpio"

summary-all: all-architectures ## Build everything and show summary for all architectures
	@echo ""
	@echo "=== Build Complete for All Architectures ==="
	@for arch in $(SUPPORTED_ARCHS); do \
		echo "--- $$arch ---"; \
		echo "Binaries: $(BASE_BINARIES_DIR)/$$arch/"; \
		ls -la $(BASE_BINARIES_DIR)/$$arch/ 2>/dev/null || echo "  (not built)"; \
		echo "Initramfs: $(BASE_INITRAMFS_DIR)/$$arch/"; \
		ls -la $(BASE_INITRAMFS_DIR)/$$arch/ 2>/dev/null || echo "  (not built)"; \
		echo ""; \
	done
