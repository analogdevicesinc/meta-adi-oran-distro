SUMMARY = "host key for user adi"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit externalsrc

INHIBIT_DEFAULT_DEPS = "1"

RDEPENDS:${PN} = "sshd"

#add directory contains the public key to install
ADI_CC_SSH_PUBKEY ??= ""
SSH_KEY_DIR=""
SSH_KEY_FILE=""

EXTERNALSRC ??= "${SSH_KEY_DIR}"

do_install_key(){
	install -d ${D}${sysconfdir}/ssh
	if [ -f "${SSH_KEY_DIR}/${SSH_KEY_FILE}" ]; then
		install ${SSH_KEY_DIR}/${SSH_KEY_FILE} ${D}${sysconfdir}/ssh/
		chmod 0600 ${D}${sysconfdir}/ssh/*
		chmod 0644 ${D}${sysconfdir}/ssh/${SSH_KEY_FILE}
	fi
}

python do_install () {
    import os
	
    file = d.getVar("ADI_CC_SSH_PUBKEY",True)
    if os.path.isfile(file):
        d.setVar('SSH_KEY_DIR',os.path.dirname(file))
        d.setVar('SSH_KEY_FILE',os.path.basename(file))
        bb.build.exec_func("do_install_key", d)
}