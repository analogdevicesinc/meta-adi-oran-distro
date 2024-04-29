#!/bin/bash

#-------------------------------------------------------------------------------------
# adi_extract_wic_images.sh -- extracts the kernel files from a wic image (as mmc.dat or sdc.dat)
#
# adi_extract_wic_images.sh -w <wic_image> [-o <output_dir>]
# 
# Arguments:
#   -w <wit_image>   path to the WIC image (mmc.dat, sdc.dat)
#   -o <output_dir>  path to the output directory
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
    echo "$(basename $1) -w <wic_image> [-o <output_dir>]"
    echo
    echo "Arguments:"
    echo "  -w <wic_image>   path to the WIC image (mmc.dat, sdc.dat)"
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
while getopts w:o:h flag; do
    case "${flag}" in
        w) wic_image=$(realpath "${OPTARG}");;
        o) output_dir=$(realpath "${OPTARG}");;
        h) print_help "$0"; exit 0;;
        *) exit 1;;
    esac
done

# Verify dependencies from SDK
# - WIC
if ! type wic &> /dev/null; then
    print_error "WIC not available. Please source the SDK environment"
fi

# Verify parameters
if [[ -z "$wic_image" ]]; then print_error "WIC image not selected"          ; fi
if [[ ! -f "$wic_image" ]]; then print_error "WIC file \"$wic_image\" not found"; fi

# Verify WIC image
wic ls "$wic_image" > /dev/null 2>&1 || print_error "\"$wic_image\" is not a WIC image"

# Prepare files directory
if [[ -z "$output_dir" ]]; then
    output_dir=$wic_image.files
elif [[ -d "$output_dir" ]]; then
    print_error "Output dir \"$output_dir\" already exits"
fi
rm -rf "$output_dir"
mkdir -p "$output_dir"

# Make temp folder
TMP_DIR="$(mktemp -d)"

pushd "$TMP_DIR" > /dev/null || print_error "Cannot pushd to $TMPDIR"

# Copy source files here
cp "$wic_image" "$MY_WIC_IMAGE"

# Extract FIT image
echo "Extracting FIT image from WIC..."
wic cp "$MY_WIC_IMAGE:$FIT_IMAGE_PARTNUM/$FIT_IMAGE" "$MY_FIT_IMAGE"

# Extract kernel images from FIT
adi_extract_kernel_fit_images -f "$MY_FIT_IMAGE" -o fit_images > /dev/null

# Copy images to output dir
cp -r fit_images/* "$output_dir"

popd > /dev/null || print_error "Cannot popd from $TMPDIR"

echo "Kernel files extracted to $output_dir"