# CPU Prebuilt Binaries

This project provides prebuilt binaries for u-root/cpu and u-root/cpud targeting aarch64 architecture.


## Quick Start (on Mac with Raspberry Pi target)

*NOTE*: Replace the version (v0.0.4) with the latest release
and use your own public/private key pair for security.

### On target (Raspberry Pi)

```bash
# Grab pre-built cpud & public key
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpud
chmod ugo+x cpud
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/identity.pub
# Start cpud (must be run as root)
sudo ./cpud -pk identity.pub
```

### On Mac

```bash
# Grab pre-built cpu & key
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpu
chmod ugo+x cpu
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/identity
# Start a docker, bind in cpu, and use it to launch on target
# This assumes you are operating out of your home directory
# and maps /Users on OSX to /home on the target.
# replace raspberrypi.local with either your pi's hostname
# or IP address 
docker run -i -t -v ${HOME}:${HOME/\Users/\/home} -e PWD=${PWD/\/Users/\/home} \
  -v ./identity:/etc/cpu/identity -v ./cpu:/usr/bin/cpu \
  ubuntu:latest \
  /usr/bin/cpu -nfs -sp 17010 -key /etc/cpu/identity \
  -namespace "/lib:/usr:/bin:/home:/etc" \
  raspberrypi.local /bin/bash
```

### On Mac from inside a devcontainer

This is pretty much like the above, except you'll want to make sure you have already
created a mount point for /workspaces on the target

```bash
# Grab pre-built cpu & key
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpu
chmod ugo+x cpu
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/identity
# first time - create workspaces directory on target if it doesn't already exist
# /tmp/local is the full root of the target device
/usr/bin/cpu -nfs -sp 17010 -key /etc/cpu/identity \
  -namespace "/lib:/usr:/bin:/home:/etc:/workspaces" \
  raspberrypi.local mkdir -p /tmp/local/workspaces
# Start cpu
/usr/bin/cpu -nfs -sp 17010 -key /etc/cpu/identity \
  -namespace "/lib:/usr:/bin:/home:/etc:/workspaces" \
  raspberrypi.local /bin/bash
```

### On Mac (native)

Since Mac binaries won't run natively on a linux target, this can be used
to be able to access directories on the host machine (Mac), but not necessarily
binaries or tools.  You could use this to be able to run python scripts, etc.
developed locally on your laptop on the target assuming the runtimes were already
installed there.  If stuff isn't installed, you are better off with something like
the docker formulations.

```bash
# If you haven't installed Go already, get that setup
brew install go git
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Install native cpu
go install github.com/u-root/cpu/cmds/cpu@latest

# Start it, but only map home directory
PWD=${PWD/\/Users/\/home} cpu -sp 17010 -key ~/src/test-cpu/identity -namespace "/home=/Users" -nfs \
raspberrypi.local /bin/bash
```

# NOTE: All other instructions below this line are currently being tested & debugged

## Quick Install (on Linux)

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
# Download and run installer (binaries run on Linux aarch64 only for now)
curl -fsSL https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh | bash

# Or download first, then run
wget https://raw.githubusercontent.com/ericvh/cpu-prebuilt/main/install.sh
chmod +x install.sh
./install.sh --help
```

### Option 2: Manual Download from Releases
```bash
# Download individual binaries (replace VERSION with actual version) (this can be used with docker desktop)
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpu
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpud

# Make executable
chmod +x cpu cpud

# Verify checksums (optional)
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpu.sha256
wget https://github.com/ericvh/cpu-prebuilt/releases/download/v0.0.4/cpud.sha256
sha256sum -c cpu.sha256 cpud.sha256
```

### Option 3: Download Complete Archive
```bash
# Download and verify archive
Go to https://github.com/ericvh/cpu-prebuilt/releases/tag/v0.0.4
Download the archive cpu-binaries-aarch64-*.tar.gz 
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

# Build binaries (requires Go 1.24+)
make

# Clean build artifacts
make clean

# Install locally built binaries
make install
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

# Boot with QEMU (example - you need to get your aarch64 Image from elsewhere)
qemu-system-aarch64 \
  -kernel Image \
  -initrd cpud-initramfs.cpio.gz \
  -append "init=/init console=ttyAMA0" \
  -netdev user,id=n1,hostfwd=tcp:0.0.0.0:17010-:17010,net=192.168.1.0/24,host=192.168.1.1 \
  -device virtio-net-pci,netdev=n1 \
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
