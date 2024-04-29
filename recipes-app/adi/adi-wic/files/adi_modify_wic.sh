#!/bin/bash

#-------------------------------------------------------------------------------------
# adi_modify_wic.sh -- rebuilds a WIC image modifying the kernel/dtbs in the FIT image
#
# ./adi_modify_wic.sh -w <wic_image> -y <keys_dir> [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>] [-o <new_wic_image>]
#
# Arguments:
#   -w <wic_image>   path to the input WIC image
#   -y <keys_dir>    path to the fit keys directory
#   -k <new_kernel>  path to the new kernel binary
#   -d <new_dtb>     path to the new devicetree
#   -s <new_sec_dtb> path to the new secondary devicetree
#   -r <new_ramdisk> path to the new ramdisk
#   -o <output_wic>  path to the output wic. If not provided, modified wic name is "new_<wic_image>"
#
# Returns 0 on success, 1 on failure
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------------------

# FIT image location inside WIC
FIT_IMAGE_PARTNUM="5"
FIT_IMAGE="kernel_fit.itb"

# Internals
# - WIC file
MY_WIC_IMAGE="adi.wic"
# - FIT image
MY_FIT_IMAGE="adi.itb"

#-------------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------------
print_help()
{
    echo
    echo "$(basename $1) -w <wic_image> -y <keys_dir> [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>] [-o <new_wic_image>]"
    echo
    echo "Arguments:"
    echo "  -w <wic_image>   path to the input WIC image"
    echo "  -y <keys_dir>    path to the fit keys directory"
    echo "  -k <new_kernel>  path to the new kernel binary"
    echo "  -d <new_dtb>     path to the new devicetree"
    echo "  -s <new_sec_dtb> path to the new secondary devicetree"
    echo "  -r <new_ramdisk> path to the new ramdisk"
    echo "  -o <output_wic>  path to the output wic. If not provided, modified wic name is \"new_<wic_image>\""
    echo
    echo "Returns 0 on success, 1 on failure"
    echo
}

print_error()
{
    echo "ERROR: $1"
    exit 1
}

#-------------------------------------------------------------------------------------
# MAIN
#-------------------------------------------------------------------------------------

# Long opts to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    '--help') set -- "$@" '-h'   ;;
    *)        set -- "$@" "$arg" ;;
  esac
done

# Gather options
while getopts w:k:d:s:r:y:o:h flag; do
    case "${flag}" in
        w) wic_image=$(realpath "${OPTARG}");;
        k) new_kernel=$(realpath "${OPTARG}");;
        d) new_dtb=$(realpath "${OPTARG}");;
        s) new_sec_dtb=$(realpath "${OPTARG}");;
        r) new_ramdisk=$(realpath "${OPTARG}");;
        y) keys_dir=$(realpath "${OPTARG}");;
        o) output_wic=$(realpath "${OPTARG}");;
        h) print_help "$0"; exit 0;;
        *) print_error "Unkown parameter -${flag}";;
    esac
done

# Verify dependencies from SDK
# - WIC
if ! type wic &> /dev/null; then
    print_error "WIC not available. Please source the SDK environment"
fi
# - mkimage
if ! type mkimage &> /dev/null; then
    print_error "mkimage not available. Please source the SDK environment"
fi

# Verify parameters
if [[ -z "$wic_image" ]]; then print_error "WIC image not selected"          ; fi
if [[ -z "$keys_dir" ]];  then print_error "FIT keys directory not selected" ; fi

if [[ ! -f "$wic_image" ]]; then print_error "WIC file \"$wic_image\" not found"; fi
if [[ ! -d "$keys_dir" ]];  then print_error "FIT keys dir \"$keys_dir\" not found" ; fi

if [[ -n "$new_kernel" ]]  && [[ ! -f "$new_kernel" ]];  then print_error "New Kernel \"$new_kernel\" not found"         ; fi
if [[ -n "$new_dtb" ]]     && [[ ! -f "$new_dtb" ]];     then print_error "New DTB \"$new_dtb\" not found"               ; fi
if [[ -n "$new_sec_dtb" ]] && [[ ! -f "$new_sec_dtb" ]]; then print_error "New Secondary DTB \"$new_sec_dtb\" not found" ; fi
if [[ -n "$new_ramdisk" ]] && [[ ! -f "$new_ramdisk" ]]; then print_error "New Ramdisk \"$new_ramdisk\" not found"       ; fi

# Verify WIC image
wic ls "$wic_image" > /dev/null 2>&1 || print_error "\"$wic_image\" is not a WIC image"

# Make temp folder
TMP_DIR="$(mktemp -d)"

pushd "$TMP_DIR" > /dev/null || print_error "Cannot pushd to $TMPDIR"

# Copy source files here
cp "$wic_image" "$MY_WIC_IMAGE"

# Extract original FIT image
echo "Extracting original FIT image from WIC..."
wic cp "$MY_WIC_IMAGE:$FIT_IMAGE_PARTNUM/$FIT_IMAGE" "$MY_FIT_IMAGE"

# Modify FIT image
params="-f $MY_FIT_IMAGE -y $keys_dir -o $FIT_IMAGE"
if [[ -n "$new_kernel" ]] ; then params+=" -k $new_kernel";  fi
if [[ -n "$new_dtb" ]]    ; then params+=" -d $new_dtb";     fi
if [[ -n "$new_sec_dtb" ]]; then params+=" -s $new_sec_dtb"; fi
if [[ -n "$new_ramdisk" ]]; then params+=" -r $new_ramdisk"; fi
adi_modify_kernel_fit $params

# Replace FIT image in WIC image
echo "Replacing FIT image in WIC... "
wic rm "$MY_WIC_IMAGE":"$FIT_IMAGE_PARTNUM"/"$FIT_IMAGE"
wic cp $FIT_IMAGE "$MY_WIC_IMAGE":"$FIT_IMAGE_PARTNUM"

popd > /dev/null || print_error "Cannot popd from $TMPDIR"

if [[ -z "$output_wic" ]]; then
    output_wic="new_$(basename "$wic_image")"
fi
cp "$TMP_DIR"/"$MY_WIC_IMAGE" "$output_wic"
echo "\" $output_wic \" successfully generated."
