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

# Install u-root for initramfs creation
echo "Installing u-root..."
go install github.com/u-root/u-root@latest

# Build cpu binary
echo "Building cpu binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../binaries/cpu ./cmds/cpu

# Build cpud binary
echo "Building cpud binary for aarch64..."
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o ../binaries/cpud ./cmds/cpud

# Create u-root initramfs with cpud
echo "Creating u-root initramfs with cpud as init..."
mkdir -p ../initramfs

# Create cpud init script
cat > ../initramfs/cpud-init.go << 'EOF'
package main

import (
    "fmt"
    "log"
    "os"
    "os/exec"
    "syscall"
    "time"
)

func main() {
    fmt.Println("CPU initramfs starting...")
    
    // Mount essential filesystems
    if err := syscall.Mount("proc", "/proc", "proc", 0, ""); err != nil {
        log.Printf("Failed to mount /proc: %v", err)
    }
    if err := syscall.Mount("sysfs", "/sys", "sysfs", 0, ""); err != nil {
        log.Printf("Failed to mount /sys: %v", err)
    }
    if err := syscall.Mount("devtmpfs", "/dev", "devtmpfs", 0, ""); err != nil {
        log.Printf("Failed to mount /dev: %v", err)
    }
    
    // Wait a moment for system to stabilize
    time.Sleep(2 * time.Second)
    
    fmt.Println("Starting cpud daemon...")
    
    // Start cpud as the main process
    cmd := exec.Command("/bin/cpud", os.Args[1:]...)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    cmd.Stdin = os.Stdin
    
    if err := cmd.Run(); err != nil {
        log.Fatalf("cpud failed: %v", err)
    }
}
EOF

# Build the initramfs with cpud and our init
echo "Building initramfs with u-root..."
GOOS=linux GOARCH=arm64 u-root -format=cpio -o ../initramfs/cpud-initramfs.cpio \
    -files "../binaries/cpud:bin/cpud" \
    -initcmd="../initramfs/cpud-init.go" \
    core

echo "Compressing initramfs..."
gzip -9 ../initramfs/cpud-initramfs.cpio

echo "Initramfs created successfully:"
ls -la ../initramfs/

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
echo
echo "Initramfs info:"
ls -la initramfs/
echo "Initramfs size:"
du -h initramfs/*

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
- cpud-initramfs.cpio.gz: U-root initramfs with cpud as init

Usage:
  ./cpu -h    # Show CPU client help
  ./cpud -h   # Show CPU daemon help

Initramfs usage:
  Use cpud-initramfs.cpio.gz as initrd with Linux kernel
  Boot parameters: init=/init

Build script: ../build.sh
EOF

cd ..

echo
echo "=== Build Complete ==="
echo "Binaries are available in the 'binaries/' directory:"
ls -la binaries/
echo
echo "Initramfs is available in the 'initramfs/' directory:"
ls -la initramfs/
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
