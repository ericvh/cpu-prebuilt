#!/bin/bash
set -e

# Local build script for CPU binaries
# This script mirrors what the GitHub Action does

# Check for clean argument
if [ "$1" = "clean" ]; then
    echo "Cleaning build directory..."
    rm -rf build/
    echo "Build directory cleaned."
    exit 0
fi

echo "=== CPU Prebuilt Local Build Script ==="
echo "This script builds cpu and cpud binaries for aarch64"
echo "Use './build.sh clean' to remove build artifacts"
echo

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed. Please install Go 1.21 or later."
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | cut -d' ' -f3 | sed 's/go//')
echo "Using Go version: $GO_VERSION"

# Create output directory
mkdir -p build/binaries build/initramfs build/repos
rm -f build/binaries/*
rm -f build/initramfs/*

echo "Cloning u-root/cpu repository..."
if [ -d "build/repos/cpu" ]; then
    echo "cpu directory already exists, updating..."
    cd build/repos/cpu
    git pull
    cd ../../..
else
    git clone https://github.com/u-root/cpu.git build/repos/cpu
fi

echo "Cloning u-root/u-root repository..."
if [ -d "build/repos/u-root" ]; then
    echo "u-root directory already exists, updating..."
    cd build/repos/u-root
    git pull
    cd ../../..
else
    git clone https://github.com/u-root/u-root.git build/repos/u-root
fi

# Set up Go workspace
echo "Setting up Go workspace..."
cat > build/go.work << EOF
go 1.24.0

use ./repos/cpu
use ./repos/u-root
EOF

cd build/repos/cpu

# Get version info
CPU_VERSION=$(git describe --tags --always)
echo "Building u-root/cpu version: $CPU_VERSION"

# Download dependencies
echo "Downloading Go dependencies..."
go mod download

# Build u-root from source
echo "Building u-root from source..."
cd ../u-root
go build -o ../../u-root-bin ./
cd ../cpu

# Build cpu binary
echo "Building cpu binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../../binaries/cpu ./cmds/cpu

# Build cpud binary
echo "Building cpud binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../../binaries/cpud ./cmds/cpud

# Create u-root initramfs with cpud
echo "Creating u-root initramfs with cpud as init..."

# Build the initramfs with cpud bundled in as init
echo "Building initramfs with u-root..."
GOOS=linux GOARCH=arm64 ../../u-root-bin -format=cpio -o ../../initramfs/cpud-initramfs.cpio \
    -initcmd="cpud" \
    ./cmds/cpud \
    ../u-root/cmds/core/ls \
    ../u-root/cmds/core/ip \
    ../u-root/cmds/core/mount \
    ../u-root/cmds/core/mkdir \
    ../u-root/cmds/core/gosh

echo "Compressing initramfs..."
gzip -9 ../../initramfs/cpud-initramfs.cpio

echo "Initramfs created successfully:"
ls -la ../../initramfs/

cd ../../..

# Verify binaries
echo "Verifying built binaries..."
ls -la build/binaries/
echo
echo "CPU binary info:"
file build/binaries/cpu
echo "CPUD binary info:"
file build/binaries/cpud
echo
echo "Binary sizes:"
du -h build/binaries/*
echo
echo "Initramfs info:"
ls -la build/initramfs/
echo "Initramfs size:"
du -h build/initramfs/*

# Create build info
echo "Creating build info..."
cd build/binaries
cat > BUILD_INFO.txt << EOF
U-Root CPU Binaries for aarch64 (Local Build)
Built on: $(date -u)
CPU version: $CPU_VERSION
Target architecture: linux/arm64
Go version: $(go version)

Files in this archive:
- cpu: CPU client binary
- cpud: CPU daemon binary
- cpud-initramfs.cpio.gz: U-root initramfs with cpud as init

Usage:
  ./cpu -h    # Show CPU client help
  ./cpud -h   # Show CPU daemon help

Initramfs usage:
  Use cpud-initramfs.cpio.gz as initrd with Linux kernel
  Boot parameters: init=/init

Build script: ../build.sh
EOF

cd ../..

echo
echo "=== Build Complete ==="
echo "Binaries are available in the 'build/binaries/' directory:"
ls -la build/binaries/
echo
echo "Initramfs is available in the 'build/initramfs/' directory:"
ls -la build/initramfs/
echo
echo "To use the binaries on an aarch64 system:"
echo "1. Copy the binaries to your target system"
echo "2. Make them executable: chmod +x cpu cpud"
echo "3. Run them: ./cpu -h or ./cpud -h"
echo
echo "To use the initramfs:"
echo "1. Copy cpud-initramfs.cpio.gz to your boot system"
echo "2. Use as initrd with your kernel"
echo "3. Boot with: init=/init"
