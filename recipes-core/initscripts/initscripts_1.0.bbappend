FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://sendsigs-status.patch;patchdir=${WORKDIR} \
"
