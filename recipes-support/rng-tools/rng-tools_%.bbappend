SUMMARY = "patch to the rng-tools init script to enable it only in real hardware."
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://rng-tools-run-in-asic.patch;patchdir=${WORKDIR} \
"
