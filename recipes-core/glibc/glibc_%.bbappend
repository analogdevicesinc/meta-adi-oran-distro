FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# If ADI_CC_USER_DB_ON_DATA_PART is set, add the patch to allow /etc/passwd, etc. to be migrated to the data partition (/data/active)
SRC_URI += "${@bb.utils.contains('ADI_CC_USER_DB_ON_DATA_PART','1',' file://0001-Update-glibc-to-use-data-active-partition-for-etc-.p.patch', ' ', d)}"

