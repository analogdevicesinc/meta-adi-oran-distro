#!/bin/sh

FILES_TO_COPY=""
DATA_SRC=/data/defaults
DATA_DST=/data/active

echo "Initializing ${DATA_DST}..."

for item in `echo ${FILES_TO_COPY}`
do
	SRC=$(echo "${DATA_SRC}/${item}" | tr -s /)
	DST=$(echo "${DATA_DST}/${item}" | tr -s /)
	if [ ! -e "${DST}" ]
	then
		echo "Copying ${SRC} to ${DST}..."
		mkdir -p $(dirname "${DST}")
		cp -p -r "${SRC}" "${DST}"
	else
		echo "${DST} already exists. Skipping."
	fi
done

exit 0
