do_configure:append() {
    echo "PATH=""$""PATH:/usr/local/sbin:/usr/sbin:/sbin" >> ${WORKDIR}/share/dot.profile
}