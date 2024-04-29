#!/bin/bash

#-------------------------------------------------------------------------------------
# adi_modify_kernel_fit.sh -- modifies a FIT image replacing the kernel/dtbs
#
# adi_modify_kernel_fit.sh -f <fit_image> -y <keys_dir> [-i <its_file>] [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>]
# 
# Arguments:
#   -f <fit_image>   path to the FIT image
#   -y <keys_dir>    path to the fit keys directory
#   -i <its_file>    path to the ITS file. Auto-generated from the FIT if not provided
#   -k <new_kernel>  path to the new kernel binary
#   -d <new_dtb>     path to the new devicetree
#   -s <new_sec_dtb> path to the new secondary devicetree
#   -r <new_ramdisk> path to the new ramdisk
#   -o <output_fit>  path to the output fit. If not provided, modified fit name is "new_<fit_image>"
#
# Returns 0 on success, 1 on failure
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------------------

# Internals
# - ITS
MY_ITS_FILE="adi.its"
# - Generic FIT image names
MY_KERNEL_NAME="linux.bin"
MY_DTB_NAME="primary.dtb"
MY_SEC_DTB_NAME="secondary.dtb"
MY_RAMDISK_NAME="initramfs.cpio.gz"
# - FIT image
MY_FIT_IMAGE="adi.itb"
# - mkimage log file
MKIMAGE_LOG="mkimage.log"

#-------------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------------
print_help()
{
    echo
    echo "$(basename $1) -f <fit_image> -y <keys_dir> [-i <its_file>] [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>] [-o <new_fit_image>]"
    echo
    echo "Arguments:"
    echo "  -f <fit_image>   path to the FIT image"
    echo "  -y <keys_dir>    path to the fit keys directory"
    echo "  -i <its_file>    path to the ITS file. Auto-generated from the FIT if not provided"
    echo "  -k <new_kernel>  path to the new kernel binary"
    echo "  -d <new_dtb>     path to the new devicetree"
    echo "  -s <new_sec_dtb> path to the new secondary devicetree"
    echo "  -r <new_ramdisk> path to the new ramdisk"
    echo "  -o <output_fit>  path to the output fit. If not provided, modified fit name is \"new_<fit_image>\""
    echo
    echo "Returns 0 on success, 1 on failure"
    echo
}

print_error()
{
    echo "ERROR: $1"
    exit 1
}

extract_fit_image()
{
    fit_name=$1
    image_number=$2
    image_name=$3

    dumpimage -T flat_dt -p "$image_number" -o "$image_name" "$fit_name" > /dev/null
    ret=$?
    if [ $ret -ne 0 ]; then print_error "Cannot extract $image_name"; fi
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

its_file="auto"
# Gather options
while getopts f:i:k:d:s:r:y:o:h flag; do
    case "${flag}" in
        f) fit_image=$(realpath "${OPTARG}");;
        i) its_file=$(realpath "${OPTARG}");;
        k) new_kernel=$(realpath "${OPTARG}");;
        d) new_dtb=$(realpath "${OPTARG}");;
        s) new_sec_dtb=$(realpath "${OPTARG}");;
        r) new_ramdisk=$(realpath "${OPTARG}");;
        y) keys_dir=$(realpath "${OPTARG}");;
        o) output_fit=$(realpath "${OPTARG}");;
        h) print_help "$0"; exit 0;;
        *) print_error "Unkown parameter -${flag}";;
    esac
done

# Verify dependencies
# - mkimage
if ! type mkimage &> /dev/null; then
    print_error "mkimage not available. Please source the SDK environment"
fi

# Verify parameters
if [[ -z "$fit_image" ]]; then print_error "FIT image not selected"          ; fi
if [[ -z "$keys_dir" ]];  then print_error "FIT keys directory not selected" ; fi

if [[ ! -f "$fit_image" ]]; then print_error "FIT image \"$fit_image\" not found"; fi
if [[ ! -f "$its_file" ]] && [[ "$its_file" != "auto" ]];  then print_error "ITS file \"$its_file\" not found" ; fi
if [[ ! -d "$keys_dir" ]];  then print_error "FIT keys dir \"$keys_dir\" not found" ; fi

if [[ -n "$new_kernel" ]]  && [[ ! -f "$new_kernel" ]];  then print_error "New Kernel \"$new_kernel\" not found"         ; fi
if [[ -n "$new_dtb" ]]     && [[ ! -f "$new_dtb" ]];     then print_error "New DTB \"$new_dtb\" not found"               ; fi
if [[ -n "$new_sec_dtb" ]] && [[ ! -f "$new_sec_dtb" ]]; then print_error "New Secondary DTB \"$new_sec_dtb\" not found" ; fi
if [[ -n "$new_ramdisk" ]] && [[ ! -f "$new_ramdisk" ]]; then print_error "New Ramdisk \"$new_ramdisk\" not found"       ; fi

# Verify FIT image
dumpimage -l "$fit_image" | grep "FIT description" > /dev/null || print_error "\"$fit_image\" is not a FIT image"

# Make temp folder
TMP_DIR="$(mktemp -d)"

pushd "$TMP_DIR" > /dev/null || print_error "Cannot pushd to $TMPDIR"

# Copy source files here
cp "$fit_image" "$MY_FIT_IMAGE"
if [[ "$its_file" == "auto" ]]; then
    TTPCACHEFOLDER=. adi_generate_its_from_fit "$fit_image" > "$MY_ITS_FILE"
else
    cp "$its_file"  "$MY_ITS_FILE"
fi

# Modify the ITS to use default names:
echo "Processing ITS file..."
# - Remove paths from incbin lines:
sed -i "s:incbin/(\".*/\([^/\"]*\)\"):incbin/(\"\1\"):" $MY_ITS_FILE
# - Extract image names:
fit_images=$(< "$MY_ITS_FILE" grep incbin | grep -o '".*"' | tr -d "\"")
fit_images=(${fit_images[@]})
 kernel_name=$(echo "${fit_images[0]}")
    dtb_name=$(echo "${fit_images[1]}")
sec_dtb_name=$(echo "${fit_images[2]}")
ramdisk_name=$(echo "${fit_images[3]}")
# - Replace image names:
sed -i "s:$kernel_name:$MY_KERNEL_NAME:"   $MY_ITS_FILE
sed -i "s:$dtb_name:$MY_DTB_NAME:"         $MY_ITS_FILE
sed -i "s:$sec_dtb_name:$MY_SEC_DTB_NAME:" $MY_ITS_FILE
sed -i "s:$ramdisk_name:$MY_RAMDISK_NAME:" $MY_ITS_FILE

# Extract images from FIT image
echo "Extracting images from FIT..."
extract_fit_image "$MY_FIT_IMAGE" 0 "$MY_KERNEL_NAME"
extract_fit_image "$MY_FIT_IMAGE" 1 "$MY_DTB_NAME"
extract_fit_image "$MY_FIT_IMAGE" 2 "$MY_SEC_DTB_NAME"
extract_fit_image "$MY_FIT_IMAGE" 3 "$MY_RAMDISK_NAME"

# Replace images
echo "Replacing images..."
if [[ -n "$new_kernel" ]];  then cp "$new_kernel"  "$MY_KERNEL_NAME"  ; fi
if [[ -n "$new_dtb" ]];     then cp "$new_dtb"     "$MY_DTB_NAME"     ; fi
if [[ -n "$new_sec_dtb" ]]; then cp "$new_sec_dtb" "$MY_SEC_DTB_NAME" ; fi
if [[ -n "$new_ramdisk" ]]; then cp "$new_ramdisk" "$MY_RAMDISK_NAME" ; fi

# Rebuild FIT image
echo "Generating FIT image... "
mkimage -f "$MY_ITS_FILE" -k "$keys_dir" "$MY_FIT_IMAGE" > $MKIMAGE_LOG
ret=$?
if [ $ret -ne 0 ]; then print_error "Cannot create FIT image. Check $TMP_DIR/$MKIMAGE_LOG for details"; fi

popd > /dev/null || print_error "Cannot popd from $TMPDIR"

if [[ -z "$output_fit" ]]; then
    output_fit="new_$(basename "$fit_image")"
fi
cp "$TMP_DIR"/"$MY_FIT_IMAGE" "$output_fit"
echo "\" $output_fit \" successfully generated."
