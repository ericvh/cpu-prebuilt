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

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install CPU binaries from GitHub releases or local build"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Install specific version (e.g., v1.0.0)"
    echo "  -d, --dir DIRECTORY      Install to custom directory (default: $INSTALL_DIR)"
    echo "  -l, --list              List available releases"
    echo "  --local                 Install from local build directory"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      # Install latest release"
    echo "  $0 -v v1.0.0           # Install specific version"
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
}

get_latest_release() {
    curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
        grep -E '"tag_name"' | \
        sed 's/.*"tag_name": "\(.*\)".*/\1/'
}

install_binaries() {
    local version="$1"
    local install_dir="$2"
    
    echo -e "${YELLOW}Installing CPU binaries version $version to $install_dir${NC}"
    
    # Create install directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Download binaries
    echo "Downloading CPU client binary..."
    curl -L -o "$TEMP_DIR/cpu" "https://github.com/$REPO/releases/download/$version/cpu"
    
    echo "Downloading CPU daemon binary..."
    curl -L -o "$TEMP_DIR/cpud" "https://github.com/$REPO/releases/download/$version/cpud"
    
    # Download checksums for verification
    echo "Downloading checksums..."
    curl -L -o "$TEMP_DIR/cpu.sha256" "https://github.com/$REPO/releases/download/$version/cpu.sha256"
    curl -L -o "$TEMP_DIR/cpud.sha256" "https://github.com/$REPO/releases/download/$version/cpud.sha256"
    
    # Verify checksums
    echo "Verifying checksums..."
    cd "$TEMP_DIR"
    if sha256sum -c cpu.sha256 && sha256sum -c cpud.sha256; then
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
    echo "  $install_dir/cpu"
    echo "  $install_dir/cpud"
    echo ""
    echo "Usage:"
    echo "  cpu -h    # Show CPU client help"
    echo "  cpud -h   # Show CPU daemon help"
}

install_local_binaries() {
    local install_dir="$1"
    
    echo -e "${YELLOW}Installing CPU binaries from local build to $install_dir${NC}"
    
    # Check if local build exists
    if [ ! -f "build/binaries/cpu" ] || [ ! -f "build/binaries/cpud" ]; then
        echo -e "${RED}Error: Local build not found in build/binaries/${NC}"
        echo "Please run './build.sh' first to build the binaries"
        exit 1
    fi
    
    # Create install directory if it doesn't exist
    mkdir -p "$install_dir"
    
    # Copy binaries
    echo "Installing CPU client binary..."
    cp "build/binaries/cpu" "$install_dir/"
    
    echo "Installing CPU daemon binary..."
    cp "build/binaries/cpud" "$install_dir/"
    
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
LIST_RELEASES=false
LOCAL_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
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

# Main logic
if [ "$LIST_RELEASES" = true ]; then
    list_releases
    exit 0
fi

# Handle local installation
if [ "$LOCAL_INSTALL" = true ]; then
    install_local_binaries "$INSTALL_DIR"
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

echo -e "${YELLOW}Installing CPU binaries version: $VERSION${NC}"

# Install binaries
install_binaries "$VERSION" "$INSTALL_DIR"

# Cleanup
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Installation complete!${NC}"
