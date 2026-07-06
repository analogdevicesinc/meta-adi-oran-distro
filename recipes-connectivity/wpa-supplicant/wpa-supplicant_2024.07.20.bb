SUMMARY = "Client for Wi-Fi Protected Access (WPA)"
HOMEPAGE = "http://w1.fi/wpa_supplicant/"
BUGTRACKER = "http://w1.fi/security/"
SECTION = "network"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=5ebcb90236d1ad640558c3d3cd3035df \
                    file://README;beginline=1;endline=56;md5=6e4b25e7d74bfc44a32ba37bdf5210a6"
DEPENDS = "libnl openssl"
SRCREV  = "d945ddd368085f255e68328f2d3b020ceea359af"
SRC_URI = "git://w1.fi/hostap.git;protocol=https;branch=main \
           file://wpa_supplicant.conf-adrv906x \
          "
PV = "2.11+git${SRCREV}"
PACKAGECONFIG ??= "gnutls"
PACKAGECONFIG[gnutls] = ",,gnutls libgcrypt"
PACKAGECONFIG[openssl] = ",,openssl"

inherit pkgconfig

CVE_PRODUCT = "wpa_supplicant"

S = "${WORKDIR}/git"

FILES:${PN} += " \
	${sbindir}/wpa_supplicant \
	${sysconfdir}/wpa_supplicant.conf \
"

do_configure () {
	${MAKE} -C wpa_supplicant clean
	install -m 0755 ${S}/wpa_supplicant/defconfig wpa_supplicant/.config
	sed -i '/CONFIG_CTRL_IFACE_DBUS/d' wpa_supplicant/.config

	if echo "${PACKAGECONFIG}" | grep -qw "openssl"; then
        	ssl=openssl
	elif echo "${PACKAGECONFIG}" | grep -qw "gnutls"; then
        	ssl=gnutls
	fi
	if [ -n "$ssl" ]; then
        	sed -i "s/%ssl%/$ssl/" wpa_supplicant/.config
	fi

	# For rebuild
	rm -f wpa_supplicant/*.d wpa_supplicant/dbus/*.d
}

export EXTRA_CFLAGS = "${CFLAGS}"
export BINDIR = "${sbindir}"

do_compile () {
	unset CFLAGS CPPFLAGS CXXFLAGS
	sed -e "s:CFLAGS\ =.*:& \$(EXTRA_CFLAGS):g" -i ${S}/src/lib.rules
	oe_runmake -C wpa_supplicant
}

do_install () {
	install -d ${D}${sbindir}
	install -m 755 ${S}/wpa_supplicant/wpa_supplicant ${D}${sbindir}

	install -d ${D}${sysconfdir}
	install -m 644 ${WORKDIR}/wpa_supplicant.conf-adrv906x ${D}${sysconfdir}/wpa_supplicant.conf
}

