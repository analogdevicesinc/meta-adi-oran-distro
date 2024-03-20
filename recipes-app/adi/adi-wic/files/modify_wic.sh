#!/bin/bash

#-------------------------------------------------------------------------------------
# modify_wic.sh -- rebuilds a WIC image modifying the kernel/dtbs in the FIT image
#
# ./modify_wic.sh -w <wic_image> -i <its_file> -y <keys_dir> [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>]
#
# Arguments:
#   -w <wic_image>   path to the input WIC image
#   -i <its_file>    path to the ITS file
#   -y <keys_dir>    path to the fit keys directory
#   -k <new_kernel>  path to the new kernel binary
#   -d <new_dtb>     path to the new devicetree
#   -s <new_sec_dtb> path to the new secondary devicetree
#   -r <new_ramdisk> path to the new ramdisk
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------------------

# FIT image location inside WIC
FIT_IMAGE_PARTNUM="5"
FIT_IMAGE="kernel_fit.itb"

# Internals
# - WIC ITS copies
MY_WIC_IMAGE="adi.wic"
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
    echo "$1 -w <wic_image> -i <its_file> -y <keys_dir> [-k <new_kernel>] [-d <new_dtb>] [-s <new_sec_dtb>] [-r <new_ramdisk>]"
    echo
    echo "Arguments:"
    echo "  -w <wic_image>   path to the input WIC image"
    echo "  -i <its_file>    path to the ITS file"
    echo "  -y <keys_dir>    path to the fit keys directory"
    echo "  -k <new_kernel>  path to the new kernel binary"
    echo "  -d <new_dtb>     path to the new devicetree"
    echo "  -s <new_sec_dtb> path to the new secondary devicetree"
    echo "  -r <new_ramdisk> path to the new ramdisk"
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

# Gather options
while getopts w:i:k:d:s:r:y:h flag; do
    case "${flag}" in
        w) wic_image=$(realpath "${OPTARG}");;
        i) its_file=$(realpath "${OPTARG}");;
        k) new_kernel=$(realpath "${OPTARG}");;
        d) new_dtb=$(realpath "${OPTARG}");;
        s) new_sec_dtb=$(realpath "${OPTARG}");;
        r) new_ramdisk=$(realpath "${OPTARG}");;
        y) keys_dir=$(realpath "${OPTARG}");;
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
if [[ -z "$its_file" ]];  then print_error "ITS file not selected"           ; fi
if [[ -z "$keys_dir" ]];  then print_error "FIT keys directory not selected" ; fi

if [[ ! -f "$wic_image" ]]; then print_error "WIC file \"$wic_image\" not found"; fi
if [[ ! -f "$its_file" ]];  then print_error "ITS file \"$its_file\" not found" ; fi
if [[ ! -d "$keys_dir" ]];  then print_error "FIT keys dir \"$keys_dir\" not found" ; fi

if [[ -n "$new_kernel" ]]  && [[ ! -f "$new_kernel" ]];  then print_error "New Kernel \"$new_kernel\" not found"         ; fi
if [[ -n "$new_dtb" ]]     && [[ ! -f "$new_dtb" ]];     then print_error "New DTB \"$new_dtb\" not found"               ; fi
if [[ -n "$new_sec_dtb" ]] && [[ ! -f "$new_sec_dtb" ]]; then print_error "New Secondary DTB \"$new_sec_dtb\" not found" ; fi
if [[ -n "$new_ramdisk" ]] && [[ ! -f "$new_ramdisk" ]]; then print_error "New Ramdisk \"$new_ramdisk\" not found"       ; fi

echo "Rebuild WIC image:"
echo "  wic: $wic_image"
echo "  its: $its_file"

# Make temp folder
TMP_DIR="$(mktemp -d)"

pushd "$TMP_DIR" > /dev/null || print_error "Cannot pushd to $TMPDIR"

# Copy source files here
cp "$wic_image" "$MY_WIC_IMAGE"
cp "$its_file"  "$MY_ITS_FILE"

# Modify the ITS to use default names:
echo "Processing ITS file..."
# - Remove paths from incbin lines:
sed -i "s:incbin/(\".*/\([^/\"]*\)\"):incbin/(\"\1\"):" $MY_ITS_FILE
# - Extract image names:
fit_images=$(< "$MY_ITS_FILE" grep incbin | grep -o '".*"' | tr -d "\"")
 kernel_name=$(echo "$fit_images" | grep ".bin")
    dtb_name=$(echo "$fit_images" | grep ".dtb" | grep -v "secondary")
sec_dtb_name=$(echo "$fit_images" | grep ".dtb" | grep    "secondary")
ramdisk_name=$(echo "$fit_images" | grep ".cpio.gz")
# - Replace image names:
sed -i "s:$kernel_name:$MY_KERNEL_NAME:"   $MY_ITS_FILE
sed -i "s:$dtb_name:$MY_DTB_NAME:"         $MY_ITS_FILE
sed -i "s:$sec_dtb_name:$MY_SEC_DTB_NAME:" $MY_ITS_FILE
sed -i "s:$ramdisk_name:$MY_RAMDISK_NAME:" $MY_ITS_FILE

# Extract original FIT image
echo "Extracting original FIT image from WIC..."
wic cp "$MY_WIC_IMAGE:$FIT_IMAGE_PARTNUM/$FIT_IMAGE" "$MY_FIT_IMAGE"

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
mkimage -f "$MY_ITS_FILE" -k "$keys_dir" $FIT_IMAGE > $MKIMAGE_LOG
ret=$?
if [ $ret -ne 0 ]; then print_error "Cannot create FIT image. Check $TMP_DIR/$MKIMAGE_LOG for details"; fi

# Replace FIT image in WIC image
echo "Replacing FIT image in WIC... "
wic rm "$MY_WIC_IMAGE":"$FIT_IMAGE_PARTNUM"/"$FIT_IMAGE"
wic cp $FIT_IMAGE "$MY_WIC_IMAGE":"$FIT_IMAGE_PARTNUM"

popd > /dev/null || print_error "Cannot popd from $TMPDIR"

new_wic_image="new_$(basename "$wic_image")"
cp "$TMP_DIR"/"$MY_WIC_IMAGE" "$new_wic_image"
echo
echo "\" $new_wic_image \" successfully generated."
echo
