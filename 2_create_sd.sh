#!/usr/bin/sh

set -e
# set -x

. ./consts.sh

check_root_fs() {
    if [ ! -f "${ROOT_FS}" ]; then
        wget "${ROOT_FS_DL}"
    fi
}

check_sd_card_is_block_device() {
    _DEVICE=${1}

    if [ -z "${_DEVICE}" ] || [ ! -b "${_DEVICE}" ]; then
        echo "Error: '${_DEVICE}' is empty or not a block device"
        exit 1
    fi
}

check_required_file() {
    if [ ! -f "${1}" ]; then
        echo "Missing file: ${1}, did you compile everything first?"
        exit 1
    fi
}

probe_partition_separator() {
    _DEVICE=${1}

    [ -b "${_DEVICE}p1" ] && echo 'p' || echo ''
}

DEVICE=${1}

check_sd_card_is_block_device "${DEVICE}"
check_root_fs
for FILE in 8723ds.ko u-boot-sunxi-with-spl.bin Image.gz Image; do
    check_required_file "${OUT_DIR}/${FILE}"
done

# format disk
if [ -z "${CI_BUILD}" ]; then
    echo "Formatting ${DEVICE}, this will REMOVE EVERYTHING on it!"
    printf "Continue? (y/N): "
    read -r confirm && [ "${confirm}" = "y" ] || [ "${confirm}" = "Y" ] || exit 1
fi

${SUDO} dd if=/dev/zero of="${DEVICE}" bs=1M count=40
${SUDO} parted -s -a optimal -- "${DEVICE}" mklabel gpt
${SUDO} parted -s -a optimal -- "${DEVICE}" mkpart primary fat32 40MiB 1024MiB
${SUDO} parted -s -a optimal -- "${DEVICE}" mkpart primary ext4 1064MiB 100%
${SUDO} partprobe "${DEVICE}"
PART_IDENTITYFIER=$(probe_partition_separator "${DEVICE}")
${SUDO} mkfs.ext2 -F -L boot "${DEVICE}${PART_IDENTITYFIER}1"
${SUDO} mkfs.ext4 -F -L root "${DEVICE}${PART_IDENTITYFIER}2"

if [ "${BOOT_METHOD}" = 'efi' ]; then
    ${SUDO} mkfs.fat -F 32 -n boot "${DEVICE}${PART_IDENTITYFIER}1"
    # does not work
    # ${SUDO} parted -s -- set "${DEVICE}${PART_IDENTITYFIER}1" boot true
    # ${SUDO} parted -s -- set "${DEVICE}${PART_IDENTITYFIER}1" esp true
fi

# flash boot things
${SUDO} dd if="${OUT_DIR}/u-boot-sunxi-with-spl.bin" of="${DEVICE}" bs=1024 seek=128

# mount it
mkdir -p "${MNT}"
${SUDO} mount "${DEVICE}${PART_IDENTITYFIER}2" "${MNT}"
${SUDO} mkdir -p "${MNT}/boot"
${SUDO} mount "${DEVICE}${PART_IDENTITYFIER}1" "${MNT}/boot"

# extract rootfs
${SUDO} tar -xv --xz -f "${ROOT_FS}" -C "${MNT}"

# remove the default kernel image
${SUDO} rm "${MNT}/boot/Image"

# install kernel and modules
${SUDO} cp "${OUT_DIR}/Image.gz" "${OUT_DIR}/Image" "${MNT}/boot/"
cd build/linux-build
KERNEL_RELEASE=$(make ARCH="${ARCH}" -s kernelversion)
${SUDO} make ARCH="${ARCH}" INSTALL_MOD_PATH="../../${MNT}" KERNELRELEASE="${KERNEL_RELEASE}" modules_install
cd ../..
${SUDO} install -D -p -m 644 "${OUT_DIR}/8723ds.ko" "${MNT}/lib/modules/${KERNEL_RELEASE}/kernel/drivers/net/wireless/8723ds.ko"

${SUDO} rm "${MNT}/lib/modules/${KERNEL_RELEASE}/build"
${SUDO} rm "${MNT}/lib/modules/${KERNEL_RELEASE}/source"

${SUDO} depmod -a -b "${MNT}" "${KERNEL_RELEASE}"
echo '8723ds' >>8723ds.conf
${SUDO} mv 8723ds.conf "${MNT}/etc/modules-load.d/"

# install U-Boot
if [ "${BOOT_METHOD}" = 'script' ]; then
    ${SUDO} cp "${OUT_DIR}/boot.scr" "${MNT}/boot/"
elif [ "${BOOT_METHOD}" = 'extlinux' ]; then
    ${SUDO} mkdir -p "${MNT}/boot/extlinux"
    cat <<EOF >extlinux.conf
label default
        linux   ../Image
        append  earlycon=sbi console=ttyS0,115200n8 root=/dev/mmcblk0p2 rootwait cma=96M
EOF
    ${SUDO} mv extlinux.conf "${MNT}/boot/extlinux/extlinux.conf"
elif [ "${BOOT_METHOD}" = 'efi' ]; then
    echo '###################################################'
    echo '# run "bootctl --esp-path=/boot/ install" in chroot'
    echo '###################################################'

    ${SUDO} mkdir -p "${MNT}/boot/loader/entries"
    cat <<EOF >opensuse.conf
title	openSUSE
linux	/Image

options	earlycon=sbi console=ttyS0,115200n8 root=/dev/mmcblk0p2 rootwait cma=96M ro
EOF
    ${SUDO} mv opensuse.conf "${MNT}/boot/loader/entries/opensuse.conf"
fi

# fstab
# FIXME for EFI vfat is used instead of ext2
# When using LABEL= or UUID= for device, systemd-remount-fs.service fails
# for some reason.
cat <<EOF >fstab
# <device>    <dir>        <type>        <options>            <dump> <pass>
/dev/mmcblk0p1    /boot        ext2          rw,defaults,noatime  0      1
/dev/mmcblk0p2    /            ext4          rw,defaults,noatime  0      2
EOF
${SUDO} cp fstab "${MNT}/etc/fstab"
rm fstab

# set hostname
echo 'opensuse-d1' >hostname
${SUDO} mv hostname "${MNT}/etc/"

echo 'Done! You can now plug in a console adapter in your board, and start playing aroun with openSUSE!'

${SUDO} umount -R "${MNT}"
exit 0
