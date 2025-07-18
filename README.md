# CPU Prebuilt Binaries

This project provides prebuilt binaries for u-root/cpu and u-root/cpud targeting aarch64 architecture.

## What this does

This repository uses GitHub Actions to:
- Build `cpu` and `cpud` from the [u-root](https://github.com/u-root/u-root) project
- Cross-compile for aarch64 (ARM64) architecture
- Package the binaries as downloadable artifacts
- Automatically rebuild on new releases or manual triggers

## Binaries Included

- **cpu**: The CPU client binary for connecting to remote systems
- **cpud**: The CPU daemon binary for hosting remote connections

## Usage

1. Go to the [Actions](../../actions) tab
2. Find the latest successful "Build CPU Binaries" workflow run
3. Download the `cpu-binaries-aarch64` artifact
4. Extract the binaries and use them on your aarch64 system

## Architecture

- **Target Architecture**: aarch64 (ARM64)
- **Source**: [u-root/u-root](https://github.com/u-root/u-root)
- **Build Tool**: Go cross-compilation

## License

The binaries are built from u-root which is licensed under the BSD 3-Clause License.
