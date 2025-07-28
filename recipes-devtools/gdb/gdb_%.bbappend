FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append = " file://0001-gdbserver-linux-read-string-one-page-at-a-time.patch"
