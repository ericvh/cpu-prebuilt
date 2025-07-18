# CPU Prebuilt Binaries

This project provides prebuilt binaries for u-root/cpu and u-root/cpud targeting aarch64 architecture.

## Quick Install

```bash
# Install latest release
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash

# Install specific version
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash -s -- -v v1.0.0

# Install to custom directory
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash -s -- -d ~/.local/bin
```

## Distribution Methods

### 🚀 **GitHub Releases** (Recommended)
- **Individual binaries**: Download `cpu` and `cpud` directly
- **Complete archive**: Download `cpu-binaries-aarch64-{version}.tar.gz`
- **Checksums included**: SHA256 verification for security
- **Easy installation**: Use the `install.sh` script

### 📦 **GitHub Packages (Container Registry)**
- **Container images**: Pull from `ghcr.io/ericvh/cpu-prebuilt`
- **Multi-architecture**: Supports linux/arm64
- **Scratch-based**: Minimal container size

### 🛠️ **GitHub Actions Artifacts**
- **Development builds**: Available for every commit
- **90-day retention**: Temporary artifacts for testing

## Installation Options

### Option 1: Install Script (Easiest)
```bash
# Download and run installer
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash

# Or download first, then run
wget https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh
chmod +x install.sh
./install.sh --help
```

### Option 2: Manual Download from Releases
```bash
# Download individual binaries (replace VERSION with actual version)
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v1.0.0/cpu
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v1.0.0/cpud

# Make executable
chmod +x cpu cpud

# Verify checksums (optional)
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v1.0.0/cpu.sha256
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v1.0.0/cpud.sha256
sha256sum -c cpu.sha256 cpud.sha256
```

### Option 3: Download Complete Archive
```bash
# Download and verify archive
VERSION="v1.0.0"  # Replace with desired version
wget https://github.com/ericvh/cpu-prebuilt/releases/download/$VERSION/cpu-binaries-aarch64-$VERSION.tar.gz
wget https://github.com/ericvh/cpu-prebuilt/releases/download/$VERSION/cpu-binaries-aarch64-$VERSION.tar.gz.sha256
sha256sum -c cpu-binaries-aarch64-$VERSION.tar.gz.sha256

# Extract
tar -xzf cpu-binaries-aarch64-$VERSION.tar.gz
chmod +x cpu cpud
```

### Option 4: Container Usage
```bash
# Pull the container
docker pull ghcr.io/ericvh/cpu-prebuilt:latest

# Run binaries from container
docker run --rm ghcr.io/ericvh/cpu-prebuilt:latest /usr/local/bin/cpu -h
docker run --rm ghcr.io/ericvh/cpu-prebuilt:latest /usr/local/bin/cpud -h

# Extract binaries from container
docker create --name cpu-container ghcr.io/ericvh/cpu-prebuilt:latest
docker cp cpu-container:/usr/local/bin/cpu ./cpu
docker cp cpu-container:/usr/local/bin/cpud ./cpud
docker rm cpu-container
```

## What this does

This repository uses GitHub Actions to:
- Build `cpu` and `cpud` from the [u-root/cpu](https://github.com/u-root/cpu) project
- Cross-compile for aarch64 (ARM64) architecture
- Package the binaries as downloadable artifacts
- Create GitHub releases with checksums
- Publish container images to GitHub Packages
- Automatically rebuild on new releases or manual triggers

## Usage

1. **View available releases**: Go to the [Releases](../../releases) page
2. **Auto-install**: Use the install script (recommended)
3. **Manual download**: Download individual binaries or archives
4. **Container usage**: Pull from GitHub Packages
5. **Development builds**: Download from [Actions](../../actions) artifacts

## Creating Releases

### Automatic (Recommended)
- Push a git tag: `git tag v1.0.0 && git push origin v1.0.0`
- Creates a release automatically with all binaries and checksums

### Manual
- Go to [Actions](../../actions) tab
- Run "Build CPU Binaries" workflow
- Enable "Create a release after building"
- Specify release tag (e.g., `v1.0.0`)

## Binaries Included

- **cpu**: The CPU client binary for connecting to remote systems
- **cpud**: The CPU daemon binary for hosting remote connections

## Architecture

- **Target Architecture**: aarch64 (ARM64)
- **Source**: [u-root/cpu](https://github.com/u-root/cpu)
- **Build Tool**: Go cross-compilation
- **Distribution**: GitHub Releases, GitHub Packages, Artifacts

## Security

- **Checksums**: SHA256 checksums provided for all binaries
- **Verification**: Install script automatically verifies checksums
- **Reproducible**: Builds are reproducible from source

## License

The binaries are built from u-root/cpu which is licensed under the BSD 3-Clause License.
