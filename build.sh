#!/bin/bash

# ==============================================================================
# KERNEL BUILD SCRIPT FOR SAMSUNG GALAXY M51
# Run this locally or in CI
# ==============================================================================

set -e  # Exit on error

# ==============================================================================
# CONFIGURATION
# ==============================================================================
KERNEL_SOURCE="https://github.com/mehedihjoy0/android_kernel_samsung_sm7150"
KERNEL_BRANCH="m51"
KERNEL_DEFCONFIG="m51_defconfig"

CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/4c6fbc28d3b078a5308894fc175f962bb26a5718/clang-r383902b1.tar.gz"
GCC_AARCH64_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
GCC_ARM_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9"
GCC_BRANCH="master-kernel-build-2021"

BUILD_USER="mehedihjoy0"
BUILD_HOST="local-build"
KERNEL_NAME="m51-kernel"

# ==============================================================================
# PATHS
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/build"
TOOLCHAIN_DIR="${WORK_DIR}/toolchains"
KERNEL_DIR="${WORK_DIR}/kernel"

# ==============================================================================
# FUNCTIONS
# ==============================================================================
print_header() {
    echo "========================================="
    echo "$1"
    echo "========================================="
}

print_step() {
    echo "➡️  $1"
}

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1" >&2
}

# ==============================================================================
# SETUP TOOLCHAINS
# ==============================================================================
setup_toolchains() {
    print_header "Setting up Toolchains"
    
    mkdir -p "${TOOLCHAIN_DIR}"
    cd "${TOOLCHAIN_DIR}"
    
    # Clang
    if [ ! -d "clang" ]; then
        print_step "Downloading Clang..."
        curl -L "${CLANG_URL}" -o clang.tar.gz
        mkdir -p clang
        tar -xzf clang.tar.gz -C clang
        rm -f clang.tar.gz
        print_success "Clang installed"
    else
        print_success "Clang already exists"
    fi
    
    # GCC AArch64
    if [ ! -d "gcc-aarch64" ]; then
        print_step "Cloning GCC AArch64..."
        git clone --depth=1 "${GCC_AARCH64_URL}" -b "${GCC_BRANCH}" gcc-aarch64
        print_success "GCC AArch64 installed"
    else
        print_success "GCC AArch64 already exists"
    fi
    
    # GCC ARM
    if [ ! -d "gcc-arm" ]; then
        print_step "Cloning GCC ARM..."
        git clone --depth=1 "${GCC_ARM_URL}" -b "${GCC_BRANCH}" gcc-arm
        print_success "GCC ARM installed"
    else
        print_success "GCC ARM already exists"
    fi
    
    cd "${SCRIPT_DIR}"
}

# ==============================================================================
# CLONE KERNEL SOURCE
# ==============================================================================
clone_kernel() {
    print_header "Setting up Kernel Source"
    
    if [ ! -d "${KERNEL_DIR}" ]; then
        print_step "Cloning kernel source..."
        git clone --depth=1 "${KERNEL_SOURCE}" -b "${KERNEL_BRANCH}" "${KERNEL_DIR}"
        print_success "Kernel source cloned"
    else
        print_step "Updating kernel source..."
        cd "${KERNEL_DIR}"
        git pull origin "${KERNEL_BRANCH}"
        cd "${SCRIPT_DIR}"
        print_success "Kernel source updated"
    fi
}

# ==============================================================================
# BUILD KERNEL
# ==============================================================================
build_kernel() {
    print_header "Building Kernel"
    
    cd "${KERNEL_DIR}"
    
    # Export environment
    export ARCH="arm64"
    export SUBARCH="arm64"
    export KBUILD_BUILD_USER="${BUILD_USER}"
    export KBUILD_BUILD_HOST="${BUILD_HOST}"
    
    # Setup PATH
    export PATH="${TOOLCHAIN_DIR}/clang/bin:${TOOLCHAIN_DIR}/gcc-aarch64/bin:${TOOLCHAIN_DIR}/gcc-arm/bin:${PATH}"
    
    # Make function
    make_kernel() {
        make O=out \
             ARCH=arm64 \
             CC=clang \
             HOSTCC=clang \
             LLVM=1 \
             CLANG_TRIPLE=aarch64-linux-gnu- \
             CROSS_COMPILE=aarch64-linux-android- \
             CROSS_COMPILE_COMPAT=arm-linux-androideabi- \
             "$@"
    }
    
    # Clean if requested
    if [[ "${1}" == "clean" ]]; then
        print_step "Cleaning previous build..."
        rm -rf out/
    fi
    
    # Build
    print_step "Configuring with ${KERNEL_DEFCONFIG}..."
    cat arch/arm64/configs/sdmmagpie_defconfig arch/arm64/configs/m51.config > arch/arm64/configs/m51_defconfig
    make_kernel "${KERNEL_DEFCONFIG}"
    
    print_step "Compiling with $(nproc) threads..."
    make_kernel -j$(nproc) 2>&1 | tee build.log
    
    print_success "Kernel build completed"
    
    # Create DTBO if dtbo files exist
    if find out/arch/arm64 -name "*.dtbo" -type f 2>/dev/null | head -1 | grep -q .; then
        print_step "Creating DTBO image..."
        ${SCRIPT_DIR}/mkdtimg create out/arch/arm64/boot/dtbo.img \
            --page_size=4096 \
            $(find out/arch/arm64 -name "*.dtbo")
        print_success "DTBO image created"
    fi
    
    cd "${SCRIPT_DIR}"
}

# ==============================================================================
# CREATE FLASHABLE ZIP
# ==============================================================================
create_flashable_zip() {
    print_header "Creating Flashable Zip"
    
    # Clone AnyKernel3 if not exists
    if [ ! -d "${WORK_DIR}/AnyKernel3" ]; then
        print_step "Cloning AnyKernel3..."
        git clone --depth=1 https://github.com/mehedihjoy0/AnyKernel3.git "${WORK_DIR}/AnyKernel3"
        rm -rf "${WORK_DIR}/AnyKernel3/.git" "${WORK_DIR}/AnyKernel3/LICENSE" "${WORK_DIR}/AnyKernel3/README.md"
    fi
    
    AK_DIR="${WORK_DIR}/AnyKernel3"
    
    # Copy kernel image
    if [ -f "${KERNEL_DIR}/out/arch/arm64/boot/Image.gz" ]; then
        cp "${KERNEL_DIR}/out/arch/arm64/boot/Image.gz" "${AK_DIR}/Image.gz"
    elif [ -f "${KERNEL_DIR}/out/arch/arm64/boot/Image" ]; then
        cp "${KERNEL_DIR}/out/arch/arm64/boot/Image" "${AK_DIR}/Image.gz"
    else
        print_error "No kernel image found!"
        exit 1
    fi
    
    # Copy DTB if exists
    if [ -f "${KERNEL_DIR}/out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb" ]; then
        cp "${KERNEL_DIR}/out/arch/arm64/boot/dts/qcom/sdmmagpie.dtb" "${AK_DIR}/dtb"
    fi
    
    # Copy DTBO if exists
    if [ -f "${KERNEL_DIR}/out/arch/arm64/boot/dtbo.img" ]; then
        cp "${KERNEL_DIR}/out/arch/arm64/boot/dtbo.img" "${AK_DIR}/"
    fi
    
    # Create zip
    cd "${AK_DIR}"
    ZIP_NAME="ButterflyKernel_m51-$(date +%Y%m%d-%H%M).zip"
    print_step "Creating ${ZIP_NAME}..."
    zip -r9 "${ZIP_NAME}" ./* -x "*.zip"
    
    # Move to output directory
    mkdir -p "${WORK_DIR}/output"
    mv "${ZIP_NAME}" "${WORK_DIR}/output/"
    
    print_success "Flashable zip created: ${WORK_DIR}/output/${ZIP_NAME}"
    
    # Copy build log
    cp "${KERNEL_DIR}/build.log" "${WORK_DIR}/output/"
    
    cd "${SCRIPT_DIR}"
}

# ==============================================================================
# MAIN
# ==============================================================================
main() {
    print_header "Butterfly Kernel Build for Samsung Galaxy M51"
    echo "Start time: $(date)"
    echo ""
    
    # Parse arguments
    CLEAN_BUILD=""
    if [[ "$1" == "--clean" ]] || [[ "$1" == "-c" ]]; then
        CLEAN_BUILD="clean"
    fi
    
    # Run build steps
    setup_toolchains
    clone_kernel
    build_kernel "${CLEAN_BUILD}"
    create_flashable_zip
    
    echo ""
    print_header "Build Completed Successfully!"
    echo "Output files in: ${WORK_DIR}/output/"
    echo "End time: $(date)"
}

# Run main function
main "$@"
