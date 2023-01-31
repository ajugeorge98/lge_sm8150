#!/bin/sh

# Some general variables
PHONE="generic"
ARCH="arm64"
SUBARCH="arm64"
DEFCONFIG=dragon_flash_defconfig
COMPILER=clang
LINKER="lld"
COMPILERDIR=$GITHUB_WORKSPACE/kernel_workspace/tools/clang/host/linux-x86/clang-r428724
export PATH=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin:$PATH
export PATH=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin:$PATH
export LD_LIBRARY_PATH=home/aju/tools/clang/host/linux-x86/clang-r428724/lib64:$LD_LIBRARY_PATH
# Cleanup output
rm -rf out/outputs/${PHONE}/*

# Export shits
export KBUILD_BUILD_USER=Aju
export KBUILD_BUILD_HOST=

# Speed up build process
MAKE="./makeparallel"

# Basic build function
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

Build () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android- \
CROSS_COMPILE_ARM32=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- \
LD_LIBRARY_PATH=home/aju/tools/clang/host/linux-x86/clang-r428724/lib64 \
Image.gz-dtb dtbo.img
}

Build_lld () {
PATH="${COMPILERDIR}/bin:${PATH}" \
make -j$(nproc --all) O=out \
ARCH=${ARCH} \
CC=${COMPILER} \
CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android- \
CROSS_COMPILE_ARM32=$GITHUB_WORKSPACE/kernel_workspace/tools/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi- \
LD=ld.${LINKER} \
AR=llvm-ar \
NM=llvm-nm \
OBJCOPY=llvm-objcopy \
OBJDUMP=llvm-objdump \
STRIP=llvm-strip \
ld-name=${LINKER} \
KBUILD_COMPILER_STRING="clang-r428724" \
Image.gz-dtb dtbo.img
}



# Make defconfig

make O=out ARCH=${ARCH} ${DEFCONFIG}
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Made ${DEFCONFIG}"
fi

# Build starts here
if [ -z ${LINKER} ]
then
    Build
else
    Build_lld
fi

if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Build succesful"
    mkdir out/outputs
    mkdir out/outputs/${PHONE}
    find out/arch/arm64/boot/dts/qcom/ -name '*.dtb' -exec cat {} + >out/outputs/${PHONE}/dtb
    cp out/arch/arm64/boot/dtbo.img out/outputs/${PHONE}/dtbo.img
    cp out/arch/arm64/boot/Image.gz out/outputs/${PHONE}/Image.gz

fi

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
