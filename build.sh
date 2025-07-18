#!/bin/bash
set -e

# Local build script for CPU binaries
# This script mirrors what the GitHub Action does

echo "=== CPU Prebuilt Local Build Script ==="
echo "This script builds cpu and cpud binaries for aarch64"
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
mkdir -p binaries
rm -f binaries/*

echo "Cloning u-root/cpu repository..."
if [ -d "cpu" ]; then
    echo "cpu directory already exists, updating..."
    cd cpu
    git pull
    cd ..
else
    git clone https://github.com/u-root/cpu.git
fi

cd cpu

# Get version info
CPU_VERSION=$(git describe --tags --always)
echo "Building u-root/cpu version: $CPU_VERSION"

# Download dependencies
echo "Downloading Go dependencies..."
go mod download

# Build cpu binary
echo "Building cpu binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../binaries/cpu ./cmds/cpu

# Build cpud binary
echo "Building cpud binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../binaries/cpud ./cmds/cpud

cd ..

# Verify binaries
echo "Verifying built binaries..."
ls -la binaries/
echo
echo "CPU binary info:"
file binaries/cpu
echo "CPUD binary info:"
file binaries/cpud
echo
echo "Binary sizes:"
du -h binaries/*

# Create build info
echo "Creating build info..."
cd binaries
cat > BUILD_INFO.txt << EOF
U-Root CPU Binaries for aarch64 (Local Build)
Built on: $(date -u)
CPU version: $CPU_VERSION
Target architecture: linux/arm64
Go version: $(go version)

Files in this archive:
- cpu: CPU client binary
- cpud: CPU daemon binary

Usage:
  ./cpu -h    # Show CPU client help
  ./cpud -h   # Show CPU daemon help

Build script: ../build.sh
EOF

cd ..

echo
echo "=== Build Complete ==="
echo "Binaries are available in the 'binaries/' directory:"
ls -la binaries/
echo
echo "To use the binaries on an aarch64 system:"
echo "1. Copy the binaries to your target system"
echo "2. Make them executable: chmod +x cpu cpud"
echo "3. Run them: ./cpu -h or ./cpud -h"
