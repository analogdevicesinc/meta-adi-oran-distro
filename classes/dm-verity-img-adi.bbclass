inherit dm-verity-img

CONVERSION_DEPENDS:verity:append = " e2fsprogs-native"

ADI_CC_DM_VERITY_ENABLED ?= "1"
ADI_CC_DM_VERITY_FEC_ENABLED ?= "1"

DM_VERITY_IMAGE_DATA_BLOCK_SIZE ?= "4096"
DM_VERITY_IMAGE_HASH_BLOCK_SIZE ?= "4096"
DM_VERITY_IMAGE_FEC_ROOTS ?= "2"

process_verity:append() {
    echo "HASH_SIZE=$HASH_SIZE" >> $ENV
    if [ "$FEC_ENABLED" -eq 0 ]; then
        echo "FEC_ENABLED=0" >> $ENV
    else
        echo "FEC_ENABLED=1" >> $ENV
        echo "FEC_SIZE=$FEC_SIZE" >> $ENV
        echo "FEC_ROOTS=${DM_VERITY_IMAGE_FEC_ROOTS}" >> $ENV
    fi

    echo "DM_VERITY_ENABLED=${ENABLED}" >> $ENV
}

verity_setup() {
    local TYPE=$1
    local INPUT=${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.$TYPE
    local SIZE=$(stat --printf="%s" $INPUT)
    local OUTPUT=$INPUT.verity
    local ENABLED=${ADI_CC_DM_VERITY_ENABLED}
    local FEC_ENABLED=${ADI_CC_DM_VERITY_FEC_ENABLED}
    local HASH_SIZE
    local FEC_SIZE
    local VERITY_OPTS

    VERITY_OPTS="--data-block-size=${DM_VERITY_IMAGE_DATA_BLOCK_SIZE} --hash-block-size=${DM_VERITY_IMAGE_HASH_BLOCK_SIZE}"
    [ "$FEC_ENABLED" -ne 0 ] && VERITY_OPTS="${VERITY_OPTS} --fec-device=rootfs.fec --fec-roots=${DM_VERITY_IMAGE_FEC_ROOTS}"

    cp -a $INPUT rootfs.$TYPE
    veritysetup ${VERITY_OPTS} format rootfs.$TYPE rootfs.hash | tail -n +2 > verity_output.txt
    touch rootfs.fec

    HASH_SIZE=$(stat --printf="%s" rootfs.hash)
    FEC_SIZE=$(stat --printf="%s" rootfs.fec)
    cat verity_output.txt | process_verity
    cat rootfs.$TYPE rootfs.hash rootfs.fec > $OUTPUT
}
