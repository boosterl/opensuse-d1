#!/usr/bin/sh
export CROSS_COMPILE='riscv64-suse-linux-'
export ARCH='riscv'
PWD="$(pwd)"
NPROC="$(nproc)"
export PWD
export NPROC

export ROOT_FS='openSUSE-Tumbleweed-RISC-V-JeOS.riscv64-rootfs.riscv64.tar.xz'
export ROOT_FS_DL="https://download.opensuse.org/ports/riscv/tumbleweed/images/${ROOT_FS}"

# select 'arch', 'nezha_defconfig'
export KERNEL='nezha_defconfig'

# Device Tree:
# In the current pinned U-Boot Commit the following device trees are available
# for the D1:
# u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-86-panel.dtb
# u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-dock.dtb
# u-boot/arch/riscv/dts/sun20i-d1-lichee-rv.dtb
# u-boot/arch/riscv/dts/sun20i-d1-nezha.dtb
export DTB=u-boot/arch/riscv/dts/sun20i-d1-lichee-rv-dock.dtb

# folder to mount rootfs
export MNT='mnt'
# folder to store compiled artifacts
export OUT_DIR="${PWD}/output"

# run as root
export SUDO='sudo'

# use arch-chroot?
export USE_CHROOT=0

# use extlinux ('extlinux'), boot.scr ('script') or EFI 'efi' (broken) for loading the kernel?
export BOOT_METHOD='extlinux'

# pinned commits (no notice when things change)
export SOURCE_OPENSBI='https://github.com/smaeul/opensbi'
export SOURCE_UBOOT='https://github.com/smaeul/u-boot'
export SOURCE_KERNEL='https://github.com/smaeul/linux'
export SOURCE_RTL8723='https://github.com/lwfinger/rtl8723ds.git'
# https://github.com/karabek/xradio

# export COMMIT_UBOOT='afc07cec423f17ebb4448a19435292ddacf19c9b' # equals d1-2022-05-26
# export TAG_UBOOT='d1-2022-05-26'
export COMMIT_UBOOT='329e94f16ff84f9cf9341f8dfdff7af1b1e6ee9a' # equals d1-2022-10-31
export TAG_UBOOT='d1-2022-10-31'
# export COMMIT_KERNEL='fe178cf0153d98b71cb01a46c8cc050826a17e77' # equals riscv/d1-wip head
# export TAG_KERNEL='riscv/d1-wip'
# export COMMIT_KERNEL='673a7faa146862c6ba7b0253a5ff22b07de0e0a9' # equals d1/wip head (12.08.2022)
# export TAG_KERNEL='d1/wip'
# export COMMIT_KERNEL='cc63db754b218d3ef9b529a82e04b66252e9bca1' # equals tag d1-wip-v5.18-rc1
# export TAG_KERNEL='d1-wip-v5.18-rc1'
export COMMIT_KERNEL='b466df90d48fb7ef03f331e0c73c8012ac03a12e' # equals d1/all head (03.11.2022)
export TAG_KERNEL='d1/all'
# use this (set to something != 0) to override the check
export IGNORE_COMMITS=0
export DEBUG='n'
