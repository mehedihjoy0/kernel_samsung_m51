#!/bin/sh

cd kernel

export ARCH=arm64
mkdir out

export PATH=$(pwd)/llvm-20/bin:$PATH

KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y"
BUILD_VAR="-j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"

echo "
CONFIG_THINLTO=y
# CONFIG_LTO_NONE is not set
CONFIG_LTO_CLANG=y
" >> arch/arm64/configs/m51_defconfig

make $BUILD_VAR m51_defconfig

make $BUILD_VAR
make $BUILD_VAR dtbs

DTBO_FILES=$(find $(pwd)/out/arch/arm64/boot/dts/samsung/ -name sm*150-sec-m51-eur-overlay-*.dtbo)
$(pwd)/tools/mkdtimg create $(pwd)/out/dtbo.img --page_size=4096 ${DTBO_FILES}

mv $(pwd)/out/dtbo.img ../dtbo.img
