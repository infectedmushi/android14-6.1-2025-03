#!/bin/bash
RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

bold=$(tput bold)
normal=$(tput sgr0)

timestamp()
{
 date +"%Y%m%d-%H%M"
}

VERSION="#1 PREEMPT "
STAMP=`date`
#UTS_VERSION="$(echo $STAMP)"



export USE_CCACHE=true

export KBUILD="/mnt/Android/kernel_akita"
export KERNEL_BUILDS="/mnt/Android/kernel_builds"

echo -e "${GREEN}${bold}Removing old files and folders...${normal}${ENDCOLOR}"
rm -rf AnyKernel3
rm -rf bazel-kernel_akita
rm -rf bootimgs
rm -rf common
rm -rf flash_device.sh
rm -rf launch_cvd.sh
rm -rf run_test_only.sh
rm -rf WORKSPACE
rm -rf bazel-out
rm -rf build
rm -rf common-modules
rm -rf kernel
rm -rf out
rm -rf tools
rm -rf bazel-bin
rm -rf bazel-testlogs
rm -rf external
rm -rf kernel_patches
rm -rf prebuilts

echo -e "${GREEN}${bold}Repo init and sync...${normal}${ENDCOLOR}"
#repo init --depth=1 --u https://android.googlesource.com/kernel/manifest -b common-android14-5.15-2024-07
#repo init --depth=1 --u https://android.googlesource.com/kernel/manifest -b common-android14-5.15-2025-01
#repo init --depth=1 --u https://android.googlesource.com/kernel/manifest -b common-android14-5.15-2025-03
repo init --depth=1 --u https://android.googlesource.com/kernel/manifest -b common-android14-6.1-2025-03
repo --trace sync -c -j$(nproc --all) --no-tags --fail-fast
echo -e "${GREEN}${bold}Entering kernel directory...${normal}${ENDCOLOR}"
cd common
echo -e "${GREEN}${bold}Fetching and cloning...${normal}${ENDCOLOR}"
curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s next
#curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs
git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1
echo -e "${GREEN}${bold}Cloning TheWildJames patches...${normal}${ENDCOLOR}"
cd ..
git clone https://github.com/TheWildJames/kernel_patches.git
echo -e "${GREEN}${bold}Patching KernelSU-Next with SuSFS...${normal}${ENDCOLOR}"
#curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next-susfs/kernel/setup.sh" | bash -s next-susfs
#cp -v /mnt/Android/susfs_patches/KernelSU-Next-Implement-SUSFS-v1.5.5-Universal.patch KernelSU-Next/KernelSU-Next-Implement-SUSFS-v1.5.5-Universal.patch
cd ./common/KernelSU-Next
cp -v ../../kernel_patches/next/0001-kernel-patch-susfs-v1.5.5-to-KernelSU-Next-v1.0.5.patch ./
#cp -v /mnt/Android/susfs_patches/0001-kernel-patch-susfs-v1.5.5-to-KernelSU-Next-v1.0.5.patch KernelSU-Next/0001-kernel-patch-susfs-v1.5.5-to-KernelSU-Next-v1.0.5.patch
patch -p1 < 0001-kernel-patch-susfs-v1.5.5-to-KernelSU-Next-v1.0.5.patch
cd ..
echo -e "${GREEN}${bold}Applying and patching SuSFS...${normal}${ENDCOLOR}"
cp -v susfs4ksu/kernel_patches/fs/* fs/
cp -v susfs4ksu/kernel_patches/include/linux/* include/linux/
cp -v susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch ./
patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch
echo -e "${GREEN}${bold}Removing exports...${normal}${ENDCOLOR}"
rm -v android/abi_gki_protected_exports_*
cd ..
#echo -e "${GREEN}${bold}Cloning TheWildJames patches...${normal}${ENDCOLOR}"
#git clone https://github.com/TheWildJames/kernel_patches.git
cd common
echo -e "${GREEN}${bold}Applying patches...${normal}${ENDCOLOR}"
cp -v ../kernel_patches/69_hide_stuff.patch ./
cp -v ../kernel_patches/next/syscall_hooks.patch ./
patch -p1 -F 3 < 69_hide_stuff.patch
patch -p1 -F 3 < syscall_hooks.patch

cd ..
echo -e "${GREEN}${bold}Adding configuration settings to gki_defconfig...${normal}${ENDCOLOR}"
echo "CONFIG_KSU=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_WITH_KPROBES=n" | tee -a ./common/arch/arm64/configs/gki_defconfig

# Add SUSFS configuration settings
echo "CONFIG_KSU_SUSFS=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HAS_MAGIC_MOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_PATH=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_MOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_KSTAT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_OVERLAYFS=n" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_TRY_UMOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_AUTO_ADD_TRY_UMOUNT_FOR_BIND_MOUNT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_ENABLE_LOG=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_KSU_SUSFS_SUS_SU=n" | tee -a ./common/arch/arm64/configs/gki_defconfig

# Add additional tmpfs config setting
echo "CONFIG_TMPFS_XATTR=y" | tee -a ./common/arch/arm64/configs/gki_defconfig
echo "CONFIG_TMPFS_POSIX_ACL=y" | tee -a ./common/arch/arm64/configs/gki_defconfig

echo -e "${GREEN}${bold}Building kernel...${normal}${ENDCOLOR}"
sed -i '$s|echo "\$res"|echo "\$res-deepongi+"|' ./common/scripts/setlocalversion
sed -i "/stable_scmversion_cmd/s/-maybe-dirty//g" ./build/kernel/kleaf/impl/stamp.bzl
sed -i '2s/check_defconfig//' ./common/build.config.gki
echo -e "${GREEN}${bold}Printing kernel date...${normal}${ENDCOLOR}"
perl -pi -e 's{UTS_VERSION="\$\(echo \$UTS_VERSION \$CONFIG_FLAGS \$TIMESTAMP \| cut -b -\$UTS_LEN\)"}{UTS_VERSION="#1 SMP PREEMPT Fri Mar 14 05:47:17 UTC 2025"}' ./common/scripts/mkcompile_h
tools/bazel build --config=fast --lto=thin //common:kernel_aarch64_dist
#tools/bazel build --config=fast --lto=full //common:kernel_aarch64_dist 
echo -e "${RED}${bold}Kernel done...${normal}${ENDCOLOR}"
echo -e "${GREEN}${bold}Cloning Anykernel3...${normal}${ENDCOLOR}"
git clone https://github.com/infectedmushi/AnyKernel3 -b android14-5.15
echo -e "${GREEN}${bold}Copying Images...${normal}${ENDCOLOR}"
mkdir -p bootimgs
cp -v ./bazel-bin/common/kernel_aarch64/Image.lz4 ./bootimgs/Image.lz4
cp -v ./bazel-bin/common/kernel_aarch64_gki_artifacts/boot.img ./bootimgs/boot.img
cp -v ./bazel-bin/common/kernel_aarch64_gki_artifacts/boot-gz.img ./bootimgs/boot-gz.img
cp -v ./bazel-bin/common/kernel_aarch64_gki_artifacts/boot-lz4.img ./bootimgs/boot-lz4.img
echo -e "${GREEN}${bold}Creating ZIP for kernel image...${normal}${ENDCOLOR}"
export ZIP_NAME="AK3-A14-6.1.128-KSUN-$(timestamp).zip"
export BUILD_IMG="A14-6.1.128-KSUN-RAW-$(timestamp).img"
export BUILD_IMG_GZ="A14-6.1.128-KSUN-GZ-$(timestamp).img"
export BUILD_IMG_LZ4="A14-6.1.128-KSUN-LZ4-$(timestamp).img"
cd AnyKernel3
mv ../bootimgs/Image.lz4 ./Image.lz4
zip -r "$ZIP_NAME" ./*
echo -e "${GREEN}${bold}AK3 zip done...!${normal}${ENDCOLOR}"
cd ..
echo -e "${GREEN}${bold}Moving files...${normal}${ENDCOLOR}"
mv -v ./AnyKernel3/$ZIP_NAME $KERNEL_BUILDS/6.1.128/$ZIP_NAME
mv -v ./bootimgs/boot.img $KERNEL_BUILDS/6.1.128/$BUILD_IMG
mv -v ./bootimgs/boot-gz.img $KERNEL_BUILDS/6.1.128/$BUILD_IMG_GZ
mv -v ./bootimgs/boot-lz4.img $KERNEL_BUILDS/6.1.128/$BUILD_IMG_LZ4

echo -e "${RED}${bold}All done...!${normal}${ENDCOLOR}"
