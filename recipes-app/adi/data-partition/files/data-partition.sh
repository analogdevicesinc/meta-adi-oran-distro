#!/bin/sh

FILES_TO_COPY=""
DATA_SRC=/data/defaults
DATA_ACTIVE=/data/active
DATA_RESET=/data/active/reset
FACTORY_RESET_FLAG=/data/active/reset/factory-reset

DATA_PART=$(mount | grep "on ${DATA_ACTIVE}" | tr -s " " " " | cut -d' ' -f1)
if [ -n "$DATA_PART" ]
then
	# Check if factory reset is enabled, if so clear data partition
	if [ -f "${FACTORY_RESET_FLAG}" ]
	then
		TIMESTAMP=$(cat "${FACTORY_RESET_FLAG}")

		umount "${DATA_ACTIVE}"
		mkfs.ext4 -F "${DATA_PART}"
		mount -o noexec,nosuid,nodev "${DATA_PART}" "${DATA_ACTIVE}"

		# Log factory reset to syslog
		mkdir "${DATA_RESET}"
		chown swupdate "${DATA_RESET}"
		echo "Factory reset ${TIMESTAMP}" > "${DATA_RESET}/factoryreset_timestamp"
	fi
fi

echo "Initializing ${DATA_ACTIVE}..."

for item in `echo ${FILES_TO_COPY}`
do
	SRC=$(echo "${DATA_SRC}/${item}" | tr -s /)
	DST=$(echo "${DATA_ACTIVE}/${item}" | tr -s /)
	if [ ! -e "${DST}" ]
	then
		echo "Copying ${SRC} to ${DST}..."
		mkdir -p $(dirname "${DST}")
		cp -p -r "${SRC}" "${DST}"
	else
		echo "${DST} already exists. Skipping."
	fi
done

if [ ! -d "${DATA_RESET}" ]
then
	# Create reset directory and give ownership to swupdate to store factory reset log
	mkdir "${DATA_RESET}"
	chown swupdate "${DATA_RESET}"
fi

sync
exit 0
