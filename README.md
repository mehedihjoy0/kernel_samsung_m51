# Butterfly Kernel

**Custom kernel for Samsung Galaxy M51 (SM-M515F)**

---

## Overview

A custom kernel implementation for the Samsung Galaxy M51, providing enhanced performance, battery optimization, and additional features while maintaining stability and compatibility.

## Features

- **Optimized Performance**: CPU/GPU scheduling improvements
- **Battery Enhancements**: Power management optimizations
- **KernelSU Support**: Optional integration for root access
- **Security Patches**: Regular security updates
- **Custom Tunables**: Exposed kernel parameters for customization
- **Stability Focus**: Production-ready with extensive testing

## Technical Details

| Component | Specification |
|-----------|--------------|
| **Base** | LineageOS 23 (Android 16) |
| **Architecture** | ARM64 (aarch64) |
| **Toolchain** | Clang + GCC 4.9 |
| **Defconfig** | `m51_defconfig` |
| **Compiler** | LLVM/Clang with LTO support |

#
## Build System

- **Local Build**: Execute `./build.sh`
- **CI/CD**: Automated via GitHub Actions
- **Output**: Flashable AnyKernel3 zip
- **Artifacts**: Kernel image, DTBO, modules, build logs

## Dependencies

Essential build dependencies include:
- Clang toolchain (AOSP)
- GCC 4.9 cross-compilers
- Standard kernel build tools
- Device Tree Compiler

## Acknowledgments

- LineageOS team for the kernel base
- KernelSU developers for root solution
- AnyKernel3 project for flashable template
- All contributors and testers

---
