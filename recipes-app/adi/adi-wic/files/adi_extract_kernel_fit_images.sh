#!/bin/bash

#-------------------------------------------------------------------------------------
# adi_extract_kernel_fit_images.sh -- extracts the files from a kernel fit image (as kernel_fit.itb)
#
# adi_extract_kernel_fit_images.sh -f <fit_image> [-o <output_dir>]
# 
# Arguments:
#   -f <fit_image>   path to the FIT image (kernel_fit.itb)
#   -o <output_dir>  path to the output directory
#
# Returns 0 on success, 1 on failure
#
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# CONSTANTS
#-------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------
# FUNCTIONS
#-------------------------------------------------------------------------------------
print_help()
{
    echo
    echo "$(basename $1) -f <fit_image> [-o <output_dir>]"
    echo
    echo "Arguments:"
    echo "  -f <fit_image>   path to the FIT image (kernel_fit.itb)"
    echo "  -o <output_dir>  path to the output directory"
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

# Gather options
while getopts f:o:h flag; do
    case "${flag}" in
        f) fit_image=$(realpath "${OPTARG}");;
        o) output_dir=$(realpath "${OPTARG}");;
        h) print_help "$0"; exit 0;;
        *) exit 1;;
    esac
done

# Verify dependencies
# - dumpimage
if ! type dumpimage &> /dev/null; then
    print_error "dumpimage not available. Please source the SDK environment"
fi
# - mkimage
if ! type mkimage &> /dev/null; then
    print_error "mkimage not available. Please source the SDK environment"
fi

# Verify parameters
if [[ -z "$fit_image" ]]; then print_error "FIT image not selected"            ; fi
if [[ ! -f "$fit_image" ]]; then print_error "FIT image \"$fit_image\" not found"; fi

# Verify FIT image
dumpimage -l "$fit_image" | grep "FIT description" > /dev/null || print_error "\"$fit_image\" is not a FIT image"

# Get ITB files list:
# 0 kernel-1
# 1 fdt-adi_adrv906x-titan-4.dtb
# 2 fdt-adi_adrv906x-secondary.dtb
# 3 ramdisk-1
fit_images_table="$(dumpimage -l "$fit_image" | grep "^[ ]*Image" | tr -d "()" | awk -F ' ' '{print $2, $3}')"

# Prepare files directory
if [[ -z "$output_dir" ]]; then
    output_dir=$fit_image.files
elif [[ -d "$output_dir" ]]; then
    print_error "Output dir \"$output_dir\" already exits"
fi
rm -rf "$output_dir"
mkdir -p "$output_dir"
pushd "$output_dir" > /dev/null || print_error "Cannot pushd to $output_dir"

# Extract files
while IFS= read -r file_info; do
    extract_fit_image "$fit_image" $file_info
done <<< "$fit_images_table"

popd > /dev/null || print_error "Cannot popd from $output_dir"

echo "Files extracted to $output_dir"