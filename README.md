# Linux Guests Build for Bao Hypervisor

This repository facilitates the building of Linux guest images to run on top of the Bao hypervisor. It primarily supports a test framework by automating the configuration and build processes for both the Linux kernel and the Buildroot root filesystem.

## Prerequisites

Ensure the following dependencies are installed on your system:

- `git`
- `make`

## Repository Overview

- **Makefile**: Central build automation script.
- **buildroot/**: Contains platform-specific Buildroot configuration files.
- **patches/**: Contains optional Linux kernel patches for specific versions.

## Usage

### Environment Variables

- `PLATFORM`: Target platform to build for (e.g., `qemu-aarch64-virt`, `imx8qm`).
- `ARCH`: Target architecture (e.g., `aarch64`, `riscv64`).

### Supported Platforms

#### AArch64 Platforms

| Platform          | Supported | Tested |
|-------------------|:---------:|:------:|
| qemu-aarch64-virt | ✅        | ✅    |
| fvp-a             | ✅        |       |
| fvp-r             | ✅        |       |
| zcu102            | ✅        |       |
| zcu104            | ✅        |       |
| imx8qm            | ✅        |       |
| tx2               | ✅        |       |
| rpi4              | ✅        |       |

#### RISC-V Platforms

| Platform             | Supported | Tested |
|----------------------|:---------:|:------:|
| qemu-riscv64-virt    | ✅        | ✅     |
### Building

Run the following commands to build the Linux guest images:

1. **Set the environment variables:**
   ```bash
   export PLATFORM=<target_platform>
   export ARCH=<target_architecture>
   ```

   Example:
   ```bash
   export PLATFORM=qemu-aarch64-virt
   export ARCH=aarch64
   ```

2. **Run the build process:**
   ```bash
   make all
   ```

   This will:
   - Clone and build Buildroot to create the root filesystem (`rootfs.cpio`).
   - Clone and build the Linux kernel for the specified platform.

3. **Output Files:**
   - Root filesystem: `wrkdir/rootfs_<PLATFORM>.cpio`
   - Kernel image: `wrkdir/Image-<PLATFORM>`

### Cleaning Up

To clean all build artifacts, run:
```bash
make clean
```

## Makefile Targets

- `all`: Builds both the Linux kernel and Buildroot root filesystem.
- `setup`: Prepares the working directory.
- `buildroot`: Builds the Buildroot root filesystem.
- `linux`: Builds the Linux kernel.
- `clean`: Removes all build artifacts.

## Customization

### Buildroot Configuration

Default Buildroot configurations are located in the `buildroot/` directory and are named according to the target architecture (e.g., `aarch64.config`, `riscv64.config`). Modify these files to customize the Buildroot build process.

### Linux Kernel Patches

If custom patches are required for the Linux kernel:

1. Place patch files in the `patches/<kernel_version>/` directory.
2. Ensure the directory name matches the kernel version (e.g., `patches/v6.1/`).
3. The Makefile automatically applies patches during the kernel build process.
