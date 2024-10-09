FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://openssh-fix-sysconfdir-mkdir-for-nfs.patch;patchdir=${WORKDIR} \
"
