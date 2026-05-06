# TODO: Remove when libyang5-based ras-libs prebuilt package is available
# Pre-built binaries are linked against libyang.so.4 and will be updated once
# ras-core is rebuilt against libyang 5. Suppress the QA check and prevent
# libyang.so.4 from being recorded as an RPM Requires (would block image build).
INSANE_SKIP:${PN}:append = " file-rdeps"
PRIVATE_LIBS:${PN} = "libyang.so.4"
