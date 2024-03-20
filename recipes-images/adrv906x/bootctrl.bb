SUMMARY = "bootctrl for ADRV906x: slot selector for fip,kernel, and rootfs, etc."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

DEPENDS:append = " xxd-native"
inherit python3native deploy

FILESEXTRAPATHS:prepend := "${THISDIR}:"
SRC_URI = " file://python-scripts/crc32.py"

BOOT_CTRL_FILE ?= "bootctrl_cfg.bin"
BOOT_CTRL_MAGIC ?= "AD1B007C"
BOOT_CTRL_VERSION ?= "00000001"
BOOT_CTRL_ACTIVE_SLOT_ID ?= "00000061"

do_compile() {
    TMP_FILE1="tmp.1"
    TMP_FILE2="tmp.2"

    b0=$(echo "${BOOT_CTRL_MAGIC}" | cut -c7-8)
    b1=$(echo "${BOOT_CTRL_MAGIC}" | cut -c5-6)
    b2=$(echo "${BOOT_CTRL_MAGIC}" | cut -c3-4)
    b3=$(echo "${BOOT_CTRL_MAGIC}" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" > ${WORKDIR}/${TMP_FILE1}

    b0=$(echo "${BOOT_CTRL_VERSION}" | cut -c7-8)
    b1=$(echo "${BOOT_CTRL_VERSION}" | cut -c5-6)
    b2=$(echo "${BOOT_CTRL_VERSION}" | cut -c3-4)
    b3=$(echo "${BOOT_CTRL_VERSION}" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" >> ${WORKDIR}/${TMP_FILE1}

    b0=$(echo "${BOOT_CTRL_ACTIVE_SLOT_ID}" | cut -c7-8)
    b1=$(echo "${BOOT_CTRL_ACTIVE_SLOT_ID}" | cut -c5-6)
    b2=$(echo "${BOOT_CTRL_ACTIVE_SLOT_ID}" | cut -c3-4)
    b3=$(echo "${BOOT_CTRL_ACTIVE_SLOT_ID}" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" >> ${WORKDIR}/${TMP_FILE1}

    xxd -r -p ${WORKDIR}/${TMP_FILE1} > ${WORKDIR}/${TMP_FILE2}
    CRC=$(python3 "${WORKDIR}/python-scripts/crc32.py" "${WORKDIR}/${TMP_FILE2}")

    b0=$(echo "${CRC}" | cut -c7-8)
    b1=$(echo "${CRC}" | cut -c5-6)
    b2=$(echo "${CRC}" | cut -c3-4)
    b3=$(echo "${CRC}" | cut -c1-2)
    echo "${b0}${b1}${b2}${b3}" >> ${WORKDIR}/${TMP_FILE1}
    xxd -r -p ${WORKDIR}/${TMP_FILE1} > ${WORKDIR}/${BOOT_CTRL_FILE}
}

do_deploy(){
    install -m 644 ${WORKDIR}/${BOOT_CTRL_FILE} ${DEPLOYDIR}/${BOOT_CTRL_FILE}
}

PROVIDES = "bootctrl"
addtask deploy before do_build after do_compile