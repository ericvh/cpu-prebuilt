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

### 🌟 **U-root Initramfs** (New!)
- **Boot to cpud**: Minimal Linux system that boots directly into cpud
- **Tiny footprint**: ~10-20MB compressed initramfs
- **No OS required**: Perfect for dedicated CPU servers
- **Quick boot**: 2-5 seconds to cpud ready
- **Raspberry Pi ready**: Simple Pi configuration included

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

### Option 5: Initramfs Boot (Minimal System)
```bash
# Download initramfs
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Verify checksum
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz.sha256
sha256sum -c cpud-initramfs.cpio.gz.sha256

# Use with kernel (QEMU example)
qemu-system-aarch64 \
  -kernel vmlinuz-aarch64 \
  -initrd cpud-initramfs.cpio.gz \
  -append "init=/init console=ttyAMA0" \
  -machine virt -cpu cortex-a57 -m 1024M -nographic \
  -netdev user,id=net0 -device virtio-net-device,netdev=net0

# Physical hardware: copy to /boot and update bootloader
sudo cp cpud-initramfs.cpio.gz /boot/
# Update GRUB/U-Boot configuration
```

## Local Development

### Building from Source
```bash
# Clone the repository
git clone https://github.com/ericvh/cpu-prebuilt.git
cd cpu-prebuilt

# Build binaries (requires Go 1.21+)
./build.sh

# Clean build artifacts
./build.sh clean

# Install locally built binaries
./install.sh --local
```

### Build Directory Structure
```
build/
├── binaries/          # Compiled binaries
│   ├── cpu
│   ├── cpud
│   └── BUILD_INFO.txt
├── initramfs/         # Initramfs files
│   └── cpud-initramfs.cpio.gz
├── repos/             # Source repositories
│   ├── cpu/           # u-root/cpu source
│   └── u-root/        # u-root/u-root source
├── go.work            # Go workspace file
└── u-root-bin         # Built u-root binary
```

All build artifacts are stored in the `build/` directory and excluded from git via `.gitignore`.

## What this does

This repository uses GitHub Actions to:
- Build `cpu` and `cpud` from the [u-root/cpu](https://github.com/u-root/cpu) project
- Cross-compile for aarch64 (ARM64) architecture
- Create u-root initramfs that boots directly into cpud
- Package the binaries as downloadable artifacts
- Create GitHub releases with checksums
- Publish container images to GitHub Packages
- Automatically rebuild on new releases or manual triggers

## Usage

1. **View available releases**: Go to the [Releases](../../releases) page
2. **Auto-install**: Use the install script (recommended)
3. **Manual download**: Download individual binaries or archives
4. **Container usage**: Pull from GitHub Packages
5. **Initramfs boot**: Boot minimal system directly into cpud
6. **Development builds**: Download from [Actions](../../actions) artifacts

For detailed initramfs usage, see [INITRAMFS.md](docs/INITRAMFS.md).

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
- **cpud-initramfs.cpio.gz**: U-root initramfs that boots directly into cpud

## Quick Start Options

### 1. **Install Binaries** (Traditional)
```bash
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash
```

### 2. **Boot Initramfs** (Minimal System)
```bash
# Download initramfs
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Boot with QEMU (example)
qemu-system-aarch64 \
  -kernel vmlinuz-aarch64 \
  -initrd cpud-initramfs.cpio.gz \
  -append "init=/init console=ttyAMA0" \
  -machine virt -cpu cortex-a57 -m 1024M -nographic

# Or boot on Raspberry Pi
sudo cp cpud-initramfs.cpio.gz /boot/firmware/
echo "initramfs cpud-initramfs.cpio.gz followkernel" | sudo tee -a /boot/firmware/config.txt
sudo sed -i 's/$/ init=\/init/' /boot/firmware/cmdline.txt
sudo reboot
```

### 3. **Container Usage**
```bash
docker pull ghcr.io/ericvh/cpu-prebuilt:latest
docker run --rm ghcr.io/ericvh/cpu-prebuilt:latest /usr/local/bin/cpud -h
```

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
