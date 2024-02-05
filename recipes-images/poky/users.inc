inherit extrausers

USER_ADI = "adi"
#generate password with "mkpasswd -m sha-512 <password> -s "analog12""
USER_PASSWD ?= "\$6\$analog12\$1jTDujwXhhDu6NKOXLwpD.p.Z63vGUMVxVy9sJuwJnEPRHc/cSk2ck9sAPFspKTH3S8nS7eVdmV3vmUBpraN81"
USER_HOME = "home/${USER_ADI}"

EXTRA_USERS_PARAMS = " \
    useradd -p '${USER_PASSWD}' ${USER_ADI}; \
    usermod -a -G sudo ${USER_ADI}; \
    "

enable_sudoers() {
    echo "${USER_ADI} ALL=(ALL:ALL) ALL" > ${IMAGE_ROOTFS}/${sysconfdir}/sudoers.d/${USER_ADI}
}

#install user's ssh pub key on the server
IMAGE_INSTALL:append = "${@bb.utils.contains("INT_ADI_CC_SSH_PUBKEY", "", "ssh-user-hostkey", "" ,d)}" 
INT_ADI_CC_SSH_PUBKEY ??= ""

install_ssh_key() {
    if [ -f "${INT_ADI_CC_SSH_PUBKEY}" ]; then
        ssh_key_file=$(basename ${INT_ADI_CC_SSH_PUBKEY})
        if [ -f "${IMAGE_ROOTFS}${sysconfdir}/ssh/$ssh_key_file" ]; then
            install -d ${IMAGE_ROOTFS}/home/${USER_ADI}/.ssh
            cat ${IMAGE_ROOTFS}${sysconfdir}/ssh/$ssh_key_file >> ${IMAGE_ROOTFS}/${USER_HOME}/.ssh/authorized_keys
        fi
    fi
}

set_user_env(){
    echo "PATH=""$""PATH:/usr/local/sbin:/usr/sbin:/sbin" >> ${IMAGE_ROOTFS}/${USER_HOME}/.profile
}

#TODO
#meta/classes/extrausers.bbclass
#uses :append to add set_user_group function"
#which does not work. add it here
#it can be removed after kirkstone fixes its bug or with an upgraded yocto version

ROOTFS_POSTPROCESS_COMMAND:append = " set_user_group; enable_sudoers; install_ssh_key; set_user_env;"
