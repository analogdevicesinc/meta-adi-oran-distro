#!/usr/bin/env bash
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#
###############################################################################
# This is the first step of customer provisioning before deployment.
#
# Arguments to the script is with a repeating pattern of [key_id key_path]:
# -- key id1
# -- key file path1
# -- key id2
# -- key file path2
# ...
# -- key idn
# -- key file pathn
#
# Notes: For the key_ids, they should be one of them below.
# long options:
# [	--HST_SEC_DEBUG --HST_SEC_BOOT --HST_PLLSA --HST_IPK ], or
# short options:
# [	-d -b -p -i ]
#
# Usage(sudo privilege is needed. An example of 3 pairs of [key_id key_path]):
# sudo ./customer-provisioning.sh \
#    --HST_IPK       /path/of/the/key/file1 \
#    --HST_IPK       /path/of/the/key/file2 \
#    --HST_SEC_BOOT  /path/of/the/key/file3 \
#
# Returns:
# 1 for failing;
# 0 for success.
###############################################################################

set -e

function usage() {
	echo "Usage: "
    echo "sudo $0 [option key-path][...]"
	echo
	echo "Options:"
	echo
	echo "  -h --help       Show this help and exit."
	echo "  -b, --HST_SEC_BOOT"
	echo "                  Specify the key id is HST_SEC_BOOT."
	echo "  -d, --HST_SEC_DEBUG"
	echo "                  Specify the key id is HST_SEC_DEBUG."
	echo "  -i, --HST_IPK"
	echo "                  Specify the key id is HST_IPK."
	echo "  -p, --HST_PLLSA"
	echo "                  Specify the key id is HST_PLLSA."
	echo
	echo "Arguments:"
	echo
	echo "  key-path"
	echo "    Path to the key file for this key id."
	echo
}

# exit with reporting error message
function exit_error () {
    echo "$1"
    exit 1
}

function parse_key_values() {

    binary_file="0"

    # get the key values from key file
    result=$(openssl pkey -pubin -inform pem -in "${key_path}" -noout -text) \
           || exit_code=$?

    if [[ ! "${exit_code}" == "0" ]]; then
        echo -e "\nINFO: First attempt using openssl hasn't gotten key values for ${key_path}."
        echo -e   "INFO: Key file: ${key_path} could be a binary file.\n"
        binary_file="1"
        exit_code="0"
    else
        regex_pattern='[a-fA-F0-9:[:space:]]+'
        if [[ ${result} =~ (pub:)(${regex_pattern}) ]]; then
            key_values="${BASH_REMATCH[2]}"

            # replace ':' with a whitespace for spliting key value bytes
            key_values=$(echo "${key_values}" | sed 's/:/ /g')

            # remove line feeds
            key_values=$(echo ${key_values} | tr '\n' '~' | sed 's/~/ /g')

        else
            echo "INFO: key file: ${key_path} could be a binary file."
            binary_file="1"
        fi
    fi

    if [[ "${binary_file}" == "1" ]]; then
        key_values=$(hexdump -v -e '/1 "0x%x "' "${key_path}")
    fi

    echo "INFO: From ${key_path}, key values are obtained as: ${key_values}"
    echo "INFO: ${key_values}"
    kv_array=(${key_values})

    # get len of key values
    key_len="${#kv_array[@]}"
    if [[ $((key_id_val)) == $((3)) && $((key_len)) != $((16)) ]]; then 
        echo "Error: key_len should be 16 for 'HST_IPK' type key file: ${key_path}! Exited."
        return 1
    elif [[ !$((key_len)) == $((32)) ]]; then
        echo "Error: key_len should be 32 for 'HST_SEC_DEBUG, HST_SEC_BOOT, or HST_PLLSA' type key file: ${key_path}! Exited."
        return 1
    fi
}

function customer_provisioning() {
	local key_id=$1
	local key_path=$2

    if [[ "${key_id}" == "HST_SEC_DEBUG" ]]; then
        key_id_val="0"
    elif [[ "${key_id}" == "HST_SEC_BOOT" ]]; then
        key_id_val="1"
    elif [[ "${key_id}" == "HST_PLLSA" ]]; then
        key_id_val="2"
    elif [[ "${key_id}" == "HST_IPK" ]]; then
        key_id_val="3"
    else
        echo "Error: key_id= ${key_id} is not recognized. Exited!"
        return 1
    fi

    if [[ ! -f "${key_path}" ]]; then
        echo "Error: ${key_path} is not found. Exited!"
        return 1
    fi

    parse_key_values "${key_path}"

    # provisioning host keys
    echo -e "\nINFO: Calling  ${ta_provisioning} with agruments:"
    echo -e   "INFO: --prov-host-keys ${key_id_val} ${key_len} ${key_values}\n"
    if [[ $((key_len)) == $((16)) ]]; then
        ${ta_provisioning}  --prov-host-keys \
        "${key_id_val}"   "${key_len}" \
        "${kv_array[0]}"  "${kv_array[1]}"  "${kv_array[2]}"  "${kv_array[3]}"  \
        "${kv_array[4]}"  "${kv_array[5]}"  "${kv_array[6]}"  "${kv_array[7]}"  \
        "${kv_array[8]}"  "${kv_array[9]}"  "${kv_array[10]}" "${kv_array[11]}" \
        "${kv_array[12]}" "${kv_array[13]}" "${kv_array[14]}" "${kv_array[15]}" \
            || exit_error "Error: Provisioning host keys failed. Exited!"
    elif [[ $((key_len)) == $((32)) ]]; then
        ${ta_provisioning}  --prov-host-keys \
        "${key_id_val}"   "${key_len}" \
        "${kv_array[0]}"  "${kv_array[1]}"  "${kv_array[2]}"  "${kv_array[3]}"  \
        "${kv_array[4]}"  "${kv_array[5]}"  "${kv_array[6]}"  "${kv_array[7]}"  \
        "${kv_array[8]}"  "${kv_array[9]}"  "${kv_array[10]}" "${kv_array[11]}" \
        "${kv_array[12]}" "${kv_array[13]}" "${kv_array[14]}" "${kv_array[15]}" \
        "${kv_array[16]}" "${kv_array[17]}" "${kv_array[18]}" "${kv_array[19]}" \
        "${kv_array[20]}" "${kv_array[21]}" "${kv_array[22]}" "${kv_array[23]}" \
        "${kv_array[24]}" "${kv_array[25]}" "${kv_array[26]}" "${kv_array[27]}" \
        "${kv_array[28]}" "${kv_array[29]}" "${kv_array[30]}" "${kv_array[31]}" \
            || exit_error "Error: Provisioning host keys failed. Exited!"
    else
        echo "Error: key_len = ${key_len} is not supported. Exited!"
        return 1
    fi

    echo -e "INFO: ${key_path} with key_id ${key_id} has been provisioned successfully!\n"
}

function main() {
	local shortopts="b:d:hi:p:"
	local longopts="HST_SEC_BOOT:,HST_SEC_DEBUG:,help,HST_IPK:,HST_PLLSA:"

    if [[ "$(id -u)" != "0" ]]; then
      echo "Usage: sudo $0 [option key-path][...](must run as root)"
      exit 1
    fi

    PATH=${PATH}:/sbin:/usr/sbin

    # key_id and key_path arraies for storing from arguments
    key_ids=()
    key_paths=()

    # number of [key_id, key_path] pairs
    count=0

    provisioning_args=$(getopt -o ${shortopts} --long ${longopts} -- "$@")
    if [[ $? -ne 0 ]]; then
        echo "Error: Input arguments invalid! Exited!"
        exit 1;
    fi

    eval set -- "$provisioning_args"
    while true; do
      case "$1" in
        -b | --HST_SEC_BOOT)
            echo "Processing '$1' option. Input argument is '$2'"
            count=$((count+1))
            key_ids[count]="HST_SEC_BOOT" && key_paths[count]=$2
            shift 2
            ;;
        -d | --HST_SEC_DEBUG)
            echo "Processing '$1' option. Input argument is '$2'"
            count=$((count+1))
            key_ids[count]="HST_SEC_DEBUG" && key_paths[count]=$2
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        -i | --HST_IPK)
            echo "Processing '$1' option. Input argument is '$2'"
            count=$((count+1))
            key_ids[count]="HST_IPK" && key_paths[count]=$2
            shift 2
            ;;
        -p | --HST_PLLSA)
            echo "Processing '$1' option. Input argument is '$2'"
            count=$((count+1))
            key_ids[count]="HST_PLLSA" && key_paths[count]=$2
            shift 2
            ;;
        --) 
            shift;
            break
            ;;
        *)
            echo "Error: Unexpected option: $1"
            usage
            exit 1
            ;;
      esac
    done

    ta_provisioning=optee_app_te_mailbox
    exit_code="0"

    # check provisioning TA is installed or not
    result=$(which "${ta_provisioning}") || exit_code=$?
    if [[ ! "${exit_code}" == "0" || ! -f "${result}" ]]; then
        echo "Error: Provisioning TA/pTA(${ta_provisioning}) is not found. Exited!"
        exit 1
    fi

    if [[ "${count}" == "0" ]] ;then
        echo "Error: No [key_id key_path] provided for provisioning. Exited!"
        exit 1
    fi

    for i in "${!key_ids[@]}"
    do
        key_id="${key_ids[i]}"
        key_path="${key_paths[i]}"
        echo -e "\n\nINFO: key_path$i = ${key_path}"

        customer_provisioning "${key_id}" "${key_path}" \
        || exit_error "Error: Provisioning ${key_ids} for ${key_path} failed. Exited!"
    done

    # provisioning prepare finalize
    ${ta_provisioning} --prov-prepare-finalize \
    || exit_error "Error: Provisioning prepare finalize failed. Exited!"

    # prompt reboot after successful prepare finalization for keys
    echo -e "\nINFO: Provisioning prepare finalization is successful!"
    echo "INFO: Please reboot the board to move to 'Customer Provisioned' lifecycle!"

    exit 0
}

main "$@"
