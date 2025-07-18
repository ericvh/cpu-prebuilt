# CPU Prebuilt - Build Logs

This directory contains build logs and artifacts from the GitHub Actions workflow.

## Artifact Contents

When the workflow runs successfully, it creates an artifact named `cpu-binaries-aarch64` containing:

- `cpu` - The CPU client binary compiled for aarch64
- `cpud` - The CPU daemon binary compiled for aarch64  
- `BUILD_INFO.txt` - Build metadata and usage information

## Manual Testing

If you want to test the binaries locally on an aarch64 system:

```bash
# Download and extract the artifact
unzip cpu-binaries-aarch64.zip

# Make binaries executable
chmod +x cpu cpud

# Test the binaries
./cpu -version
./cpud -version
```

## Build Process

The GitHub Action performs these steps:

1. Sets up Go 1.21
2. Clones the latest u-root repository
3. Cross-compiles both `cpu` and `cpud` for linux/arm64
4. Verifies the binaries are correctly built
5. Creates build metadata
6. Uploads everything as an artifact
7. (Optional) Creates a GitHub release if triggered by a tag
