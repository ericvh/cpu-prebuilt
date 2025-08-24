#!/bin/bash
set -e

# CPU Binaries Installer Script
# This script helps users install CPU binaries from GitHub releases

REPO="ericvh/cpu-prebuilt"
INSTALL_DIR="/usr/local/bin"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Architecture detection
detect_arch() {
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}" >&2
            echo -e "${YELLOW}Supported architectures: x86_64, aarch64${NC}" >&2
            exit 1
            ;;
    esac
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install CPU binaries from GitHub releases or local build"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Install specific version (e.g., v1.0.0)"
    echo "  -a, --arch ARCH         Install for specific architecture (aarch64, x86_64)"
    echo "  -d, --dir DIRECTORY      Install to custom directory (default: $INSTALL_DIR)"
    echo "  -l, --list              List available releases"
    echo "  --local                 Install from local build directory"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Supported architectures: aarch64 (ARM64), x86_64 (AMD64)"
    echo "Current system architecture: $(detect_arch)"
    echo ""
    echo "Examples:"
    echo "  $0                      # Install latest release for current architecture"
    echo "  $0 -v v1.0.0           # Install specific version for current architecture"
    echo "  $0 -a x86_64           # Install for x86_64 architecture"
    echo "  $0 -d ~/.local/bin      # Install to custom directory"
    echo "  $0 --local              # Install from local build"
    echo "  $0 -l                   # List available releases"
}

list_releases() {
    echo -e "${YELLOW}Available releases:${NC}"
    curl -s "https://api.github.com/repos/$REPO/releases" | \
        grep -E '"tag_name"' | \
        head -10 | \
        sed 's/.*"tag_name": "\(.*\)".*/\1/' | \
        while read -r tag; do
            echo "  $tag"
        done
    echo ""
    echo -e "${YELLOW}Note: Each release includes binaries for aarch64 and x86_64 architectures${NC}"
}

get_latest_release() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
        grep -E '"tag_name"' | \
        sed 's/.*"tag_name": "\(.*\)".*/\1/'
}

install_binaries() {
    local version="$1"
    local install_dir="$2"
    local arch="$3"
    
    echo -e "${YELLOW}Installing CPU binaries version $version for $arch to $install_dir${NC}"
    
    # Create install directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Download binaries with architecture suffix
    echo "Downloading CPU client binary for $arch..."
    curl -L -o "$TEMP_DIR/cpu" "https://github.com/$REPO/releases/download/$version/cpu-$arch"
    
    echo "Downloading CPU daemon binary for $arch..."
    curl -L -o "$TEMP_DIR/cpud" "https://github.com/$REPO/releases/download/$version/cpud-$arch"
    
    # Download checksums for verification
    echo "Downloading checksums..."
    curl -L -o "$TEMP_DIR/cpu.sha256" "https://github.com/$REPO/releases/download/$version/cpu-$arch.sha256"
    curl -L -o "$TEMP_DIR/cpud.sha256" "https://github.com/$REPO/releases/download/$version/cpud-$arch.sha256"
    
    # Verify checksums (need to adjust for actual vs downloaded filenames)
    echo "Verifying checksums..."
    cd "$TEMP_DIR"
    # Create temporary checksum files with correct filenames
    sed "s/cpu-$arch/cpu/" cpu.sha256 > cpu_adjusted.sha256
    sed "s/cpud-$arch/cpud/" cpud.sha256 > cpud_adjusted.sha256
    
    if sha256sum -c cpu_adjusted.sha256 && sha256sum -c cpud_adjusted.sha256; then
        echo -e "${GREEN}✓ Checksums verified${NC}"
    else
        echo -e "${RED}✗ Checksum verification failed${NC}"
        exit 1
    fi
    
    # Make binaries executable
    chmod +x cpu cpud
    
    # Install binaries
    echo "Installing binaries..."
    if [ -w "$install_dir" ]; then
        cp cpu cpud "$install_dir/"
    else
        echo "Installing to $install_dir requires sudo..."
        sudo cp cpu cpud "$install_dir/"
    fi
    
    echo -e "${GREEN}✓ CPU binaries installed successfully${NC}"
    echo ""
    echo "Installed files:"
    echo "  $install_dir/cpu (for $arch)"
    echo "  $install_dir/cpud (for $arch)"
    echo ""
    echo "Usage:"
    echo "  cpu -h    # Show CPU client help"
    echo "  cpud -h   # Show CPU daemon help"
}

install_local_binaries() {
    local install_dir="$1"
    local arch="$2"
    
    echo -e "${YELLOW}Installing CPU binaries for $arch from local build to $install_dir${NC}"
    
    # Check for architecture-specific build first
    local build_path="build/binaries/$arch"
    if [ -f "$build_path/cpu" ] && [ -f "$build_path/cpud" ]; then
        echo "Found architecture-specific build for $arch"
        local cpu_src="$build_path/cpu"
        local cpud_src="$build_path/cpud"
    else
        # Fall back to legacy build directory (for backward compatibility)
        build_path="build/binaries"
        if [ -f "$build_path/cpu" ] && [ -f "$build_path/cpud" ]; then
            echo -e "${YELLOW}Warning: Using legacy build directory. Consider rebuilding with 'make ARCH=$arch all'${NC}"
            local cpu_src="$build_path/cpu"
            local cpud_src="$build_path/cpud"
        else
            echo -e "${RED}Error: Local build not found for $arch${NC}"
            echo "Available architectures:"
            for arch_dir in build/binaries/*/; do
                if [ -d "$arch_dir" ]; then
                    arch_name=$(basename "$arch_dir")
                    if [ -f "$arch_dir/cpu" ] && [ -f "$arch_dir/cpud" ]; then
                        echo "  $arch_name"
                    fi
                fi
            done
            echo ""
            echo "To build for $arch, run: make ARCH=$arch all"
            exit 1
        fi
    fi
    
    # Create install directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Copy binaries
    echo "Installing CPU client binary..."
    cp "$cpu_src" "$install_dir/cpu"
    
    echo "Installing CPU daemon binary..."
    cp "$cpud_src" "$install_dir/cpud"
    
    # Make executable
    chmod +x "$install_dir/cpu" "$install_dir/cpud"
    
    echo -e "${GREEN}✓ Local installation complete${NC}"
    echo ""
    echo "Installed binaries:"
    echo "  $install_dir/cpu"
    echo "  $install_dir/cpud"
    echo ""
    echo "Usage:"
    echo "  cpu -h    # Show CPU client help"
    echo "  cpud -h   # Show CPU daemon help"
}

# Parse command line arguments
VERSION=""
ARCH=""
LIST_RELEASES=false
LOCAL_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -a|--arch)
            ARCH="$2"
            shift 2
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -l|--list)
            LIST_RELEASES=true
            shift
            ;;
        --local)
            LOCAL_INSTALL=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Set default architecture if not specified
if [ -z "$ARCH" ]; then
    ARCH=$(detect_arch)
    echo -e "${YELLOW}Auto-detected architecture: $ARCH${NC}"
else
    # Validate specified architecture
    case $ARCH in
        aarch64|x86_64)
            echo -e "${YELLOW}Using specified architecture: $ARCH${NC}"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
            echo -e "${YELLOW}Supported architectures: aarch64, x86_64${NC}"
            exit 1
            ;;
    esac
fi

# Main logic
if [ "$LIST_RELEASES" = true ]; then
    list_releases
    exit 0
fi

# Handle local installation
if [ "$LOCAL_INSTALL" = true ]; then
    install_local_binaries "$INSTALL_DIR" "$ARCH"
    exit 0
fi

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

# Get version to install
if [ -z "$VERSION" ]; then
    echo "Getting latest release..."
    VERSION=$(get_latest_release)
    if [ -z "$VERSION" ]; then
        echo -e "${RED}Error: Could not determine latest release${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Installing CPU binaries version: $VERSION for architecture: $ARCH${NC}"

# Install binaries
install_binaries "$VERSION" "$INSTALL_DIR" "$ARCH"

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation complete!${NC}"
