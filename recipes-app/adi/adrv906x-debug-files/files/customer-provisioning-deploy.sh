#!/usr/bin/env bash
# Copyright 2024 Analog Devices Inc.
# Released under MIT licence
#
###############################################################################
# This is the second step of customer provisioning, i.e. for deployment.
#
# Arguments to the script:
# -- none
#
# Usage(sudo privilege is needed):
# sudo ./customer-provisioning-deploy.sh
#
# Returns:
# 1 for failing;
# 0 for success.
###############################################################################

set -e

# exit with reporting error message
function exit_error () {
    echo "$1"
    exit 1
}

if [[ "$(id -u)" != "0" ]]; then
  echo "sudo $0 (must run as root)"
  exit 1
fi

PATH=${PATH}:/sbin:/usr/sbin

if [[ "$1" ]]; then
    echo "Error: No argument is needed for provisioning deployment. Exited!"
	exit 1
fi

ta_provisioning=optee_app_te_mailbox
exit_code="0"

# check provisioning TA is installed or not
result=$(which "${ta_provisioning}") || exit_code=$?
if [[ ! "${exit_code}" == "0" || ! -f "${result}" ]]; then
    exit_error "Error: Provisioning TA/pTA(${ta_provisioning}) is not found. Exited!"
fi

# provisioning finalize
${ta_provisioning} --prov-finalize  \
    || exit_error "Error: Provisioning finalize failed. Exited!"

# prompt reboot after successful provisioning for keys
echo -e "\nINFO: Customer Provisioning Successful!"
echo "INFO: Please reboot the board to move to 'Deployed' lifecycle!"

exit 0
