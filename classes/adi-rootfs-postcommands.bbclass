IMAGE_FEATURES[validitems] += "data-partition"
IMAGE_PREPROCESS_COMMAND += '${@bb.utils.contains("IMAGE_FEATURES", "data-partition", "adi_data_partition_hook; ", "",d)}'

#
# A hook function to support the data-partition image feature
# Adapted from rootfs-postcommands.bbclass
#
adi_data_partition_hook () {
	# If using the data partition, update the ssh host key location
	if [ -d ${IMAGE_ROOTFS}/etc/ssh ]; then
		if [ ! -e ${IMAGE_ROOTFS}/etc/ssh/ssh_host_rsa_key ]; then
			if [ -e ${IMAGE_ROOTFS}/etc/default/ssh ]; then
				sed -i '/SYSCONFDIR=/d' ${IMAGE_ROOTFS}/etc/default/ssh
			fi
			sed -i '/HostKey/d' ${IMAGE_ROOTFS}/etc/ssh/sshd_config
			echo "HostKey /etc/ssh/keys/ssh_host_rsa_key" >> ${IMAGE_ROOTFS}/etc/ssh/sshd_config
			echo "HostKey /etc/ssh/keys/ssh_host_ecdsa_key" >> ${IMAGE_ROOTFS}/etc/ssh/sshd_config
			echo "HostKey /etc/ssh/keys/ssh_host_ed25519_key" >> ${IMAGE_ROOTFS}/etc/ssh/sshd_config
			cp ${IMAGE_ROOTFS}/etc/ssh/sshd_config ${IMAGE_ROOTFS}/etc/ssh/sshd_config_readonly
			rm -rf ${IMAGE_ROOTFS}/etc/ssh/keys
			mkdir -p ${IMAGE_ROOTFS}/etc/ssh/keys
		fi
	fi

	# Also tweak the key location for dropbear in the same way
	if [ -d ${IMAGE_ROOTFS}/etc/dropbear ]; then
		if [ ! -e ${IMAGE_ROOTFS}/etc/dropbear/dropbear_rsa_host_key ]; then
			sed -i '/DROPBEAR_RSAKEY_DIR=/d' ${IMAGE_ROOTFS}/etc/default/dropbear
			echo "DROPBEAR_RSAKEY_DIR=/etc/dropbear/keys" >> ${IMAGE_ROOTFS}/etc/default/dropbear
			rm -rf ${IMAGE_ROOTFS}/etc/dropbear/keys
			mkdir -p ${IMAGE_ROOTFS}/etc/dropbear/keys
		fi
	fi

	# Set user/group/mode settings as specified in IMAGE_SECURITY_POLICY_SETTINGS
	security_policy_settings="${IMAGE_SECURITY_POLICY_SETTINGS}"
	setting=`echo $security_policy_settings | cut -d ';' -f1`
	remaining=`echo $security_policy_settings | cut -d ';' -f2-`
	while test "x$setting" != "x"; do
		file=`echo $setting | cut -d ' ' -f1`
		chmod_opts=`echo $setting | cut -d ' ' -f2`
		chown_opts=`echo $setting | cut -d ' ' -f3`
		chmod $chmod_opts ${IMAGE_ROOTFS}/$file
		chown $chown_opts ${IMAGE_ROOTFS}/$file
		# Avoid infinite loop if the last parameter doesn't end with ';'
		if [ "$setting" = "$remaining" ]; then
			break
		fi
		# iterate to the next setting
		setting=`echo $remaining | cut -d ';' -f1`
		remaining=`echo $remaining | cut -d ';' -f2-`
	done

	# Create symlinks from rootfs to data partition
	for item in `echo ${IMAGE_DATA_PART_FILES}`
	do
		rm -rf ${IMAGE_ROOTFS}/${item}
		ln -s /data/active${item} ${IMAGE_ROOTFS}/${item}
	done

	# For items with default values:
	# 1) Copy default to /data/defaults
	# 2) Create symlinks from rootfs to data partition
	# 3) Update list of files to copy for the data partition init script
	for item in `echo ${IMAGE_DATA_PART_FILES_WITH_DFLTS}`
	do
		mkdir -p $(dirname ${IMAGE_ROOTFS}/data/defaults/${item})
		cp -p -r ${IMAGE_ROOTFS}/${item} ${IMAGE_ROOTFS}/data/defaults/${item}
		rm -rf ${IMAGE_ROOTFS}/${item}
		ln -s /data/active${item} ${IMAGE_ROOTFS}/${item}
	done
	sed -i 's@FILES_TO_COPY=""@FILES_TO_COPY="'"${IMAGE_DATA_PART_FILES_WITH_DFLTS}"'"@g' ${IMAGE_ROOTFS}/etc/init.d/data-partition.sh
	sed -i 's@  *@ @g' ${IMAGE_ROOTFS}/etc/init.d/data-partition.sh
}

