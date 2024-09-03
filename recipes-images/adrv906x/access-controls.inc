# Access controls for ADRV906X reference design
# Requires extrausers
# Requires adi-rootfs-postcommands

# Add udev device access rules
IMAGE_INSTALL:append = " \
    udev-access-policy \
    "

# Set user/group/mode policy for any rootfs files
IMAGE_SECURITY_POLICY_SETTINGS = " \
    /etc/network/interfaces,0644,root:network; \
    /opt/adi/adrv906x,,-R adrv906x_server:adrv906x_server; \
    "

# Set user accounts, groups, group membership
ADI_USER_PASSWD = "\$5\$sfAG0Qrs6B\$DNNkFVFV7itj7Y0q6bGlr0nXibofyTaUQO0CJs16pJ/"
EXTRA_USERS_PARAMS = "\
    groupadd adi-oru-uio; \
    groupadd bootcfg; \
    groupadd sram_mmap; \
    groupadd gpio; \
    groupadd tee; \
    groupadd network; \
    groupadd spidev; \
    groupadd i2c; \
    groupadd eeprom; \
    usermod -L -e 1 -s /sbin/nologin root; \
    useradd -p '${ADI_USER_PASSWD}' adi; \
    useradd -M adrv906x_server; \
    usermod -L -e 1 -s /sbin/nologin adrv906x_server; \
    usermod -a -G adi-oru-uio,bootcfg,sram_mmap,gpio,tee,dialout,shutdown adrv906x_server; \
    useradd -M adrv906x_ras; \
    usermod -L -e 1 -s /sbin/nologin adrv906x_ras; \
    usermod -a -G spidev,i2c,eeprom,dialout,gpio,tee,shutdown adrv906x_ras; \
    useradd -M swupdate; \
    usermod -L -e 1 -s /sbin/nologin swupdate; \
    usermod -a -G disk,bootcfg,shutdown swupdate; \
    "

# Enable sudo for the adi user. Developer image only.
enable_sudo_group() {
    # Sets the following line in the sudeors file:
    # %sudo   ALL=(ALL:ALL) ALL
    sed -i 's/^#\s*\(%sudo\s*ALL=(ALL:ALL)\s*ALL\)/\1/'  ${IMAGE_ROOTFS}/etc/sudoers
}
EXTRA_USERS_PARAMS:append = "${@bb.utils.contains('ADI_CC_BOOT_DEBUG', '1', ' usermod -a -G sudo adi;', ' ', d)}"
ROOTFS_POSTPROCESS_COMMAND:append = "${@bb.utils.contains('ADI_CC_BOOT_DEBUG', '1', ' enable_sudo_group;', ' ', d)}"
