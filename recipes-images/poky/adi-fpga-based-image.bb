require recipes-core/images/core-image-base.bb
require ./users.inc


DEPENDS:append = " \
    bash \
    perl \
    "

IMAGE_INSTALL:append = " \
    packagegroup-adi-essential \
    packagegroup-core-ssh-openssh \
    "

IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "" ,d)}"

IMAGE_TYPES = "cpio.gz tar.gz"

export IMAGE_BASENAME = "adi-console-image"

set_rootfs_env() {
    # TODO: Check if we can move this to source recipe
    # Source environment from "adi-files" recipe.
    echo "\nsource /etc/environment" >> ${IMAGE_ROOTFS}/etc/profile
}

enable_autologin() {
    if ${@bb.utils.contains('ADI_CC_SYSTEMD_INIT', '1', 'true', 'false', d)}; then
        sed -i "s/ExecStart=-\/sbin\/agetty/ExecStart=-\/sbin\/agetty --autologin root /g"  ${IMAGE_ROOTFS}/lib/systemd/system/serial-getty@.service
    else
        sed -i "s/1:12345:respawn:.*/S0:12345:respawn:\/sbin\/getty 115200 ttyS0 -n -l \/bin\/autologin/g" ${IMAGE_ROOTFS}/etc/inittab
        echo "#!/bin/sh\nexec /bin/login -f root" > ${IMAGE_ROOTFS}/bin/autologin
        chmod 0755 ${IMAGE_ROOTFS}/bin/autologin
    fi
}

ROOTFS_POSTPROCESS_COMMAND:append= " enable_autologin; set_rootfs_env; "
