# CPU Initramfs Usage Guide

This guide explains how to use the CPU initramfs that boots directly into the cpud daemon.

## What is the CPU Initramfs?

The CPU initramfs is a u-root-based initial RAM filesystem that:
- Boots directly into the cpud daemon
- Provides a minimal Linux environment
- Automatically mounts essential filesystems (`/proc`, `/sys`, `/dev`)
- Includes a default SSH public key for authentication (`/etc/cpu_rsa.pub`)
- Starts cpud as the init process

## SSH Key Authentication

The initramfs includes a default SSH public key at `/etc/cpu_rsa.pub` for convenient authentication. The corresponding private key is available in the release binaries.

**⚠️ WARNING**: These are default keys for convenience. Generate your own keys for production use!

### Using the Default Keys

```bash
# Download the private key from the release
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpu_rsa
chmod 600 cpu_rsa

# Use with CPU client
./cpu -key cpu_rsa user@target-system
```

### Generating Your Own Keys

```bash
# Generate your own key pair
ssh-keygen -t rsa -b 4096 -f my_cpu_key -N ""

# Replace the public key in the initramfs (requires rebuilding)
# Or use cpu with your custom key
./cpu -key my_cpu_key user@target-system
```

## Use Cases

### 1. **Dedicated CPU Server**
Boot a system that immediately becomes a CPU server without needing a full OS installation.

### 2. **Container/VM Images**
Create lightweight VMs or containers that only run cpud.

### 3. **Network Boot (PXE)**
Boot systems over the network directly into CPU mode.

### 4. **Recovery/Rescue Systems**
Quick access to systems via CPU without full OS boot.

## Usage Examples

### QEMU/KVM Virtual Machine

```bash
# Download the initramfs
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Boot with QEMU (aarch64)
qemu-system-aarch64 \
  -kernel vmlinuz-aarch64 \
  -initrd cpud-initramfs.cpio.gz \
  -append "init=/init console=ttyAMA0" \
  -machine virt \
  -cpu cortex-a57 \
  -m 1024M \
  -nographic \
  -netdev user,id=net0 \
  -device virtio-net-device,netdev=net0
```

### Physical Hardware Boot

```bash
# Copy to boot partition
sudo cp cpud-initramfs.cpio.gz /boot/

# Update bootloader configuration (example for GRUB)
sudo nano /etc/default/grub

# Add menu entry:
menuentry 'CPU Server' {
    linux /vmlinuz-aarch64 init=/init console=ttyS0,115200
    initrd /cpud-initramfs.cpio.gz
}

# Update GRUB
sudo update-grub
```

### Raspberry Pi Boot

The Raspberry Pi has a unique boot process. Here's how to set it up:

#### **Raspberry Pi 4/5 (64-bit)**

```bash
# Download initramfs
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Copy to boot partition
sudo cp cpud-initramfs.cpio.gz /boot/firmware/

# Edit config.txt
sudo nano /boot/firmware/config.txt

# Add these lines at the end:
# CPU Server Configuration
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1

# Edit cmdline.txt to set init
sudo nano /boot/firmware/cmdline.txt
# Modify the existing line to add init=/init
# Example result:
# console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait init=/init

# Reboot
sudo reboot
```

#### **Raspberry Pi 3 (64-bit)**

```bash
# Download initramfs
wget https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Copy to boot partition
sudo cp cpud-initramfs.cpio.gz /boot/

# Edit config.txt
sudo nano /boot/config.txt

# Add these lines:
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1

# Edit cmdline.txt
sudo nano /boot/cmdline.txt
# Add init=/init to the existing line

# Reboot
sudo reboot
```

#### **Raspberry Pi Zero 2 W**

```bash
# Same as Pi 3 but ensure you have the right kernel
sudo cp cpud-initramfs.cpio.gz /boot/

# Edit config.txt
sudo nano /boot/config.txt

# Add:
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1

# Edit cmdline.txt
sudo nano /boot/cmdline.txt
# Add init=/init

sudo reboot
```

#### **Network Boot (PXE) for Pi**

```bash
# Set up TFTP server with initramfs
sudo cp cpud-initramfs.cpio.gz /tftpboot/

# Configure dnsmasq for PXE
sudo nano /etc/dnsmasq.conf

# Add:
enable-tftp
tftp-root=/tftpboot
pxe-service=0,"Raspberry Pi Boot"
dhcp-boot=bootcode.bin

# Create boot configuration
echo "initramfs cpud-initramfs.cpio.gz followkernel" > /tftpboot/config.txt
echo "console=serial0,115200 console=tty1 init=/init" > /tftpboot/cmdline.txt
```

### Docker Container

```bash
# Create a minimal container with the initramfs
cat > Dockerfile << 'EOF'
FROM scratch
COPY cpud-initramfs.cpio.gz /initramfs.cpio.gz
CMD ["/bin/sh"]
EOF

docker build -t cpu-initramfs .
```

### U-Boot Configuration

```bash
# U-Boot commands for network boot
setenv bootargs 'init=/init console=ttyS0,115200'
setenv bootcmd 'tftp ${kernel_addr_r} vmlinuz-aarch64; tftp ${ramdisk_addr_r} cpud-initramfs.cpio.gz; booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}'
boot
```

## Configuration

### Boot Parameters

The initramfs supports standard Linux boot parameters:

```bash
# Basic boot
init=/init

# With console output (Pi serial)
init=/init console=serial0,115200

# With console output (Pi HDMI)
init=/init console=tty1

# With network configuration
init=/init ip=dhcp

# With cpud parameters (passed through)
init=/init -- -key /tmp/cpu_rsa -dbg9p -port 17010

# Raspberry Pi specific
init=/init console=serial0,115200 console=tty1 dwc_otg.lpm_enable=0
```

### Network Configuration

The initramfs includes basic networking support:

```bash
# DHCP (automatic) - works great on Pi
ip=dhcp

# Static IP
ip=192.168.1.100::192.168.1.1:255.255.255.0::eth0:off

# Raspberry Pi WiFi (requires wpa_supplicant setup)
# Note: WiFi setup requires additional configuration in initramfs

# Manual configuration (in init)
ip addr add 192.168.1.100/24 dev eth0
ip route add default via 192.168.1.1
```

### Raspberry Pi Specific Configuration

#### **WiFi Setup (Advanced)**

To enable WiFi in the initramfs, you need to customize the build:

```bash
# Create wpa_supplicant configuration
cat > wpa_supplicant.conf << 'EOF'
network={
    ssid="YourWiFiNetwork"
    psk="YourWiFiPassword"
}
EOF

# Modify the u-root build to include WiFi tools
GOOS=linux GOARCH=arm64 u-root -format=cpio -o cpud-initramfs.cpio \
    -files "../binaries/cpud:bin/cpud" \
    -files "wpa_supplicant.conf:etc/wpa_supplicant/wpa_supplicant.conf" \
    -initcmd="../initramfs/cpud-init.go" \
    core wifi
```

#### **Hardware-Specific Settings**

```bash
# Pi 4/5 - GPU memory split
gpu_mem=16

# Pi 3 - Optimize for headless
gpu_mem=16
disable_camera_led=1

# All Pi models - Disable unnecessary services
dtoverlay=disable-wifi  # if using ethernet only
dtoverlay=disable-bt    # if not using bluetooth
```

#### **Performance Optimization**

```bash
# In config.txt for better performance
over_voltage=2
arm_freq=1500
gpu_freq=500

# Disable unnecessary hardware
dtoverlay=disable-wifi
dtoverlay=disable-bt
disable_camera_led=1
disable_splash=1
```

## Customization

### Adding Files

To add custom files to the initramfs:

```bash
# Clone the cpu-prebuilt repository
git clone https://github.com/ericvh/cpu-prebuilt.git
cd cpu-prebuilt

# Modify the build script to add files
# In build.sh, modify the u-root command:
GOOS=linux GOARCH=arm64 u-root -format=cpio -o ../initramfs/cpud-initramfs.cpio \
    -files "../binaries/cpud:bin/cpud" \
    -files "myconfig.yaml:etc/cpud.yaml" \
    -initcmd="../initramfs/cpud-init.go" \
    core

# Rebuild
./build.sh
```

### Custom Init Script

The init script can be customized by modifying `cpud-init.go`:

```go
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
    fmt.Println("Custom CPU initramfs starting...")
    
    // Mount filesystems
    syscall.Mount("proc", "/proc", "proc", 0, "")
    syscall.Mount("sysfs", "/sys", "sysfs", 0, "")
    syscall.Mount("devtmpfs", "/dev", "devtmpfs", 0, "")
    
    // Custom initialization
    setupNetwork()
    loadConfig()
    
    // Start cpud
    cmd := exec.Command("/bin/cpud", os.Args[1:]...)
    cmd.Stdout = os.Stdout
    cmd.Stderr = os.Stderr
    cmd.Stdin = os.Stdin
    
    if err := cmd.Run(); err != nil {
        log.Fatalf("cpud failed: %v", err)
    }
}

func setupNetwork() {
    // Custom network setup
}

func loadConfig() {
    // Custom configuration loading
}
```

## Troubleshooting

### Common Issues

1. **Boot Hangs**: Check console output, ensure correct kernel
2. **Network Issues**: Verify network configuration and drivers
3. **Permission Issues**: Ensure proper filesystem permissions

### Debug Mode

Boot with debug parameters:

```bash
init=/init debug console=ttyS0,115200 loglevel=7
```

### Recovery

If cpud fails to start, the system will drop to a basic shell:

```bash
# Check logs
dmesg | tail

# Test cpud manually
/bin/cpud -h

# Check network
ip addr show
```

## Security Considerations

- The initramfs runs as root by default
- Consider using SSH keys for CPU authentication
- Network security should be configured appropriately
- Regular updates recommended for security patches

## Performance

- **Size**: ~10-20MB compressed initramfs
- **Boot time**: ~2-5 seconds to cpud ready
- **Memory usage**: ~50-100MB base system
- **Network latency**: Minimal overhead over direct cpud

## Integration Examples

### Raspberry Pi Projects

#### **Pi Cluster CPU Node**
```bash
# config.txt for cluster node
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1
gpu_mem=16
disable_splash=1
dtoverlay=disable-wifi
dtoverlay=disable-bt

# cmdline.txt
console=serial0,115200 init=/init ip=dhcp -- -port 17010
```

#### **Pi Zero CPU Server**
```bash
# Minimal config.txt for Pi Zero 2 W
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1
gpu_mem=16
dtoverlay=dwc2

# cmdline.txt with USB gadget mode
console=serial0,115200 init=/init modules-load=dwc2,g_ether
```

#### **Pi 4 Headless CPU Server**
```bash
# config.txt optimized for headless operation
initramfs cpud-initramfs.cpio.gz followkernel
arm_64bit=1
enable_uart=1
gpu_mem=16
disable_splash=1
boot_delay=0

# cmdline.txt with performance tuning
console=serial0,115200 init=/init ip=dhcp cgroup_memory=1 cgroup_enable=memory
```

### Kubernetes Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-server
spec:
  containers:
  - name: cpu-server
    image: cpu-initramfs
    command: ["/init"]
    ports:
    - containerPort: 17010
```

### Systemd Service

```ini
[Unit]
Description=CPU Server from Initramfs
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/qemu-system-aarch64 \
  -kernel /boot/vmlinuz-aarch64 \
  -initrd /boot/cpud-initramfs.cpio.gz \
  -append "init=/init" \
  -nographic

[Install]
WantedBy=multi-user.target
```

### Raspberry Pi Automation Scripts

#### **Auto-deployment Script**
```bash
#!/bin/bash
# deploy-cpu-pi.sh - Automatically configure Pi for CPU server

set -e

PI_IP="$1"
if [ -z "$PI_IP" ]; then
    echo "Usage: $0 <pi-ip-address>"
    exit 1
fi

echo "Deploying CPU server to Pi at $PI_IP..."

# Download latest initramfs
wget -O cpud-initramfs.cpio.gz \
    https://github.com/ericvh/cpu-prebuilt/releases/latest/download/cpud-initramfs.cpio.gz

# Copy to Pi
scp cpud-initramfs.cpio.gz pi@$PI_IP:/tmp/

# Configure Pi
ssh pi@$PI_IP << 'EOF'
# Copy initramfs to boot partition
sudo cp /tmp/cpud-initramfs.cpio.gz /boot/firmware/

# Backup original config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.bak
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.bak

# Configure for CPU server
echo "initramfs cpud-initramfs.cpio.gz followkernel" | sudo tee -a /boot/firmware/config.txt
echo "arm_64bit=1" | sudo tee -a /boot/firmware/config.txt
echo "enable_uart=1" | sudo tee -a /boot/firmware/config.txt

# Update cmdline.txt
sudo sed -i 's/$/ init=\/init/' /boot/firmware/cmdline.txt

echo "Configuration complete. Rebooting in 10 seconds..."
sleep 10
sudo reboot
EOF

echo "Pi will reboot into CPU server mode"
```

#### **Monitor and Recovery Script**
```bash
#!/bin/bash
# monitor-cpu-pi.sh - Monitor Pi CPU server

PI_IP="$1"
CPU_PORT="17010"

check_cpu_server() {
    if timeout 5 nc -z "$PI_IP" "$CPU_PORT" 2>/dev/null; then
        echo "$(date): CPU server at $PI_IP:$CPU_PORT is responding"
        return 0
    else
        echo "$(date): CPU server at $PI_IP:$CPU_PORT is not responding"
        return 1
    fi
}

# Main monitoring loop
while true; do
    if ! check_cpu_server; then
        echo "Attempting to restart Pi..."
        # You could implement remote power cycling here
        # or send alerts
    fi
    sleep 30
done
```
