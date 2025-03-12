
do_install:append() {
    echo "net.ipv4.conf.all.arp_filter = 1" >> ${D}${sysconfdir}/sysctl.conf
    echo "net.ipv4.conf.default.arp_filter = 1" >> ${D}${sysconfdir}/sysctl.conf
}
