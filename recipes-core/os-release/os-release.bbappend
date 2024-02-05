OS_RELEASE_FIELDS:append = " MACHINE HOME_URL SUPPORT_URL BUG_REPORT_URL"
HOME_URL = "https://github.com/analogdevicesinc"
SUPPORT_URL = "https://github.com/analogdevicesinc"
BUG_REPORT_URL = "https://github.com/analogdevicesinc"

python fn_custom_variables() {

    customVersion = d.getVar('ADI_CC_BUILD_VERSION')
    if customVersion:
        bb.note("ADI_CC_BUILD_VERSION is defined!")
        d.setVar('DISTRO_VERSION', customVersion)
    else:
        customVersion = d.getVar('VERSION_META')
        if customVersion:
            bb.note("VERSION_META is defined!")
            d.setVar('VERSION_ID', customVersion)
            customVersionShort = d.getVar('VERSION_META')[0:5]
            if customVersionShort:
                d.setVar('DISTRO_VERSION', customVersionShort)
}

do_compile:prepend() {
    bb.build.exec_func('fn_custom_variables', d)
}