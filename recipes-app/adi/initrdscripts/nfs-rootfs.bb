SUMMARY = "NFS mount of rootfs for initramfs"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

RDEPENDS:${PN} = " \
    nfs-utils \
    nfs-utils-client \
"

# NFS is disabled by default
# These should be overridden in local.conf or a .bbappend
NFS_ENABLED ?= "0"
NFS_INTF ?= ""
NFS_LCL_IP_ADDR ?= ""
NFS_HOST_IP_ADDR ?= ""
NFS_SHARE_PATH ?= ""

do_install() {
    install -d ${D}${sysconfdir}
    echo 'NFS_ENABLED=${NFS_ENABLED}' >> "${D}${sysconfdir}/nfs-cfg.env"
    echo 'NFS_INTF=${NFS_INTF}' >> "${D}${sysconfdir}/nfs-cfg.env"
    echo 'NFS_LCL_IP_ADDR=${NFS_LCL_IP_ADDR}' >> "${D}${sysconfdir}/nfs-cfg.env"
    echo 'NFS_HOST_IP_ADDR=${NFS_HOST_IP_ADDR}' >> "${D}${sysconfdir}/nfs-cfg.env"
    echo 'NFS_SHARE_PATH=${NFS_SHARE_PATH}' >> "${D}${sysconfdir}/nfs-cfg.env"
}

FILES:${PN} = " ${sysconfdir}/nfs-cfg.env"
